import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// Rôles des utilisateurs de MARCHE.CM.
enum Role {
  producteur('Producteur', 'Je vends mes récoltes', Icons.agriculture),
  cooperative('Coopérative / GIC', 'Je vends pour un groupe de producteurs', Icons.groups),
  transformateur('Transformateur', "J'achète des matières premières", Icons.factory),
  transporteur('Transporteur', 'Je livre les commandes', Icons.local_shipping),
  agent('Agent terrain', 'Je contrôle les lots au point de collecte', Icons.fact_check);

  const Role(this.label, this.tagline, this.icon);
  final String label;
  final String tagline;
  final IconData icon;

  bool get sells => this == Role.producteur || this == Role.cooperative;
}

/// Grade qualité attribué au point de collecte.
enum Grade {
  a('A', 'Premier choix'),
  b('B', 'Standard'),
  c('C', 'Transformation');

  const Grade(this.code, this.label);
  final String code;
  final String label;

  Color get color => switch (this) {
        Grade.a => AppColors.green,
        Grade.b => AppColors.blue,
        Grade.c => AppColors.muted,
      };
}

enum MobileMoney {
  mtn('MTN Mobile Money', AppColors.mtn),
  orange('Orange Money', AppColors.orange);

  const MobileMoney(this.label, this.color);
  final String label;
  final Color color;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.emoji,
    this.perishable = false,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final String emoji;
  final bool perishable;
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.city,
    required this.region,
    this.company,
    this.verified = false,
    this.rating = 0,
    this.reviews = 0,
    this.trustScore = 0.8,
    this.members = 0,
  });

  final String id;
  String name;
  String phone;
  Role role;
  String city;
  String region;
  String? company;
  bool verified;
  double rating;
  int reviews;
  double trustScore;
  int members;

  String get displayName => company ?? name;
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

enum OfferStatus {
  active('En ligne', AppColors.green),
  reservee('Réservée', AppColors.blue),
  vendue('Vendue', AppColors.muted),
  expiree('Expirée', AppColors.red);

  const OfferStatus(this.label, this.color);
  final String label;
  final Color color;
}

