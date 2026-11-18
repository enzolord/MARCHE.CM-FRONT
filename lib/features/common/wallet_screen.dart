import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

/// Portefeuille : fonds en séquestre, solde, retraits et historique.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final buyer = state.role == Role.transformateur;
    final tx = state.walletTx;
    return Scaffold(
      appBar: AppBar(
        title: Text(buyer ? 'Paiements' : (state.role == Role.transporteur ? 'Mes gains' : 'Portefeuille')),
        actions: standalone ? null : const [TopActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (buyer)
            Row(
              children: [
                Expanded(child: KpiCard(label: 'Achats du mois', value: fcfa(state.monthPurchases), icon: Icons.shopping_bag_outlined)),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCard(
                    label: 'En séquestre',
                    value: fcfa(state.myOrders.where((o) => !o.status.isFinal).fold(0, (s, o) => s + o.totalPaid)),
                    icon: Icons.lock_clock,
                    color: AppColors.blue,
                  ),
                ),
              ],
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde disponible', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(fcfa(state.availableBalance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                  if (state.isSeller) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.lock_clock, color: AppColors.gold, size: 18),
                        const SizedBox(width: 6),
                        Text('${fcfa(state.escrowBalance)} en séquestre', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ink),
                    onPressed: state.availableBalance <= 0 ? null : () => _withdraw(context, state),
                    icon: const Icon(Icons.north_east),
                    label: const Text('Retirer vers Mobile Money'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const InfoBanner(
              icon: Icons.info_outline,
              color: AppColors.green,
              text: 'Producteurs : aucune commission sur vos ventes. Le séquestre est versé dès la confirmation de réception (72 h maximum après livraison).',
            ),
          ],
          const SectionTitle('Historique', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          if (tx.isEmpty) const Text('Aucune opération.', style: TextStyle(color: AppColors.muted)),
          for (final t in tx)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: t.kind.color.withValues(alpha: 0.12), child: Icon(t.kind.icon, color: t.kind.color, size: 20)),
                title: Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${t.kind.label} · ${dateTime(t.at)}'),
                trailing: Text(
                  '${t.amount > 0 ? '+' : ''}${fcfa(t.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: t.kind == TxKind.sequestre ? AppColors.blue : (t.amount >= 0 ? AppColors.green : AppColors.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, AppState state) async {
    var via = MobileMoney.mtn;
    final controller = TextEditingController(text: '${state.availableBalance}');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Retrait', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              NumberField(controller: controller, label: 'Montant', suffix: 'FCFA'),
              const SizedBox(height: 16),
              PaymentPicker(value: via, onChanged: (m) => setSheet(() => via = m)),
              const SizedBox(height: 8),
              Text('Vers le ${prettyPhone(state.me!.phone)}', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer le retrait')),
            ],
          ),
        ),
      ),
    );
    final amount = parseNum(controller.text)?.round() ?? 0;
    // Laisse la feuille finir son animation avant de libérer le contrôleur.
    Future<void>.delayed(const Duration(milliseconds: 500), controller.dispose);
    if (ok != true || amount <= 0) return;
    final capped = amount > state.availableBalance ? state.availableBalance : amount;
    state.withdraw(capped, via);
    if (context.mounted) toast(context, '${fcfa(capped)} envoyés sur votre compte ${via.label}');
  }
}
