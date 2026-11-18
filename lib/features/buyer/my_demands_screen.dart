import 'package:material_ui/material_ui.dart';

import '../../core/cards.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'demand_form_screen.dart';
import 'offer_detail_screen.dart';

class MyDemandsScreen extends StatelessWidget {
  const MyDemandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final demands = state.myDemands;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes besoins')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => go<void>(context, const DemandFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau besoin'),
      ),
      body: demands.isEmpty
          ? EmptyState(
              icon: Icons.campaign_outlined,
              title: 'Aucun besoin publié',
              message: 'Décrivez ce que vous cherchez : les producteurs viennent à vous.',
              action: 'Publier un besoin',
              onAction: () => go<void>(context, const DemandFormScreen()),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: demands.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final d = demands[i];
                final matches = state.marketOffers.map((o) => (o, state.matchScore(o, d))).where((m) => m.$2 >= 60).toList()
                  ..sort((a, b) => b.$2.compareTo(a.$2));
                return DemandCard(
                  demand: d,
                  action: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (matches.isEmpty)
                        const Text('Pas encore d’offre correspondante.', style: TextStyle(color: AppColors.muted))
                      else ...[
                        Text('${matches.length} offre(s) correspondante(s)', style: const TextStyle(fontWeight: FontWeight.w700)),
                        for (final (Offer o, int score) in matches.take(3))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Pill('$score %', color: AppColors.flash),
                            title: Text(o.producer.displayName),
                            subtitle: Text('${o.unitPrice} F/${o.product.unit} · ${o.city}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => go<void>(context, OfferDetailScreen(offer: o)),
                          ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            if (await confirm(context, title: 'Clôturer ce besoin ?', message: 'Les producteurs ne pourront plus y répondre.', ok: 'Clôturer')) {
                              state.closeDemand(d);
                            }
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Clôturer'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
