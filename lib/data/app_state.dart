import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import 'mock_data.dart';
import 'models.dart';

/// État global de l'application (démo hors ligne).
///
/// Chaque méthode correspond à un point d'API prévu dans l'étude
/// (POST /offres, POST /commandes, …) : il suffira de remplacer le corps
/// des méthodes par des appels HTTP.
class AppState extends ChangeNotifier {
  AppState({DateTime? now}) : data = MockData(now ?? DateTime.now()) {
    offers = data.offers;
    flashLots = data.flashLots;
    demands = data.demands;
    orders = data.orders;
    conversations = data.conversations;
    contracts = data.contracts;
    missions = data.missions;
  }

  final MockData data;
  final _random = Random(7);

  // Session
  AppUser? me;
  String pendingPhone = '';
  bool offline = false;
  bool proSubscriber = false;
  bool onboardingSeen = false;

  late List<Offer> offers;
  late List<FlashLot> flashLots;
  late List<Demand> demands;
  late List<Order> orders;
  late List<Conversation> conversations;
  late List<PreHarvestContract> contracts;
  late List<Mission> missions;

  List<MarketPrice> get prices => data.prices;
  List<WeatherDay> get weather => data.weather;
  List<Prefinancing> get prefinancing => data.prefinancing;

  Role get role => me?.role ?? Role.producteur;
  bool get isSeller => role.sells;

  // ---------------------------------------------------------------- Auth

  /// POST /auth/otp
  void requestOtp(String phone) {
    pendingPhone = phone.replaceAll(RegExp(r'\D'), '');
    notifyListeners();
  }

  /// POST /auth/verify — en démo, tout code à 6 chiffres est accepté.
  bool verifyOtp(String code) => RegExp(r'^\d{6}$').hasMatch(code);

  /// Choix du rôle : on reprend le personnage de démo correspondant.
  void chooseRole(Role role) {
    me = personaFor(role);
    if (pendingPhone.isNotEmpty) me!.phone = pendingPhone;
    notifyListeners();
  }

  AppUser personaFor(Role role) => switch (role) {
        Role.producteur => data.producteur,
        Role.cooperative => data.cooperative,
        Role.transformateur => data.transformateur,
        Role.transporteur => data.transporteur,
        Role.agent => data.agent,
      };

  /// PUT /utilisateurs/moi
  void updateProfile({required String name, required String city, required String region, String? company}) {
    final u = me;
    if (u == null) return;
    u
      ..name = name
      ..city = city
      ..region = region;
    if (company != null && company.trim().isNotEmpty) u.company = company.trim();
    notifyListeners();
  }

  /// Démo : passer d'un espace à l'autre sans se déconnecter.
  void switchRole(Role role) {
    me = personaFor(role);
    notifyListeners();
  }

  /// Déconnexion. Le personnage de démo est gardé en mémoire pour éviter
  /// que les écrans encore affichés pendant la transition ne le perdent ;
  /// il est remplacé au prochain choix de rôle.
  void logout() {
    pendingPhone = '';
    offline = false;
  }

  void setOffline(bool value) {
    offline = value;
    notifyListeners();
  }

  void subscribePro(MobileMoney via) {
    proSubscriber = true;
    _wallet.insert(0, WalletTx(kind: TxKind.paiement, label: 'Abonnement Pro (${via.label})', amount: -15000, at: DateTime.now()));
    _notify('Abonnement Pro activé', 'Commission réduite à 2 % et alertes prioritaires.', Icons.workspace_premium);
    notifyListeners();
  }

  // ---------------------------------------------------------------- Vues filtrées

  List<Offer> get myOffers => offers.where((o) => o.producer == me).toList();
  List<FlashLot> get myFlashLots => flashLots.where((f) => f.producer == me).toList();
  List<Demand> get myDemands => demands.where((d) => d.buyer == me).toList();
  List<PreHarvestContract> get myContracts =>
      contracts.where((c) => c.producer == me || c.buyer == me).toList();

