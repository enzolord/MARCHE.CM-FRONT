import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/qr.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../messages/chat_screen.dart';
import 'dispute_screen.dart';

/// Suivi d'une commande : frise d'états, montants, logistique et actions.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final asBuyer = order.buyer == state.me;
    final asSeller = order.producer == state.me;
    final other = asBuyer ? order.producer : order.buyer;
    final s = order.status;

    return Scaffold(
      appBar: AppBar(title: Text('Commande ${order.shortId}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ProductThumb(order.product, size: 60, flash: order.isFlash),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${qty(order.quantity)} ${order.product.unit} · ${order.product.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${fcfa(order.unitPrice)}/${order.product.unit} · passée ${ago(order.createdAt)}', style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          Pill(s.label, color: s.color, icon: s.icon),
                          if (order.isFlash) const Pill('Vente Flash', color: AppColors.flash, icon: Icons.bolt),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _EscrowBanner(order: order, asBuyer: asBuyer),
          const SizedBox(height: 4),
          _Actions(order: order, asBuyer: asBuyer, asSeller: asSeller),
          const SectionTitle('Suivi', padding: EdgeInsets.fromLTRB(0, 16, 0, 8)),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: _Timeline(order: order))),
          if (order.grade != null) ...[
            const SectionTitle('Contrôle qualité', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    TraceCode(order.qrCode ?? order.id, size: 92),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradeBadge(order.grade!),
                          const SizedBox(height: 8),
                          Text('Poids contrôlé : ${qty(order.weighedKg ?? order.quantity)} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(order.qrCode ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('Scannez le code pour voir l’origine et le parcours du lot.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SectionTitle('Logistique', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.warehouse_outlined), title: const Text('Point de collecte'), subtitle: Text(order.collectionPoint)),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(order.transporter == null ? 'Transporteur à attribuer' : order.transporter!.displayName),
                  subtitle: Text(order.deliveryFee > 0 ? 'Livraison à ${order.deliveryCity}' : 'Enlèvement au point de collecte'),
                  trailing: order.transporter == null ? null : Stars(order.transporter!.rating),
                ),
              ],
            ),
          ),
          SectionTitle(asBuyer ? 'Producteur' : 'Acheteur', padding: const EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: UserAvatar(other),
              title: Row(children: [
                Flexible(child: Text(other.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (other.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
              ]),
              subtitle: Text('${other.city} · numéro masqué'),
              trailing: IconButton.filledTonal(
                tooltip: 'Message',
                onPressed: () => go<void>(context, ChatScreen(conversation: state.conversationWith(other, 'Commande ${order.shortId}'))),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
          const SectionTitle('Montants', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: asBuyer
                    ? [
                        AmountRow('Marchandise', fcfa(order.goodsAmount)),
                        AmountRow('Commission (${(order.commissionRate * 100).round()} %)', fcfa(order.commission)),
                        if (order.deliveryFee > 0) AmountRow('Livraison', fcfa(order.deliveryFee)),
                        const Divider(height: 20),
                        AmountRow('Total payé', fcfa(order.totalPaid), bold: true),
                        AmountRow('Moyen de paiement', order.payment.label),
                      ]
                    : [
                        AmountRow('Prix de vente', fcfa(order.goodsAmount)),
                        const AmountRow('Commission', '0 FCFA', hint: 'Payée par l’acheteur'),
                        const Divider(height: 20),
                        AmountRow('Vous recevez', fcfa(order.goodsAmount), bold: true, color: AppColors.green),
                        AmountRow('Versement sur', order.payment.label),
                      ],
              ),
            ),
          ),
          if (order.disputeReason != null) ...[
            const SectionTitle('Litige', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            InfoBanner(icon: Icons.gavel, color: AppColors.red, text: order.disputeReason!),
          ],
        ],
      ),
    );
  }
}

class _EscrowBanner extends StatelessWidget {
  const _EscrowBanner({required this.order, required this.asBuyer});

  final Order order;
  final bool asBuyer;

