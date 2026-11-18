import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../orders/order_detail_screen.dart';
import 'payment_dialog.dart';

/// Commande et paiement en séquestre.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.offer});

  final Offer offer;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final TextEditingController _quantity;
  late final TextEditingController _city;
  MobileMoney _payment = MobileMoney.mtn;
  bool _delivery = true;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    final start = o.quantity < o.minOrder * 2 ? o.quantity : o.minOrder * 2;
    _quantity = TextEditingController(text: qty(start).replaceAll(' ', ''));
    _city = TextEditingController(text: AppScope.read(context).me?.city ?? '');
  }

  @override
  void dispose() {
    _quantity.dispose();
    _city.dispose();
    super.dispose();
  }

  double get _q => parseNum(_quantity.text) ?? 0;

  String? get _error {
    final o = widget.offer;
    if (_q <= 0) return 'Indiquez une quantité';
    if (_q < o.minOrder) return 'Minimum ${qty(o.minOrder)} ${o.product.unit}';
    if (_q > o.quantity) return 'Maximum ${qty(o.quantity)} ${o.product.unit}';
    return null;
  }

  Future<void> _pay(int total) async {
    final state = AppScope.read(context);
    final ok = await payWithMobileMoney(context, amount: total, operator: _payment, phone: state.me!.phone);
    if (!ok || !mounted) return;
    final order = state.placeOrder(offer: widget.offer, quantity: _q, payment: _payment, deliveryCity: _city.text.trim(), withDelivery: _delivery);
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final o = widget.offer;
    final goods = (_q * o.unitPrice).round();
    final rate = state.proSubscriber ? 0.02 : 0.03;
    final commission = (goods * rate).round();
    final delivery = _delivery ? state.estimateDelivery(o.distanceKm, _q) : 0;
    final total = goods + commission + delivery;

    return Scaffold(
      appBar: AppBar(title: const Text('Commander')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ProductThumb(o.product, size: 52),
              title: Text(o.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${fcfa(o.unitPrice)}/${o.product.unit} · ${o.producer.displayName}'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Quantité',
              suffixText: o.product.unit,
              errorText: _error,
              helperText: 'Disponible : ${qty(o.quantity)} ${o.product.unit} · minimum ${qty(o.minOrder)}',
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.local_shipping_outlined), label: Text('Livraison')),
              ButtonSegment(value: false, icon: Icon(Icons.warehouse_outlined), label: Text('Enlèvement')),
            ],
            selected: {_delivery},
            onSelectionChanged: (s) => setState(() => _delivery = s.first),
          ),
          const SizedBox(height: 12),
          if (_delivery)
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville de livraison', prefixIcon: Icon(Icons.place_outlined)),
            )
          else
            InfoBanner(icon: Icons.warehouse_outlined, text: 'Vous récupérez le lot contrôlé à : ${o.collectionPoint}.'),
          const SizedBox(height: 20),
          const Text('Paiement', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          PaymentPicker(value: _payment, onChanged: (m) => setState(() => _payment = m)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AmountRow('Marchandise', fcfa(goods), hint: 'Versée intégralement au producteur'),
                  AmountRow('Commission MARCHE.CM (${(rate * 100).round()} %)', fcfa(commission), hint: state.proSubscriber ? 'Tarif Pro' : 'Contrôle qualité, séquestre et suivi inclus'),
                  if (_delivery) AmountRow('Livraison estimée', fcfa(delivery), hint: 'Transporteur partenaire'),
                  const Divider(height: 24),
                  AmountRow('Total à payer', fcfa(total), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.lock_outline,
            color: AppColors.green,
            text: 'Séquestre : l’argent est bloqué jusqu’à votre confirmation de réception. Lot non conforme au contrôle = remboursement intégral.',
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _error == null ? () => _pay(total) : null,
            icon: const Icon(Icons.lock),
            label: Text('Payer ${fcfa(total)}'),
          ),
        ),
      ),
    );
  }
}
