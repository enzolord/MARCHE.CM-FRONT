import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../orders/order_detail_screen.dart';
import 'payment_dialog.dart';

class FlashDetailScreen extends StatefulWidget {
  const FlashDetailScreen({super.key, required this.lot});

  final FlashLot lot;

  @override
  State<FlashDetailScreen> createState() => _FlashDetailScreenState();
}

class _FlashDetailScreenState extends State<FlashDetailScreen> {
  MobileMoney _payment = MobileMoney.mtn;
  DateTime? _reservedUntil;

  Future<void> _reserve() async {
    setState(() => _reservedUntil = DateTime.now().add(const Duration(minutes: 30)));
  }

  Future<void> _pay() async {
    final state = AppScope.read(context);
    final lot = widget.lot;
    final unit = lot.priceAt(DateTime.now());
    final goods = (unit * lot.quantity).round();
    final total = goods + (goods * 0.05).round() + state.estimateDelivery(lot.distanceKm, lot.quantity);
    final ok = await payWithMobileMoney(context, amount: total, operator: _payment, phone: state.me!.phone);
    if (!ok || !mounted) return;
    final order = state.buyFlash(lot: lot, payment: _payment);
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lot = widget.lot;
    final isBuyer = state.role == Role.transformateur;
    return Scaffold(
      appBar: AppBar(title: Text('Flash · ${lot.product.name}')),
      body: Ticker(
        builder: (context, now) {
          final left = lot.end.difference(now);
          final next = lot.nextDropAt(now);
          final unit = lot.priceAt(now);
          final goods = (unit * lot.quantity).round();
          final reservedLeft = _reservedUntil?.difference(now);
          if (reservedLeft != null && reservedLeft.isNegative) {
            _reservedUntil = null;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.flashLight, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Text(lot.product.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    FlashPrice(lot, big: true),
                    const SizedBox(height: 6),
                    Pill('-${lot.discountAt(now)} % · prix plancher ${fcfa(lot.floorPrice)}', color: AppColors.flash),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _Counter(label: 'Fin de la vente', value: remaining(left), urgent: left.inHours < 6)),
                        const SizedBox(width: 10),
                        Expanded(child: _Counter(label: 'Prochaine baisse', value: next == null ? '—' : remaining(next.difference(now)))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AmountRow('Quantité', '${qty(lot.quantity)} ${lot.product.unit}'),
                      AmountRow('Lieu', lot.distanceKm > 0 ? '${lot.city} (${qty(lot.distanceKm)} km)' : lot.city),
                      AmountRow('Producteur', lot.producer.displayName),
                      AmountRow('Intéressés', '${lot.watchers} transformateur(s)'),
                      const Divider(height: 20),
                      const Text('État du lot', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(lot.condition, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ),
              if (isBuyer && lot.isOpen(now)) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        AmountRow('Lot complet au prix actuel', fcfa(goods)),
                        AmountRow('Commission Flash (5 %)', fcfa((goods * 0.05).round())),
                        AmountRow('Enlèvement express', fcfa(state.estimateDelivery(lot.distanceKm, lot.quantity))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (reservedLeft == null || reservedLeft.isNegative)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.flash),
                    onPressed: _reserve,
                    icon: const Icon(Icons.timer),
                    label: const Text('Réserver le lot (30 min pour payer)'),
                  )
                else ...[
                  InfoBanner(
                    icon: Icons.timer,
                    color: AppColors.flash,
                    text: 'Lot réservé pour vous encore ${remaining(reservedLeft)}. Passé ce délai, il est remis en vente.',
                  ),
                  const SizedBox(height: 12),
                  PaymentPicker(value: _payment, onChanged: (m) => setState(() => _payment = m)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _pay, icon: const Icon(Icons.lock), label: const Text('Payer maintenant')),
                ],
              ],
              if (!lot.isOpen(now)) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  icon: lot.sold ? Icons.check_circle : Icons.timer_off,
                  color: AppColors.muted,
                  text: lot.sold ? 'Ce lot a été vendu.' : 'La vente est terminée.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value, this.urgent = false});

  final String label;
  final String value;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: urgent ? AppColors.red : AppColors.ink)),
        ],
      ),
    );
  }
}