  @override
  Widget build(BuildContext context) {
    final s = order.status;
    final (IconData icon, Color color, String text) = switch (s) {
      OrderStatus.enAttentePaiement => (Icons.hourglass_top, AppColors.muted, 'En attente du paiement Mobile Money (30 min maximum).'),
      OrderStatus.cloturee => (Icons.check_circle, AppColors.green, asBuyer ? 'Commande terminée. Merci !' : '${fcfa(order.goodsAmount)} versés sur votre compte ${order.payment.label}.'),
      OrderStatus.remboursee => (Icons.undo, AppColors.muted, asBuyer ? 'Vous avez été remboursé intégralement.' : 'La commande a été annulée et l’acheteur remboursé.'),
      OrderStatus.annulee => (Icons.cancel, AppColors.muted, 'Commande annulée.'),
      OrderStatus.enLitige => (Icons.gavel, AppColors.red, 'Litige en cours : les fonds restent gelés jusqu’à la décision de l’administrateur (48 h maximum).'),
      OrderStatus.livree => (Icons.lock_clock, AppColors.blue, asBuyer ? 'Confirmez la réception pour libérer le paiement. Sans réponse sous 72 h, il est libéré automatiquement.' : 'Livrée. Le paiement sera libéré dès la confirmation de l’acheteur (72 h maximum).'),
      _ => (Icons.lock, AppColors.blue, asBuyer ? 'Votre paiement de ${fcfa(order.totalPaid)} est bloqué en séquestre jusqu’à la livraison.' : '${fcfa(order.goodsAmount)} sont bloqués pour vous. Ils vous seront versés à la livraison.'),
    };
    return InfoBanner(icon: icon, color: color, text: text);
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.asBuyer, required this.asSeller});

  final Order order;
  final bool asBuyer;
  final bool asSeller;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = order.status;
    final buttons = <Widget>[];

    if (asSeller && s == OrderStatus.payeeSequestre) {
      buttons.add(Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              if (await confirm(context, title: 'Refuser la commande ?', message: 'L’acheteur sera remboursé intégralement. Les refus répétés baissent votre score de confiance.', ok: 'Refuser', danger: true)) {
                state.producerDecline(order);
              }
            },
            child: const Text('Refuser'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () {
              state.producerConfirm(order);
              toast(context, 'Commande confirmée. Déposez le lot au point de collecte.');
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirmer'),
          ),
        ),
      ]));
    }
    if (asSeller && s == OrderStatus.enPreparation) {
      buttons.add(FilledButton.icon(
        onPressed: () => state.declareDeposit(order),
        icon: const Icon(Icons.warehouse),
        label: const Text('J’ai déposé le lot au point de collecte'),
      ));
    }
    if (asBuyer && s == OrderStatus.livree) {
      buttons.add(FilledButton.icon(
        onPressed: () => _confirmReception(context, state),
        icon: const Icon(Icons.verified),
        label: const Text('Confirmer la réception'),
      ));
      buttons.add(const SizedBox(height: 8));
      buttons.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
        onPressed: () => go<void>(context, DisputeScreen(order: order)),
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Signaler un problème'),
      ));
    }
    final myRating = asBuyer ? order.buyerRating : order.producerRating;
    if (s == OrderStatus.cloturee && myRating == null) {
      buttons.add(OutlinedButton.icon(
        onPressed: () => _rate(context, state),
        icon: const Icon(Icons.star_outline),
        label: Text(asBuyer ? 'Noter le producteur' : 'Noter l’acheteur'),
      ));
    }
    if (myRating != null) {
      buttons.add(Row(children: [
        const Text('Votre note : ', style: TextStyle(color: AppColors.muted)),
        for (var i = 1; i <= 5; i++) Icon(i <= myRating ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.gold, size: 20),
      ]));
    }

    // Étapes qui dépendent d'autres acteurs (agent, transporteur) : simulables en démo.
    final next = switch (s) {
      OrderStatus.payeeSequestre when !asSeller => ('Le producteur confirme', () => state.producerConfirm(order)),
      OrderStatus.enPreparation when !asSeller => ('Le producteur dépose le lot', () => state.declareDeposit(order)),
      OrderStatus.auPointCollecte => ('L’agent contrôle le lot', () => state.recordControl(order, weightKg: order.quantity, grade: Grade.a, conforme: true)),
      OrderStatus.controleeConforme => ('Le transporteur prend en charge', () => state.advance(order, OrderStatus.enLivraison, 'Prise en charge par le transporteur')),
      OrderStatus.enLivraison => ('Le lot est livré', () => state.advance(order, OrderStatus.livree, 'Remis au transformateur')),
      OrderStatus.livree when asSeller => ('L’acheteur confirme la réception', () => state.confirmReception(order)),
      OrderStatus.enLitige => ('L’administrateur tranche (partage)', () => state.advance(order, OrderStatus.cloturee, 'Décision : 90 % au producteur, 10 % remboursés')),
      _ => null,
    };
    if (next != null) {
      buttons.add(TextButton.icon(
        onPressed: next.$2,
        icon: const Icon(Icons.fast_forward, size: 18),
        label: Text('Démo : ${next.$1}'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons),
    );
  }

  Future<void> _confirmReception(BuildContext context, AppState state) async {
    final ok = await confirm(
      context,
      title: 'Tout est conforme ?',
      message: 'En confirmant, ${fcfa(order.goodsAmount)} sont versés au producteur. Cette action est définitive.',
      ok: 'Oui, libérer le paiement',
    );
    if (!ok) return;
    state.confirmReception(order);
    if (context.mounted) await _rate(context, state);
  }

  Future<void> _rate(BuildContext context, AppState state) async {
    final stars = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _RatingSheet(),
    );
    if (stars != null) state.rate(order, stars);
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet();

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 5;
  final _tags = <String>{};
  static const _options = ['Qualité conforme', 'Quantité exacte', 'Ponctuel', 'Bonne communication', 'Emballage soigné'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Votre avis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 40,
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.gold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final t in _options)
                  FilterChip(label: Text(t), selected: _tags.contains(t), onSelected: (v) => setState(() => v ? _tags.add(t) : _tags.remove(t))),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(context, _stars), child: const Text('Envoyer')),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final current = order.status;
    final offFlow = !OrderStatus.flow.contains(current);
    final steps = [...OrderStatus.flow];
    if (offFlow) {
      // Litige, remboursement ou annulation : on montre l'historique réel.
      final reached = order.history.map((e) => e.status).toList();
      steps
        ..retainWhere(reached.contains)
        ..add(current);
    }
    final reachedIndex = steps.lastIndexWhere((s) => order.dateOf(s) != null);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            status: steps[i],
            date: order.dateOf(steps[i]),
            note: _noteFor(steps[i]),
            done: i <= reachedIndex,
            current: i == reachedIndex,
            last: i == steps.length - 1,
          ),
      ],
    );
  }

  String? _noteFor(OrderStatus s) {
    for (final e in order.history.reversed) {
      if (e.status == s) return e.note;
    }
    return null;
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.status, required this.date, required this.note, required this.done, required this.current, required this.last});

  final OrderStatus status;
  final DateTime? date;
  final String? note;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done ? status.color : AppColors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(status.icon, size: 15, color: done ? Colors.white : AppColors.line),
                ),
                if (!last) Expanded(child: Container(width: 2, color: done ? color.withValues(alpha: 0.5) : AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16, top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                      color: done ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                  if (date != null) Text(dateTime(date!), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  if (note != null) Text(note!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
