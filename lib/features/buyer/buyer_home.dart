import 'package:material_ui/material_ui.dart';

import '../../core/cards.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../orders/order_detail_screen.dart';
import '../shell/home_shell.dart';
import 'demand_form_screen.dart';
import 'flash_detail_screen.dart';
import 'market_screen.dart';
import 'my_demands_screen.dart';
import 'offer_detail_screen.dart';
import 'pro_screen.dart';

class BuyerHome extends StatelessWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.me!;
    final flash = state.openFlashLots(DateTime.now());
    final recommended = state.recommendedOffers.take(4).toList();
    final active = state.activeOrders;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(child: Text(me.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                if (me.verified) ...[const SizedBox(width: 6), const VerifiedBadge()],
                if (state.proSubscriber) ...[const SizedBox(width: 6), const Pill('PRO', color: AppColors.gold, filled: true)],
              ],
            ),
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
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => go<void>(context, const MarketScreen(standalone: true)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.muted),
                    SizedBox(width: 10),
                    Expanded(child: Text('Tomates, maïs, cacao…', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.muted, fontSize: 15))),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                for (final c in Catalog.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(c),
                      onPressed: () => go<void>(context, MarketScreen(standalone: true, category: c)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: KpiCard(label: 'Commandes en cours', value: '${active.length}', icon: Icons.local_shipping_outlined, color: AppColors.blue)),
                const SizedBox(width: 10),
                Expanded(child: KpiCard(label: 'Achats du mois', value: fcfa(state.monthPurchases), icon: Icons.shopping_bag_outlined)),
              ],
            ),
            ),
          ),
          if (active.isNotEmpty) ...[
            const SectionTitle('Suivi de commande'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OrderTile(order: active.first, asBuyer: true, onTap: () => go<void>(context, OrderDetailScreen(order: active.first))),
            ),
          ],
          if (flash.isNotEmpty) ...[
            const SectionTitle('⚡ Ventes Flash près de vous'),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: flash.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(
                  width: 310,
                  child: FlashCard(lot: flash[i], compact: true, onTap: () => go<void>(context, FlashDetailScreen(lot: flash[i]))),
                ),
              ),
            ),
          ],
          SectionTitle('Recommandé pour vous', action: 'Marché', onAction: () => go<void>(context, const MarketScreen(standalone: true))),
          if (recommended.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: InfoBanner(
                icon: Icons.lightbulb_outline,
                text: 'Publiez une demande : nous vous proposons les meilleures offres selon la distance, le prix et la quantité.',
                margin: EdgeInsets.zero,
                color: AppColors.blue,
              ),
            ),
          for (final (o, score) in recommended)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: OfferCard(offer: o, score: score, onTap: () => go<void>(context, OfferDetailScreen(offer: o))),
            ),
          SectionTitle('Mes demandes (${state.myDemands.length})', action: 'Gérer', onAction: () => go<void>(context, const MyDemandsScreen())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => go<void>(context, const DemandFormScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Publier un besoin'),
            ),
          ),
          if (!state.proSubscriber) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: AppColors.ink,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 32),
                  title: const Text('Passez à MARCHE.CM Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Commission réduite, alertes prioritaires, contrats pré-récolte.', style: TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () => go<void>(context, const ProScreen()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