class Offer {
  Offer({
    required this.id,
    required this.product,
    required this.producer,
    required this.quantity,
    required this.unitPrice,
    required this.availableFrom,
    required this.grade,
    required this.city,
    required this.distanceKm,
    required this.collectionPoint,
    this.description = '',
    this.photos = 3,
    this.status = OfferStatus.active,
    this.groupSale = false,
    this.minOrder = 1,
    this.views = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final Product product;
  final AppUser producer;
  double quantity;
  final int unitPrice;
  final DateTime availableFrom;
  final Grade grade;
  final String city;
  final double distanceKm;
  final String collectionPoint;
  final String description;
  final int photos;
  OfferStatus status;
  final bool groupSale;
  final double minOrder;
  int views;
  final DateTime createdAt;

  int get total => (quantity * unitPrice).round();
}

/// Lot périssable vendu en Vente Flash, avec un prix qui baisse dans le temps.
class FlashLot {
  FlashLot({
    required this.id,
    required this.product,
    required this.producer,
    required this.quantity,
    required this.initialPrice,
    required this.floorPrice,
    required this.start,
    required this.end,
    required this.condition,
    required this.city,
    required this.distanceKm,
    this.reservedBy,
    this.sold = false,
    this.watchers = 0,
  });

  final String id;
  final Product product;
  final AppUser producer;
  final double quantity;
  final int initialPrice;
  final int floorPrice;
  final DateTime start;
  final DateTime end;
  final String condition;
  final String city;
  final double distanceKm;
  AppUser? reservedBy;
  bool sold;
  int watchers;

  /// Le prix baisse par paliers de 6 h, du prix initial jusqu'au prix plancher.
  int priceAt(DateTime now) {
    final total = end.difference(start).inMinutes;
    if (total <= 0) return floorPrice;
    final elapsed = now.difference(start).inMinutes.clamp(0, total);
    final steps = (total / 360).ceil();
    final step = (elapsed / 360).floor().clamp(0, steps);
    final drop = (initialPrice - floorPrice) * step / steps;
    return (initialPrice - drop).round().clamp(floorPrice, initialPrice);
  }

  int discountAt(DateTime now) =>
      ((1 - priceAt(now) / initialPrice) * 100).round();

  /// Heure du prochain palier de baisse, ou null s'il n'y en a plus.
  DateTime? nextDropAt(DateTime now) {
    var t = start;
    while (t.isBefore(end)) {
      t = t.add(const Duration(hours: 6));
      if (t.isAfter(now) && t.isBefore(end)) return t;
    }
    return null;
  }

  bool isOpen(DateTime now) => !sold && reservedBy == null && now.isBefore(end);
}

/// Besoin publié par un transformateur.
class Demand {
  Demand({
    required this.id,
    required this.product,
    required this.buyer,
    required this.quantity,
    required this.maxPrice,
    required this.deadline,
    required this.region,
    this.grade,
    this.recurring = false,
    this.responses = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final Product product;
  final AppUser buyer;
  final double quantity;
  final int maxPrice;
  final DateTime deadline;
  final String region;
  final Grade? grade;
  final bool recurring;
  int responses;
  final DateTime createdAt;
}

/// États d'une commande (voir le diagramme d'états-transitions de l'étude).
enum OrderStatus {
  enAttentePaiement('En attente de paiement', Icons.hourglass_top, AppColors.muted),
  payeeSequestre('Payée — fonds bloqués', Icons.lock, AppColors.blue),
  enPreparation('En préparation', Icons.inventory_2, AppColors.blue),
  auPointCollecte('Au point de collecte', Icons.warehouse, AppColors.blue),
  controleeConforme('Contrôlée conforme', Icons.verified, AppColors.green),
  enLivraison('En livraison', Icons.local_shipping, AppColors.blue),
  livree('Livrée', Icons.inventory, AppColors.green),
  enLitige('En litige', Icons.gavel, AppColors.red),
  cloturee('Clôturée — fonds versés', Icons.check_circle, AppColors.green),
  remboursee('Remboursée', Icons.undo, AppColors.muted),
  annulee('Annulée', Icons.cancel, AppColors.muted);

  const OrderStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  bool get isFinal =>
      this == OrderStatus.cloturee ||
      this == OrderStatus.remboursee ||
      this == OrderStatus.annulee;

  /// Étapes du parcours normal, pour la frise de suivi.
  static const flow = [
    OrderStatus.payeeSequestre,
    OrderStatus.enPreparation,
    OrderStatus.auPointCollecte,
    OrderStatus.controleeConforme,
    OrderStatus.enLivraison,
    OrderStatus.livree,
    OrderStatus.cloturee,
  ];
}

class StatusEvent {
  StatusEvent(this.status, this.at, [this.note]);
  final OrderStatus status;
  final DateTime at;
  final String? note;
}

class Order {
  Order({
    required this.id,
    required this.product,
    required this.buyer,
    required this.producer,
    required this.quantity,
    required this.unitPrice,
    required this.collectionPoint,
    required this.deliveryCity,
    required this.payment,
    this.commissionRate = 0.03,
    this.isFlash = false,
    this.offerId,
    List<StatusEvent>? history,
    this.transporter,
    this.deliveryFee = 0,
    this.weighedKg,
    this.grade,
    this.qrCode,
    this.buyerRating,
    this.producerRating,
    this.disputeReason,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        history = history ?? [];

  final String id;
  final Product product;
  final AppUser buyer;
  final AppUser producer;
  final double quantity;
  final int unitPrice;
  final String collectionPoint;
  final String deliveryCity;
  final MobileMoney payment;
  final double commissionRate;
  final bool isFlash;
  final String? offerId;
  final List<StatusEvent> history;
  AppUser? transporter;
  int deliveryFee;
  double? weighedKg;
  Grade? grade;
  String? qrCode;
  int? buyerRating;
  int? producerRating;
  String? disputeReason;
  final DateTime createdAt;

  OrderStatus get status =>
      history.isEmpty ? OrderStatus.enAttentePaiement : history.last.status;

  /// Montant de la marchandise, versé intégralement au producteur.
  int get goodsAmount => (quantity * unitPrice).round();

  /// Commission MARCHE.CM, payée par le transformateur.
  int get commission => (goodsAmount * commissionRate).round();

  /// Total payé par le transformateur.
  int get totalPaid => goodsAmount + commission + deliveryFee;

  String get shortId => '#${id.toUpperCase()}';

  void move(OrderStatus status, [String? note]) =>
      history.add(StatusEvent(status, DateTime.now(), note));

  DateTime? dateOf(OrderStatus s) {
    for (final e in history) {
      if (e.status == s) return e.at;
    }
    return null;
  }
}

class Message {
  Message({required this.fromMe, required this.text, required this.at, this.masked = false});
  final bool fromMe;
  final String text;
  final DateTime at;
  final bool masked;
}

class Conversation {
  Conversation({
    required this.id,
    required this.other,
    required this.subject,
    List<Message>? messages,
    this.unread = 0,
  }) : messages = messages ?? [];

  final String id;
  final AppUser other;
  final String subject;
  final List<Message> messages;
  int unread;

  DateTime get lastAt =>
      messages.isEmpty ? DateTime.now() : messages.last.at;
}

class AppNotification {
  AppNotification({
    required this.title,
    required this.body,
    required this.at,
    required this.icon,
    this.color = AppColors.green,
    this.read = false,
  });

  final String title;
  final String body;
  final DateTime at;
  final IconData icon;
  final Color color;
  bool read;
}

class MarketPrice {
  const MarketPrice({
    required this.product,
    required this.market,
    required this.price,
    required this.trend,
    required this.history,
  });

  final Product product;
  final String market;
  final int price;
  final double trend; // variation sur 7 jours, en %
  final List<int> history; // 8 dernières semaines
}

class WeatherDay {
  const WeatherDay(this.day, this.icon, this.max, this.min, this.rainMm);
  final String day;
  final IconData icon;
  final int max;
  final int min;
  final int rainMm;
}

enum ContractStatus {
  propose('Proposé', AppColors.blue),
  signe('Signé — acompte versé', AppColors.green),
  livre('Livré', AppColors.muted);

  const ContractStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// Contrat de pré-récolte : prix fixé avant la récolte, acompte versé.
class PreHarvestContract {
  PreHarvestContract({
    required this.id,
    required this.product,
    required this.buyer,
    required this.producer,
    required this.quantity,
    required this.fixedPrice,
    required this.harvestDate,
    required this.depositRate,
    this.status = ContractStatus.propose,
  });

  final String id;
  final Product product;
  final AppUser buyer;
  final AppUser producer;
  final double quantity;
  final int fixedPrice;
  final DateTime harvestDate;
  final double depositRate;
  ContractStatus status;

  int get total => (quantity * fixedPrice).round();
  int get deposit => (total * depositRate).round();
}

enum TxKind {
  sequestre('Fonds bloqués', Icons.lock_clock, AppColors.blue),
  versement('Versement reçu', Icons.south_west, AppColors.green),
  retrait('Retrait Mobile Money', Icons.north_east, AppColors.ink),
  paiement('Paiement', Icons.north_east, AppColors.ink),
  remboursement('Remboursement', Icons.undo, AppColors.green),
  acompte('Acompte de contrat', Icons.handshake, AppColors.green);

  const TxKind(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class WalletTx {
  WalletTx({required this.kind, required this.label, required this.amount, required this.at});
  final TxKind kind;
  final String label;
  final int amount;
  final DateTime at;
}

enum MissionStatus {
  proposee('Proposée', AppColors.blue),
  acceptee('Acceptée', AppColors.green),
  enCours('En cours', AppColors.flash),
  terminee('Terminée', AppColors.muted);

  const MissionStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// Mission de livraison proposée à un transporteur.
class Mission {
  Mission({
    required this.id,
    required this.order,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    required this.fee,
    required this.when,
    this.refrigerated = false,
    this.status = MissionStatus.proposee,
  });

  final String id;
  final Order order;
  final String pickup;
  final String dropoff;
  final double distanceKm;
  final int fee;
  final DateTime when;
  final bool refrigerated;
  MissionStatus status;
}

class Prefinancing {
  Prefinancing({
    required this.partner,
    required this.amount,
    required this.months,
    required this.rate,
    required this.status,
  });

  final String partner;
  final int amount;
  final int months;
  final double rate;
  String status;
}