  List<Order> get myOrders {
    final list = orders.where((o) => o.buyer == me || o.producer == me).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Order> get activeOrders => myOrders.where((o) => !o.status.isFinal).toList();

  List<Offer> get marketOffers => offers
      .where((o) => o.status == OfferStatus.active && o.producer != me)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<FlashLot> openFlashLots(DateTime now) => flashLots.where((f) => f.isOpen(now)).toList()
    ..sort((a, b) => a.end.compareTo(b.end));

  List<AppNotification> get notifications => data.notifications[role] ?? const [];
  int get unreadNotifications => notifications.where((n) => !n.read).length;
  int get unreadMessages => conversations.fold(0, (s, c) => s + c.unread);

  List<WalletTx> get _wallet => data.wallet.putIfAbsent(role, () => []);
  List<WalletTx> get walletTx => _wallet;

  /// Fonds bloqués en séquestre pour le producteur (commandes non clôturées).
  int get escrowBalance => orders
      .where((o) => o.producer == me && !o.status.isFinal && o.status != OrderStatus.enAttentePaiement)
      .fold(0, (s, o) => s + o.goodsAmount);

  /// Solde disponible (démo) : versements + acomptes - retraits.
  int get availableBalance => _wallet
      .where((t) => t.kind != TxKind.sequestre)
      .fold(0, (s, t) => s + t.amount);

  int get monthSales => orders
      .where((o) => o.producer == me && o.status != OrderStatus.annulee && o.status != OrderStatus.remboursee)
      .fold(0, (s, o) => s + o.goodsAmount);

  int get monthPurchases => orders
      .where((o) => o.buyer == me && o.status != OrderStatus.annulee && o.status != OrderStatus.remboursee)
      .fold(0, (s, o) => s + o.totalPaid);

  /// Score de mise en relation (algorithme MVP de l'étude) :
  /// 40 % distance, 30 % prix, 20 % quantité, 10 % note du vendeur.
  int matchScore(Offer offer, Demand demand) {
    if (offer.product.id != demand.product.id) return 0;
    final distance = (1 - (offer.distanceKm / 600)).clamp(0.0, 1.0);
    final price = offer.unitPrice <= demand.maxPrice
        ? 1.0
        : (1 - (offer.unitPrice - demand.maxPrice) / demand.maxPrice * 4).clamp(0.0, 1.0);
    final quantity = (offer.quantity / demand.quantity).clamp(0.0, 1.0);
    final rating = (offer.producer.rating / 5).clamp(0.0, 1.0);
    return (100 * (0.4 * distance + 0.3 * price + 0.2 * quantity + 0.1 * rating)).round();
  }

  /// Pour un producteur : demandes qui correspondent à ses produits.
  List<(Demand, int)> get opportunities {
    final mine = myOffers;
    final result = <(Demand, int)>[];
    for (final d in demands) {
      var best = 0;
      for (final o in mine) {
        best = max(best, matchScore(o, d));
      }
      if (best == 0 && d.region == me?.region) best = 55;
      if (best > 0) result.add((d, best));
    }
    result.sort((a, b) => b.$2.compareTo(a.$2));
    return result;
  }

  /// Pour un transformateur : meilleures offres par rapport à ses demandes.
  List<(Offer, int)> get recommendedOffers {
    final result = <(Offer, int)>[];
    for (final o in marketOffers) {
      var best = 0;
      for (final d in myDemands) {
        best = max(best, matchScore(o, d));
      }
      if (best >= 60) result.add((o, best));
    }
    result.sort((a, b) => b.$2.compareTo(a.$2));
    return result;
  }

  MarketPrice? priceOf(Product p) {
    for (final m in prices) {
      if (m.product.id == p.id) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------- Producteur

  /// POST /offres
  Offer publishOffer({
    required Product product,
    required double quantity,
    required int unitPrice,
    required DateTime availableFrom,
    required Grade grade,
    required String collectionPoint,
    String description = '',
    int photos = 0,
    double minOrder = 1,
  }) {
    final offer = Offer(
      id: 'of${offers.length + 100}',
      product: product,
      producer: me!,
      quantity: quantity,
      unitPrice: unitPrice,
      availableFrom: availableFrom,
      grade: grade,
      city: me!.city,
      distanceKm: 0,
      collectionPoint: collectionPoint,
      description: description,
      photos: photos,
      groupSale: me!.role == Role.cooperative,
      minOrder: minOrder,
    );
    offers.insert(0, offer);
    final matches = demands.where((d) => matchScore(offer, d) >= 60).length;
    _notify(
      offline ? 'Offre enregistrée hors ligne' : 'Offre publiée',
      offline
          ? 'Elle sera envoyée dès le retour du réseau.'
          : matches > 0
              ? '$matches transformateur(s) correspondant(s) ont été alertés.'
              : 'Les transformateurs de votre zone verront votre offre.',
      Icons.campaign,
    );
    notifyListeners();
    return offer;
  }

  void withdrawOffer(Offer offer) {
    offer.status = OfferStatus.expiree;
    notifyListeners();
  }

  /// POST /flash
  FlashLot publishFlash({
    required Product product,
    required double quantity,
    required int initialPrice,
    required int floorPrice,
    required int hours,
    required String condition,
  }) {
    final now = DateTime.now();
    final lot = FlashLot(
      id: 'fl${flashLots.length + 100}',
      product: product,
      producer: me!,
      quantity: quantity,
      initialPrice: initialPrice,
      floorPrice: floorPrice,
      start: now,
      end: now.add(Duration(hours: hours)),
      condition: condition,
      city: me!.city,
      distanceKm: 0,
    );
    flashLots.insert(0, lot);
    _notify('Vente Flash lancée', 'Les transformateurs à moins de 300 km sont alertés par notification et SMS.', Icons.bolt, AppColors.flash);
    notifyListeners();
    return lot;
  }

  /// Le producteur confirme qu'il prépare la commande.
  void producerConfirm(Order order) {
    order.move(OrderStatus.enPreparation, 'Commande confirmée par le producteur');
    notifyListeners();
  }

  /// Le producteur refuse : le transformateur est remboursé.
  void producerDecline(Order order) {
    order.move(OrderStatus.remboursee, 'Refusée par le producteur — transformateur remboursé');
    notifyListeners();
  }

  /// Le producteur déclare avoir déposé le lot.
  void declareDeposit(Order order) {
    order.move(OrderStatus.auPointCollecte, 'Lot déposé à ${order.collectionPoint}');
    notifyListeners();
  }

  void respondToDemand(Demand demand) {
    demand.responses++;
    _notify('Proposition envoyée', '${demand.buyer.displayName} a reçu votre proposition.', Icons.send);
    notifyListeners();
  }

  void signContract(PreHarvestContract c) {
    c.status = ContractStatus.signe;
    if (c.producer == me) {
      _wallet.insert(0, WalletTx(kind: TxKind.acompte, label: 'Acompte — ${c.product.name}', amount: c.deposit, at: DateTime.now()));
    }
    notifyListeners();
  }

  PreHarvestContract proposeContract({required Product product, required double quantity, required int price, required DateTime harvest, required AppUser buyer}) {
    final c = PreHarvestContract(
      id: 'ct${contracts.length + 10}',
      product: product,
      buyer: buyer,
      producer: me!,
      quantity: quantity,
      fixedPrice: price,
      harvestDate: harvest,
      depositRate: 0.2,
    );
    contracts.insert(0, c);
    notifyListeners();
    return c;
  }

  void withdraw(int amount, MobileMoney to) {
    _wallet.insert(0, WalletTx(kind: TxKind.retrait, label: 'Retrait vers ${to.label}', amount: -amount, at: DateTime.now()));
    notifyListeners();
  }

  void requestPrefinancing(int amount, int months) {
    data.prefinancing.insert(0, Prefinancing(partner: 'Microfinance partenaire (démo)', amount: amount, months: months, rate: 0.015, status: 'Demande envoyée'));
    _notify('Demande de préfinancement envoyée', 'Le partenaire répond sous 72 h, sur la base de votre historique de ventes.', Icons.account_balance);
    notifyListeners();
  }

  // ---------------------------------------------------------------- Transformateur

  /// POST /commandes puis paiement Mobile Money : les fonds vont en séquestre.
  Order placeOrder({required Offer offer, required double quantity, required MobileMoney payment, required String deliveryCity, bool withDelivery = true}) {
    final rate = proSubscriber ? 0.02 : 0.03;
    final order = Order(
      id: 'c${1044 + orders.length}',
      product: offer.product,
      buyer: me!,
      producer: offer.producer,
      quantity: quantity,
      unitPrice: offer.unitPrice,
      collectionPoint: offer.collectionPoint,
      deliveryCity: deliveryCity,
      payment: payment,
      commissionRate: rate,
      offerId: offer.id,
      deliveryFee: withDelivery ? estimateDelivery(offer.distanceKm, quantity) : 0,
    );
    order.move(OrderStatus.enAttentePaiement);
    order.move(OrderStatus.payeeSequestre, 'Paiement ${payment.label} reçu — fonds bloqués');
    orders.insert(0, order);
    offer.quantity = max(0, offer.quantity - quantity);
    if (offer.quantity == 0) offer.status = OfferStatus.vendue;
    _wallet.insert(0, WalletTx(kind: TxKind.paiement, label: 'Commande ${order.shortId} — ${offer.product.name}', amount: -order.totalPaid, at: DateTime.now()));
    _notify('Paiement reçu', 'Commande ${order.shortId} : ${fcfa(order.totalPaid)} bloqués en séquestre.', Icons.lock, AppColors.blue);
    notifyListeners();
    return order;
  }

  /// Réservation d'un lot Flash (30 min pour payer) puis paiement.
  Order buyFlash({required FlashLot lot, required MobileMoney payment}) {
    final now = DateTime.now();
    lot
      ..reservedBy = me
      ..sold = true;
    final order = Order(
      id: 'c${1044 + orders.length}',
      product: lot.product,
      buyer: me!,
      producer: lot.producer,
      quantity: lot.quantity,
      unitPrice: lot.priceAt(now),
      collectionPoint: '${lot.city} — enlèvement express',
      deliveryCity: me!.city,
      payment: payment,
      commissionRate: 0.05,
      isFlash: true,
      deliveryFee: estimateDelivery(lot.distanceKm, lot.quantity),
    );
    order.move(OrderStatus.enAttentePaiement);
    order.move(OrderStatus.payeeSequestre, 'Lot Flash payé — enlèvement express demandé');
    orders.insert(0, order);
    _wallet.insert(0, WalletTx(kind: TxKind.paiement, label: 'Flash ${order.shortId} — ${lot.product.name}', amount: -order.totalPaid, at: now));
    _notify('Lot Flash acheté', '${qty(lot.quantity)} ${lot.product.unit} de ${lot.product.name.toLowerCase()} à ${fcfa(order.unitPrice)}/${lot.product.unit}.', Icons.bolt, AppColors.flash);
    notifyListeners();
    return order;
  }

  int estimateDelivery(double km, double quantity) {
    final base = 5000 + km * 90 + quantity * 8;
    return (base / 500).round() * 500;
  }

  /// POST /demandes
  Demand publishDemand({required Product product, required double quantity, required int maxPrice, required DateTime deadline, required String region, Grade? grade, bool recurring = false}) {
    final d = Demand(
      id: 'dm${demands.length + 100}',
      product: product,
      buyer: me!,
      quantity: quantity,
      maxPrice: maxPrice,
      deadline: deadline,
      region: region,
      grade: grade,
      recurring: recurring,
    );
    demands.insert(0, d);
    final matching = offers.where((o) => matchScore(o, d) >= 60).length;
    _notify('Demande publiée', matching > 0 ? '$matching offre(s) correspondent déjà à votre besoin.' : 'Les producteurs de la zone sont alertés.', Icons.campaign);
    notifyListeners();
    return d;
  }

  void closeDemand(Demand d) {
    demands.remove(d);
    notifyListeners();
  }

  /// PUT /commandes/{id}/reception : libère les fonds au producteur.
  void confirmReception(Order order, {int? rating, String? comment}) {
    order.move(OrderStatus.cloturee, 'Réception confirmée — ${fcfa(order.goodsAmount)} versés au producteur');
    order.buyerRating = rating;
    notifyListeners();
  }

  /// Fait avancer une commande (étapes gérées par d'autres acteurs en démo).
  void advance(Order order, OrderStatus status, [String? note]) {
    order.move(status, note);
    notifyListeners();
  }

  /// POST /litiges : les fonds restent gelés.
  void openDispute(Order order, String reason) {
    order
      ..disputeReason = reason
      ..move(OrderStatus.enLitige, 'Litige ouvert : $reason');
    _notify('Litige ouvert', 'Un administrateur arbitre sous 48 h. Les fonds restent bloqués.', Icons.gavel, AppColors.red);
    notifyListeners();
  }

  void rate(Order order, int stars) {
    if (order.buyer == me) {
      order.buyerRating = stars;
    } else {
      order.producerRating = stars;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- Transport et contrôle

  void acceptMission(Mission m) {
    m.status = MissionStatus.acceptee;
    m.order.transporter = me;
    notifyListeners();
  }

  void startMission(Mission m) {
    m.status = MissionStatus.enCours;
    if (m.order.status == OrderStatus.controleeConforme) {
      m.order.move(OrderStatus.enLivraison, 'Prise en charge par ${me!.displayName}');
    }
    notifyListeners();
  }

  void finishMission(Mission m) {
    m.status = MissionStatus.terminee;
    if (m.order.status == OrderStatus.enLivraison) {
      m.order.move(OrderStatus.livree, 'Remis au transformateur à ${m.dropoff}');
    }
    _wallet.insert(0, WalletTx(kind: TxKind.versement, label: 'Mission ${m.pickup.split(' — ').first} – ${m.dropoff.split(' — ').first}', amount: m.fee, at: DateTime.now()));
    notifyListeners();
  }

  /// Lots attendus ou présents au point de collecte de l'agent.
  List<Order> get lotsToControl => orders
      .where((o) => o.status == OrderStatus.auPointCollecte || o.status == OrderStatus.enPreparation || o.status == OrderStatus.payeeSequestre)
      .toList();

  List<Order> get controlledLots => orders.where((o) => o.grade != null).toList();

  /// Contrôle qualité : pesée, grade et QR code de traçabilité.
  void recordControl(Order order, {required double weightKg, required Grade grade, required bool conforme, String? note}) {
    order
      ..weighedKg = weightKg
      ..grade = grade
      ..qrCode = 'MCM-${order.id}-${order.product.id}'.toUpperCase();
    if (conforme) {
      order.move(OrderStatus.controleeConforme, 'Pesé ${qty(weightKg)} kg — grade ${grade.code}${note == null || note.isEmpty ? '' : ' — $note'}');
    } else {
      order.move(OrderStatus.remboursee, 'Lot non conforme — transformateur remboursé${note == null || note.isEmpty ? '' : ' ($note)'}');
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- Messagerie

  static final _phonePattern = RegExp(r'(\+?237)?[\s.-]*6[\s.-]*\d([\s.-]*\d){7}');
  static final _contactWords = RegExp(r'whatsapp|appelle[- ]?moi|mon num(é|e)ro|hors (de la )?plateforme', caseSensitive: false);

  /// Anti-contournement : les numéros sont masqués et un rappel est affiché.
  bool sendMessage(Conversation c, String text) {
    final masked = _phonePattern.hasMatch(text) || _contactWords.hasMatch(text);
    final clean = text.replaceAll(_phonePattern, '[numéro masqué]');
    c.messages.add(Message(fromMe: true, text: clean, at: DateTime.now(), masked: masked));
    notifyListeners();
    if (!masked) _simulateReply(c);
    return masked;
  }

  Future<void> _simulateReply(Conversation c) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    const replies = [
      "D'accord, je regarde et je reviens vers vous.",
      'Très bien, merci.',
      'Je peux passer la commande dans l’application.',
      'Parfait, on reste en contact ici.',
    ];
    c.messages.add(Message(fromMe: false, text: replies[_random.nextInt(replies.length)], at: DateTime.now()));
    notifyListeners();
  }

  void markRead(Conversation c) {
    if (c.unread == 0) return;
    c.unread = 0;
    notifyListeners();
  }

  Conversation conversationWith(AppUser other, String subject) {
    for (final c in conversations) {
      if (c.other == other) return c;
    }
    final c = Conversation(id: 'cv${conversations.length + 10}', other: other, subject: subject);
    conversations.insert(0, c);
    notifyListeners();
    return c;
  }

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void _notify(String title, String body, IconData icon, [Color color = AppColors.green]) {
    data.notifications.putIfAbsent(role, () => []).insert(0, AppNotification(title: title, body: body, at: DateTime.now(), icon: icon, color: color));
  }
}

/// Donne accès à [AppState] dans l'arbre de widgets.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Accès avec reconstruction quand l'état change.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Accès ponctuel (dans un callback), sans abonnement.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
