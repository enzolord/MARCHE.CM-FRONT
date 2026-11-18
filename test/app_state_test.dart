import 'package:flutter_test/flutter_test.dart';
import 'package:marche_cm/data/app_state.dart';
import 'package:marche_cm/data/mock_data.dart';
import 'package:marche_cm/data/models.dart';

void main() {
  group('Vente Flash', () {
    final start = DateTime(2026, 11, 18, 8);
    final lot = FlashLot(
      id: 't',
      product: Catalog.tomate,
      producer: AppUser(id: 'p', name: 'Test', phone: '677000000', role: Role.producteur, city: 'Foumbot', region: 'Ouest'),
      quantity: 100,
      initialPrice: 300,
      floorPrice: 150,
      start: start,
      end: start.add(const Duration(hours: 48)),
      condition: '',
      city: 'Foumbot',
      distanceKm: 10,
    );

    test('le prix part du prix initial', () {
      expect(lot.priceAt(start), 300);
    });

    test('le prix baisse par paliers de 6 h', () {
      expect(lot.priceAt(start.add(const Duration(hours: 5))), 300);
      expect(lot.priceAt(start.add(const Duration(hours: 6))), lessThan(300));
    });

    test('le prix ne passe jamais sous le plancher', () {
      expect(lot.priceAt(start.add(const Duration(hours: 100))), 150);
    });
  });

  group('Commande et séquestre', () {
    test('le transformateur paie la commission, le producteur reçoit 100 %', () {
      final state = AppState()..chooseRole(Role.transformateur);
      final offer = state.marketOffers.first;
      final order = state.placeOrder(offer: offer, quantity: offer.minOrder, payment: MobileMoney.mtn, deliveryCity: 'Douala', withDelivery: false);
      expect(order.status, OrderStatus.payeeSequestre);
      expect(order.goodsAmount, (offer.minOrder * offer.unitPrice).round());
      expect(order.totalPaid, order.goodsAmount + order.commission);
      expect(order.commission, (order.goodsAmount * 0.03).round());
    });

    test('la confirmation de réception clôture la commande', () {
      final state = AppState()..chooseRole(Role.transformateur);
      final order = state.myOrders.firstWhere((o) => o.status == OrderStatus.livree);
      state.confirmReception(order);
      expect(order.status, OrderStatus.cloturee);
    });

    test('un lot non conforme est remboursé', () {
      final state = AppState()..chooseRole(Role.agent);
      final order = state.orders.firstWhere((o) => o.status == OrderStatus.auPointCollecte);
      state.recordControl(order, weightKg: 10, grade: Grade.c, conforme: false);
      expect(order.status, OrderStatus.remboursee);
    });
  });

  test('le score de mise en relation favorise les offres proches et moins chères', () {
    final state = AppState();
    final demand = state.demands.firstWhere((d) => d.product.id == 'tomate');
    final offer = state.offers.firstWhere((o) => o.product.id == 'tomate');
    final score = state.matchScore(offer, demand);
    expect(score, inInclusiveRange(1, 100));
    expect(state.matchScore(state.offers.firstWhere((o) => o.product.id == 'mais'), demand), 0);
  });

  test('les numéros de téléphone sont masqués dans la messagerie', () {
    final state = AppState()..chooseRole(Role.producteur);
    final conversation = state.conversations.first;
    final masked = state.sendMessage(conversation, 'Appelle-moi au 677 12 34 56');
    expect(masked, isTrue);
    expect(conversation.messages.last.text, isNot(contains('677')));
  });
}
