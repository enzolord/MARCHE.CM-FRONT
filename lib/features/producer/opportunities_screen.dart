import 'package:material_ui/material_ui.dart';

import '../../core/cards.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../messages/chat_screen.dart';

/// Demandes des transformateurs qui correspondent aux produits du producteur.
class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final list = state.opportunities;
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes pour vous')),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.search, title: 'Aucune demande pour l’instant', message: 'Nous vous alertons dès qu’un transformateur cherche vos produits.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const InfoBanner(
                    icon: Icons.bolt,
                    color: AppColors.flash,
                    text: 'Score de correspondance : distance 40 %, prix 30 %, quantité 20 %, votre note 10 %.',
                  );
                }
                final (d, score) = list[i - 1];
                return DemandCard(
                  demand: d,
                  score: score,
                  action: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          onPressed: () => go<void>(context, ChatScreen(conversation: state.conversationWith(d.buyer, '${d.product.name} — demande'))),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Discuter'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                          onPressed: () {
                            state.respondToDemand(d);
                            toast(context, 'Proposition envoyée à ${d.buyer.displayName}');
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Proposer'),
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
