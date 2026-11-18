import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'models.dart';

/// Données de démonstration, en attendant l'API NestJS.
/// Toutes les personnes et entreprises ci-dessous sont fictives.
class Catalog {
  Catalog._();

  static const tomate = Product(id: 'tomate', name: 'Tomates', category: 'Légumes', unit: 'kg', emoji: '🍅', perishable: true);
  static const mais = Product(id: 'mais', name: 'Maïs grain', category: 'Céréales', unit: 'kg', emoji: '🌽');
  static const cacao = Product(id: 'cacao', name: 'Fèves de cacao', category: 'Cultures de rente', unit: 'kg', emoji: '🍫');
  static const cafe = Product(id: 'cafe', name: 'Café arabica', category: 'Cultures de rente', unit: 'kg', emoji: '☕');
  static const manioc = Product(id: 'manioc', name: 'Manioc frais', category: 'Tubercules', unit: 'kg', emoji: '🥔', perishable: true);
  static const plantain = Product(id: 'plantain', name: 'Plantain', category: 'Fruits', unit: 'régime', emoji: '🍌', perishable: true);
  static const arachide = Product(id: 'arachide', name: 'Arachides décortiquées', category: 'Oléagineux', unit: 'kg', emoji: '🥜');
  static const oignon = Product(id: 'oignon', name: 'Oignons', category: 'Légumes', unit: 'kg', emoji: '🧅');
  static const ananas = Product(id: 'ananas', name: 'Ananas', category: 'Fruits', unit: 'pièce', emoji: '🍍', perishable: true);
  static const avocat = Product(id: 'avocat', name: 'Avocats', category: 'Fruits', unit: 'kg', emoji: '🥑', perishable: true);
  static const piment = Product(id: 'piment', name: 'Piment', category: 'Légumes', unit: 'kg', emoji: '🌶️', perishable: true);
  static const soja = Product(id: 'soja', name: 'Soja', category: 'Oléagineux', unit: 'kg', emoji: '🫘');

  static const all = [tomate, mais, cacao, cafe, manioc, plantain, arachide, oignon, ananas, avocat, piment, soja];

  static List<String> get categories =>
      {for (final p in all) p.category}.toList();

  static const regions = [
    'Adamaoua', 'Centre', 'Est', 'Extrême-Nord', 'Littoral',
    'Nord', 'Nord-Ouest', 'Ouest', 'Sud', 'Sud-Ouest',
  ];

  static const collectionPoints = [
    'Foumbot — magasin du marché',
    'Bafoussam — marché A',
    'Dschang — coopérative de la Menoua',
    'Douala — marché Mboppi',
    'Yaoundé — marché Mvog-Mbi',
    'Obala — gare routière',
    'Garoua — marché central',
    'Mbalmayo — entrepôt GIC',
  ];
}

class MockData {
  MockData(this.now) {
    _build();
  }

  final DateTime now;

  // Personnes (fictives)
  late final AppUser producteur;
  late final AppUser cooperative;
  late final AppUser producteur2;
  late final AppUser producteur3;
  late final AppUser producteur4;
  late final AppUser transformateur;
  late final AppUser transformateur2;
  late final AppUser transformateur3;
  late final AppUser transporteur;
  late final AppUser transporteur2;
  late final AppUser agent;

  late final List<Offer> offers;
  late final List<FlashLot> flashLots;
  late final List<Demand> demands;
  late final List<Order> orders;
  late final List<Conversation> conversations;
  late final Map<Role, List<AppNotification>> notifications;
  late final List<PreHarvestContract> contracts;
  late final Map<Role, List<WalletTx>> wallet;
  late final List<Mission> missions;
  late final List<MarketPrice> prices;
  late final List<WeatherDay> weather;
  late final List<Prefinancing> prefinancing;

  DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));
  DateTime _in({int days = 0, int hours = 0}) =>
      now.add(Duration(days: days, hours: hours));

  void _build() {
    producteur = AppUser(id: 'u1', name: 'Jean-Pierre Fotso', phone: '677123456', role: Role.producteur, city: 'Foumbot', region: 'Ouest', verified: true, rating: 4.7, reviews: 23, trustScore: 0.92);
    cooperative = AppUser(id: 'u2', name: 'Coopérative COOPAM', company: 'Coopérative COOPAM Menoua', phone: '699001122', role: Role.cooperative, city: 'Dschang', region: 'Ouest', verified: true, rating: 4.8, reviews: 61, trustScore: 0.95, members: 148);
    producteur2 = AppUser(id: 'u3', name: 'Aïssatou Bello', phone: '655443322', role: Role.producteur, city: 'Garoua', region: 'Nord', verified: true, rating: 4.5, reviews: 12, trustScore: 0.88);
    producteur3 = AppUser(id: 'u4', name: 'Thérèse Mbarga', phone: '690778899', role: Role.producteur, city: 'Obala', region: 'Centre', verified: false, rating: 4.2, reviews: 5, trustScore: 0.74);
    producteur4 = AppUser(id: 'u5', name: 'GIC Les Planteurs du Nyong', company: 'GIC Les Planteurs du Nyong', phone: '651234987', role: Role.cooperative, city: 'Mbalmayo', region: 'Centre', verified: true, rating: 4.6, reviews: 34, trustScore: 0.9, members: 42);
    transformateur = AppUser(id: 'u6', name: 'Paul Ekwalla', company: 'Saveurs du Littoral SARL', phone: '694556677', role: Role.transformateur, city: 'Douala', region: 'Littoral', verified: true, rating: 4.6, reviews: 18, trustScore: 0.9);
    transformateur2 = AppUser(id: 'u7', name: 'Mireille Tchami', company: 'Moulin des Hauts-Plateaux', phone: '675889900', role: Role.transformateur, city: 'Bafoussam', region: 'Ouest', verified: true, rating: 4.4, reviews: 9, trustScore: 0.86);
    transformateur3 = AppUser(id: 'u8', name: 'Hervé Nkoulou', company: 'Gari Express', phone: '698112233', role: Role.transformateur, city: 'Yaoundé', region: 'Centre', verified: true, rating: 4.1, reviews: 7, trustScore: 0.8);
    transporteur = AppUser(id: 'u9', name: 'Samuel Ndzana', company: 'Ndzana Transport', phone: '670102030', role: Role.transporteur, city: 'Bafoussam', region: 'Ouest', verified: true, rating: 4.8, reviews: 40, trustScore: 0.93);
    transporteur2 = AppUser(id: 'u10', name: 'Ibrahim Moussa', phone: '691929394', role: Role.transporteur, city: 'Douala', region: 'Littoral', verified: true, rating: 4.5, reviews: 15);
    agent = AppUser(id: 'u11', name: 'Lucie Ngo Bassong', phone: '656565656', role: Role.agent, city: 'Foumbot', region: 'Ouest', verified: true);

    offers = [
      Offer(id: 'of1', product: Catalog.tomate, producer: producteur, quantity: 1200, unitPrice: 350, availableFrom: _in(days: 2), grade: Grade.a, city: 'Foumbot', distanceKm: 245, collectionPoint: Catalog.collectionPoints[0], description: 'Variété Roma, récolte en cours. Calibre moyen, conditionnement en cageots de 25 kg.', views: 87, createdAt: _ago(hours: 5)),
      Offer(id: 'of2', product: Catalog.mais, producer: cooperative, quantity: 18000, unitPrice: 210, availableFrom: _in(days: 7), grade: Grade.a, city: 'Dschang', distanceKm: 210, collectionPoint: Catalog.collectionPoints[2], description: 'Vente groupée de 37 membres. Maïs jaune séché (humidité < 14 %), en sacs de 100 kg.', groupSale: true, minOrder: 1000, views: 203, createdAt: _ago(days: 1)),
      Offer(id: 'of3', product: Catalog.oignon, producer: producteur2, quantity: 5000, unitPrice: 300, availableFrom: _in(days: 4), grade: Grade.b, city: 'Garoua', distanceKm: 1050, collectionPoint: Catalog.collectionPoints[6], description: 'Oignons rouges de Garoua, bien séchés, sacs de 50 kg.', minOrder: 500, views: 64, createdAt: _ago(days: 2)),
      Offer(id: 'of4', product: Catalog.manioc, producer: producteur3, quantity: 3000, unitPrice: 120, availableFrom: _in(days: 1), grade: Grade.b, city: 'Obala', distanceKm: 40, collectionPoint: Catalog.collectionPoints[5], description: 'Manioc doux récolté sur commande, livré sous 48 h après arrachage.', minOrder: 300, views: 31, createdAt: _ago(hours: 20)),
      Offer(id: 'of5', product: Catalog.cacao, producer: producteur4, quantity: 4500, unitPrice: 2100, availableFrom: _in(days: 10), grade: Grade.a, city: 'Mbalmayo', distanceKm: 50, collectionPoint: Catalog.collectionPoints[7], description: 'Fèves fermentées 6 jours et séchées au soleil. Traçabilité par parcelle.', groupSale: true, minOrder: 500, views: 142, createdAt: _ago(days: 3)),
      Offer(id: 'of6', product: Catalog.plantain, producer: producteur, quantity: 400, unitPrice: 3500, availableFrom: _in(days: 3), grade: Grade.a, city: 'Foumbot', distanceKm: 245, collectionPoint: Catalog.collectionPoints[0], description: 'Régimes de plantain « big ebanga », 30 à 40 doigts.', minOrder: 20, views: 22, createdAt: _ago(days: 1, hours: 3)),
      Offer(id: 'of7', product: Catalog.cafe, producer: cooperative, quantity: 2500, unitPrice: 1650, availableFrom: _in(days: 15), grade: Grade.a, city: 'Dschang', distanceKm: 210, collectionPoint: Catalog.collectionPoints[2], description: 'Arabica lavé des hauts plateaux, vente groupée.', groupSale: true, minOrder: 250, views: 58, createdAt: _ago(days: 4)),
      Offer(id: 'of8', product: Catalog.arachide, producer: producteur2, quantity: 1500, unitPrice: 750, availableFrom: _in(days: 5), grade: Grade.b, city: 'Garoua', distanceKm: 1050, collectionPoint: Catalog.collectionPoints[6], views: 19, createdAt: _ago(days: 2, hours: 8)),
      Offer(id: 'of9', product: Catalog.piment, producer: producteur, quantity: 300, unitPrice: 900, availableFrom: _in(days: 2), grade: Grade.b, city: 'Foumbot', distanceKm: 245, collectionPoint: Catalog.collectionPoints[0], status: OfferStatus.reservee, views: 40, createdAt: _ago(days: 3)),
    ];

    flashLots = [
      FlashLot(id: 'fl1', product: Catalog.tomate, producer: producteur, quantity: 600, initialPrice: 300, floorPrice: 150, start: _ago(hours: 13), end: _in(hours: 59), condition: 'Bien mûres, à transformer sous 4 jours. Parfait pour purée et sauce.', city: 'Foumbot', distanceKm: 245, watchers: 14),
      FlashLot(id: 'fl2', product: Catalog.ananas, producer: producteur4, quantity: 900, initialPrice: 400, floorPrice: 180, start: _ago(hours: 30), end: _in(hours: 18), condition: 'Ananas très mûrs, idéal pour jus et confitures.', city: 'Mbalmayo', distanceKm: 50, watchers: 9),
      FlashLot(id: 'fl3', product: Catalog.avocat, producer: cooperative, quantity: 350, initialPrice: 600, floorPrice: 250, start: _ago(hours: 2), end: _in(hours: 70), condition: "Calibre irrégulier, quelques taches. Convient à l'extraction d'huile.", city: 'Dschang', distanceKm: 210, watchers: 4),
      FlashLot(id: 'fl4', product: Catalog.plantain, producer: producteur3, quantity: 120, initialPrice: 3000, floorPrice: 1400, start: _ago(hours: 50), end: _in(hours: 4), condition: 'Régimes très mûrs — chips et farine.', city: 'Obala', distanceKm: 40, watchers: 21),
    ];

    demands = [
      Demand(id: 'dm1', product: Catalog.tomate, buyer: transformateur, quantity: 2000, maxPrice: 380, deadline: _in(days: 6), region: 'Ouest', grade: Grade.a, recurring: true, responses: 3, createdAt: _ago(hours: 9)),
      Demand(id: 'dm2', product: Catalog.mais, buyer: transformateur2, quantity: 25000, maxPrice: 220, deadline: _in(days: 12), region: 'Ouest', responses: 5, createdAt: _ago(days: 1)),
      Demand(id: 'dm3', product: Catalog.manioc, buyer: transformateur3, quantity: 8000, maxPrice: 130, deadline: _in(days: 4), region: 'Centre', recurring: true, responses: 2, createdAt: _ago(days: 2)),
      Demand(id: 'dm4', product: Catalog.piment, buyer: transformateur, quantity: 500, maxPrice: 1000, deadline: _in(days: 9), region: 'Ouest', responses: 1, createdAt: _ago(hours: 30)),
      Demand(id: 'dm5', product: Catalog.plantain, buyer: transformateur3, quantity: 300, maxPrice: 3800, deadline: _in(days: 8), region: 'Ouest', responses: 0, createdAt: _ago(hours: 4)),
    ];

    Order order(String id, Product p, AppUser buyer, AppUser seller, double q, int price, List<(OrderStatus, int)> steps,
        {MobileMoney pay = MobileMoney.mtn, bool flash = false, String? point, String city = 'Douala', AppUser? truck, int fee = 0, Grade? grade, double? kg, int? rating}) {
      final o = Order(
        id: id, product: p, buyer: buyer, producer: seller, quantity: q, unitPrice: price,
        collectionPoint: point ?? Catalog.collectionPoints[0], deliveryCity: city, payment: pay,
        isFlash: flash, commissionRate: flash ? 0.05 : 0.03, transporter: truck, deliveryFee: fee,
        grade: grade, weighedKg: kg, qrCode: grade == null ? null : 'MCM-$id-${p.id}'.toUpperCase(),
        buyerRating: rating, createdAt: _ago(hours: steps.first.$2),
      );
      for (final (s, hoursAgo) in steps) {
        o.history.add(StatusEvent(s, _ago(hours: hoursAgo)));
      }
      return o;
    }

    orders = [
      order('c1042', Catalog.tomate, transformateur, producteur, 800, 340, [(OrderStatus.payeeSequestre, 30), (OrderStatus.enPreparation, 26), (OrderStatus.auPointCollecte, 6), (OrderStatus.controleeConforme, 5), (OrderStatus.enLivraison, 2)], truck: transporteur, fee: 45000, grade: Grade.a, kg: 796),
      order('c1043', Catalog.plantain, transformateur3, producteur, 60, 3400, [(OrderStatus.payeeSequestre, 3)], pay: MobileMoney.orange, city: 'Yaoundé'),
      order('c1038', Catalog.piment, transformateur, producteur, 200, 900, [(OrderStatus.payeeSequestre, 120), (OrderStatus.enPreparation, 110), (OrderStatus.auPointCollecte, 96), (OrderStatus.controleeConforme, 95), (OrderStatus.enLivraison, 80), (OrderStatus.livree, 72), (OrderStatus.cloturee, 70)], truck: transporteur, fee: 15000, grade: Grade.b, kg: 201, rating: 5),
      order('c1040', Catalog.mais, transformateur2, cooperative, 5000, 205, [(OrderStatus.payeeSequestre, 50), (OrderStatus.enPreparation, 40), (OrderStatus.auPointCollecte, 20)], point: Catalog.collectionPoints[2], city: 'Bafoussam'),
      order('c1036', Catalog.tomate, transformateur, producteur3, 400, 330, [(OrderStatus.payeeSequestre, 200), (OrderStatus.enPreparation, 190), (OrderStatus.auPointCollecte, 170), (OrderStatus.controleeConforme, 169), (OrderStatus.enLivraison, 160), (OrderStatus.livree, 150), (OrderStatus.enLitige, 148)], point: Catalog.collectionPoints[5], truck: transporteur2, fee: 20000, grade: Grade.b, kg: 380),
      order('c1041', Catalog.ananas, transformateur, producteur4, 300, 260, [(OrderStatus.payeeSequestre, 20), (OrderStatus.enPreparation, 16), (OrderStatus.auPointCollecte, 4), (OrderStatus.controleeConforme, 3), (OrderStatus.enLivraison, 2), (OrderStatus.livree, 1)], flash: true, point: Catalog.collectionPoints[7], truck: transporteur2, fee: 25000, grade: Grade.b, kg: 298),
    ];
    orders[4].disputeReason = 'Environ 20 kg de tomates écrasées à la livraison.';

    conversations = [
      Conversation(id: 'cv1', other: transformateur, subject: 'Tomates Roma — 1 200 kg', unread: 2, messages: [
        Message(fromMe: false, text: 'Bonjour, vos tomates sont-elles disponibles pour jeudi ?', at: _ago(hours: 3)),
        Message(fromMe: true, text: 'Oui, la récolte se termine mercredi soir.', at: _ago(hours: 2, minutes: 40)),
        Message(fromMe: false, text: 'Pouvez-vous faire 330 FCFA le kg pour 1 000 kg ?', at: _ago(minutes: 50)),
        Message(fromMe: false, text: 'Je peux commander aujourd’hui.', at: _ago(minutes: 48)),
      ]),
      Conversation(id: 'cv2', other: transformateur3, subject: 'Plantain — commande #C1043', messages: [
        Message(fromMe: false, text: 'Merci, commande payée. Les régimes seront au point de collecte samedi ?', at: _ago(hours: 3)),
        Message(fromMe: true, text: 'Oui, samedi avant 10 h.', at: _ago(hours: 2)),
      ]),
      Conversation(id: 'cv3', other: cooperative, subject: 'Maïs grain — vente groupée', unread: 1, messages: [
        Message(fromMe: false, text: 'Le prochain lot de 18 tonnes sera prêt dans une semaine.', at: _ago(days: 1)),
      ]),
    ];

    notifications = {
      Role.producteur: [
        AppNotification(title: 'Nouvelle commande payée', body: 'Gari Express a payé 60 régimes de plantain. Fonds bloqués en séquestre.', at: _ago(hours: 3), icon: Icons.lock, color: AppColors.blue),
        AppNotification(title: 'Demande correspondante', body: 'Saveurs du Littoral cherche 2 000 kg de tomates (score 86).', at: _ago(hours: 9), icon: Icons.bolt, color: AppColors.flash),
        AppNotification(title: 'Prix de la tomate en hausse', body: '+8 % à Douala cette semaine.', at: _ago(days: 1), icon: Icons.trending_up, read: true),
        AppNotification(title: 'Versement reçu', body: '180 000 FCFA versés sur votre compte MTN pour la commande #C1038.', at: _ago(days: 3), icon: Icons.payments, read: true),
      ],
      Role.transformateur: [
        AppNotification(title: 'Votre commande arrive', body: 'Commande #C1042 en livraison avec Ndzana Transport.', at: _ago(hours: 2), icon: Icons.local_shipping, color: AppColors.blue),
        AppNotification(title: 'Vente Flash près de vous', body: 'Ananas très mûrs à -25 %, Mbalmayo (50 km).', at: _ago(hours: 6), icon: Icons.bolt, color: AppColors.flash),
        AppNotification(title: '3 offres pour votre demande', body: 'Tomates Roma : 3 producteurs ont répondu.', at: _ago(hours: 8), icon: Icons.handshake),
        AppNotification(title: 'Confirmez la réception', body: 'Commande #C1041 livrée. Sans réponse sous 72 h, elle sera validée.', at: _ago(hours: 1), icon: Icons.inventory, read: true),
      ],
      Role.transporteur: [
        AppNotification(title: 'Nouvelle mission', body: 'Foumbot → Douala, 796 kg, 45 000 FCFA.', at: _ago(hours: 1), icon: Icons.route, color: AppColors.flash),
      ],
      Role.agent: [
        AppNotification(title: 'Lot attendu', body: 'Plantain #C1043 déposé samedi avant 10 h.', at: _ago(hours: 2), icon: Icons.warehouse),
      ],
    };
    notifications[Role.cooperative] = notifications[Role.producteur]!;

    contracts = [
      PreHarvestContract(id: 'ct1', product: Catalog.tomate, buyer: transformateur, producer: producteur, quantity: 5000, fixedPrice: 320, harvestDate: _in(days: 75), depositRate: 0.2, status: ContractStatus.signe),
      PreHarvestContract(id: 'ct2', product: Catalog.mais, buyer: transformateur2, producer: producteur, quantity: 8000, fixedPrice: 200, harvestDate: _in(days: 110), depositRate: 0.15),
    ];

    wallet = {
      Role.producteur: [
        WalletTx(kind: TxKind.sequestre, label: 'Commande #C1043 — plantain', amount: 204000, at: _ago(hours: 3)),
        WalletTx(kind: TxKind.sequestre, label: 'Commande #C1042 — tomates', amount: 272000, at: _ago(hours: 30)),
        WalletTx(kind: TxKind.versement, label: 'Commande #C1038 — piment', amount: 180000, at: _ago(days: 3)),
        WalletTx(kind: TxKind.acompte, label: 'Contrat pré-récolte tomates', amount: 320000, at: _ago(days: 9)),
        WalletTx(kind: TxKind.retrait, label: 'Retrait vers MTN MoMo', amount: -250000, at: _ago(days: 10)),
      ],
      Role.transformateur: [
        WalletTx(kind: TxKind.paiement, label: 'Commande #C1042 — tomates', amount: -325160, at: _ago(hours: 30)),
        WalletTx(kind: TxKind.paiement, label: 'Commande #C1041 — ananas (Flash)', amount: -106900, at: _ago(hours: 20)),
        WalletTx(kind: TxKind.paiement, label: 'Abonnement Pro — novembre', amount: -15000, at: _ago(days: 17)),
      ],
      Role.transporteur: [
        WalletTx(kind: TxKind.versement, label: 'Mission Foumbot → Douala', amount: 15000, at: _ago(days: 3)),
      ],
      Role.agent: [],
    };
    wallet[Role.cooperative] = wallet[Role.producteur]!;

    missions = [
      Mission(id: 'ms1', order: orders[0], pickup: Catalog.collectionPoints[0], dropoff: 'Douala — zone industrielle de Bassa', distanceKm: 245, fee: 45000, when: _ago(hours: 2), status: MissionStatus.enCours),
      Mission(id: 'ms2', order: orders[3], pickup: Catalog.collectionPoints[2], dropoff: 'Bafoussam — quartier Tamdja', distanceKm: 55, fee: 60000, when: _in(hours: 20)),
      Mission(id: 'ms3', order: orders[1], pickup: Catalog.collectionPoints[0], dropoff: 'Yaoundé — Nkolbisson', distanceKm: 290, fee: 38000, when: _in(days: 2), refrigerated: false),
      Mission(id: 'ms4', order: orders[2], pickup: Catalog.collectionPoints[0], dropoff: 'Douala — Bonabéri', distanceKm: 240, fee: 15000, when: _ago(days: 3), status: MissionStatus.terminee),
    ];

    prices = [
      const MarketPrice(product: Catalog.tomate, market: 'Douala (Mboppi)', price: 380, trend: 8.2, history: [290, 300, 310, 330, 320, 340, 350, 380]),
      const MarketPrice(product: Catalog.mais, market: 'Bafoussam', price: 215, trend: -2.1, history: [240, 235, 230, 225, 220, 222, 219, 215]),
      const MarketPrice(product: Catalog.cacao, market: 'Kribi', price: 2150, trend: 1.4, history: [1980, 2000, 2050, 2080, 2100, 2090, 2120, 2150]),
      const MarketPrice(product: Catalog.manioc, market: 'Yaoundé (Mvog-Mbi)', price: 125, trend: 0.0, history: [120, 125, 125, 120, 125, 125, 125, 125]),
      const MarketPrice(product: Catalog.oignon, market: 'Garoua', price: 310, trend: 5.0, history: [260, 270, 275, 280, 290, 295, 300, 310]),
      const MarketPrice(product: Catalog.plantain, market: 'Douala (Mboppi)', price: 3600, trend: -4.0, history: [4000, 3900, 3900, 3800, 3750, 3700, 3750, 3600]),
      const MarketPrice(product: Catalog.cafe, market: 'Dschang', price: 1700, trend: 2.5, history: [1580, 1600, 1620, 1640, 1650, 1660, 1680, 1700]),
      const MarketPrice(product: Catalog.arachide, market: 'Garoua', price: 760, trend: 1.2, history: [700, 710, 720, 730, 740, 745, 750, 760]),
    ];

    weather = const [
      WeatherDay("Aujourd'hui", Icons.wb_cloudy, 26, 17, 4),
      WeatherDay('Demain', Icons.thunderstorm, 24, 17, 18),
      WeatherDay('Ven.', Icons.grain, 25, 16, 9),
      WeatherDay('Sam.', Icons.wb_sunny, 28, 16, 0),
      WeatherDay('Dim.', Icons.wb_sunny, 29, 17, 0),
    ];

    prefinancing = [
      Prefinancing(partner: 'Microfinance partenaire (démo)', amount: 350000, months: 6, rate: 0.015, status: 'Pré-éligible'),
    ];
  }
}
