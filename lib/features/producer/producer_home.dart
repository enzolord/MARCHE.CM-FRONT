import 'package:flutter/material.dart';

import '../../core/cards.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../common/contracts_screen.dart';
import '../common/prices_screen.dart';
import '../common/wallet_screen.dart';
import '../orders/order_detail_screen.dart';
import '../shell/home_shell.dart';
import 'flash_form_screen.dart';
import 'offer_form_screen.dart';
import 'opportunities_screen.dart';
import 'prefinancing_screen.dart';

class ProducerHome extends StatelessWidget {
  const ProducerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.me!;
    final todo = state.myOrders
        .where((o) => o.producer == me && (o.status == OrderStatus.payeeSequestre || o.status == OrderStatus.enPreparation))
        .toList();
    final opportunities = state.opportunities.take(3).toList();
    final myProducts = {for (final o in state.myOffers) o.product.id};
    final prices = state.prices.where((p) => myProducts.contains(p.product.id)).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour ${me.name.split(' ').first} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${me.city}, ${me.region}', style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: const [TopActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BalanceCard(sales: state.monthSales, escrow: state.escrowBalance),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _QuickAction(icon: Icons.add_business, label: 'Publier\nune offre', color: AppColors.green, onTap: () => go<void>(context, const OfferFormScreen())),
                _QuickAction(icon: Icons.bolt, label: 'Vente\nFlash', color: AppColors.flash, onTap: () => go<void>(context, const FlashFormScreen())),
                _QuickAction(icon: Icons.query_stats, label: 'Bourse\ndes prix', color: AppColors.blue, onTap: () => go<void>(context, const PricesScreen())),
                _QuickAction(icon: Icons.handshake, label: 'Contrats\npré-récolte', color: AppColors.greenDark, onTap: () => go<void>(context, const ContractsScreen())),
                _QuickAction(icon: Icons.account_balance, label: 'Préfinan-\ncement', color: AppColors.ink, onTap: () => go<void>(context, const PrefinancingScreen())),
              ],
            ),
          ),
          if (todo.isNotEmpty) ...[
            SectionTitle('À faire (${todo.length})'),
            for (final o in todo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _TodoTile(order: o),
              ),
          ],
          SectionTitle('Demandes pour vous', action: 'Tout voir', onAction: () => go<void>(context, const OpportunitiesScreen())),
          if (opportunities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: InfoBanner(icon: Icons.search, text: 'Publiez une offre : nous vous signalerons les transformateurs qui cherchent vos produits.'),
            ),
          for (final (d, score) in opportunities)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DemandCard(demand: d, score: score, onTap: () => go<void>(context, const OpportunitiesScreen())),
            ),
          SectionTitle('Prix du marché', action: 'Bourse des prix', onAction: () => go<void>(context, const PricesScreen())),
          for (final p in prices)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PriceTile(price: p),
            ),
          const SectionTitle('Météo à 5 jours'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WeatherStrip(days: state.weather),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.sales, required this.escrow});

  final int sales;
  final int escrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => go<void>(context, const WalletScreen(standalone: true)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.green, AppColors.greenDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ventes ce mois-ci', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(fcfa(sales), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${fcfa(escrow)} en séquestre, versés à la livraison',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 92,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 20)),
              const Spacer(),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final toConfirm = order.status == OrderStatus.payeeSequestre;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ProductThumb(order.product, size: 44, flash: order.isFlash),
        title: Text(
          toConfirm ? 'Confirmer la commande ${order.shortId}' : 'Déposer le lot ${order.shortId}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
        subtitle: Text('${qty(order.quantity)} ${order.product.unit} · ${order.buyer.displayName}'),
        trailing: Pill(toConfirm ? 'Payée' : 'À déposer', color: toConfirm ? AppColors.blue : AppColors.flash),
        onTap: () => go<void>(context, OrderDetailScreen(order: order)),
      ),
    );
  }
}
