import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import 'offer_form_screen.dart';

/// Déclaration d'un lot périssable en Vente Flash.
class FlashFormScreen extends StatefulWidget {
  const FlashFormScreen({super.key, this.product, this.quantity, this.price});

  final Product? product;
  final double? quantity;
  final int? price;

  @override
  State<FlashFormScreen> createState() => _FlashFormScreenState();
}

class _FlashFormScreenState extends State<FlashFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _floor;
  final _condition = TextEditingController();
  late Product _product;
  int _hours = 48;
  int _photos = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product ?? Catalog.tomate;
    _quantity = TextEditingController(text: widget.quantity == null ? '' : qty(widget.quantity!).replaceAll(' ', ''));
    final p = widget.price;
    _price = TextEditingController(text: p == null ? '' : '${(p * 0.85).round()}');
    _floor = TextEditingController(text: p == null ? '' : '${(p * 0.45).round()}');
  }

  @override
  void dispose() {
    for (final c in [_quantity, _price, _floor, _condition]) {
      c.dispose();
    }
    super.dispose();
  }

  List<(String, int)> _schedule() {
    final initial = parseNum(_price.text)?.round();
    final floor = parseNum(_floor.text)?.round();
    if (initial == null || floor == null || initial <= 0 || floor <= 0 || floor > initial) return const [];
    final now = DateTime.now();
    final preview = FlashLot(
      id: 'preview',
      product: _product,
      producer: AppScope.read(context).me!,
      quantity: 1,
      initialPrice: initial,
      floorPrice: floor,
      start: now,
      end: now.add(Duration(hours: _hours)),
      condition: '',
      city: '',
      distanceKm: 0,
    );
    return [
      for (var h = 0; h < _hours; h += 6) ('+$h h', preview.priceAt(now.add(Duration(hours: h, minutes: 1)))),
    ];
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final state = AppScope.read(context);
    state.publishFlash(
      product: _product,
      quantity: parseNum(_quantity.text)!,
      initialPrice: parseNum(_price.text)!.round(),
      floorPrice: parseNum(_floor.text)!.round(),
      hours: _hours,
      condition: _condition.text.trim().isEmpty ? 'Lot à écouler rapidement.' : _condition.text.trim(),
    );
    await showSuccess(
      context,
      icon: Icons.bolt,
      color: AppColors.flash,
      title: 'Vente Flash lancée',
      message: 'Les transformateurs proches reçoivent une alerte et un SMS. Le premier qui paie emporte le lot.',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule();
    return Scaffold(
      appBar: AppBar(title: const Text('Vente Flash')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const InfoBanner(
              icon: Icons.bolt,
              color: AppColors.flash,
              text: 'Pour un lot périssable ou proche de la péremption. Le prix baisse toutes les 6 h, sans jamais passer sous votre prix plancher.',
            ),
            const SizedBox(height: 16),
            const Text('Produit', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in Catalog.all.where((p) => p.perishable))
                  ChoiceChip(
                    label: Text('${p.emoji} ${p.name}'),
                    selected: _product == p,
                    onSelected: (_) => setState(() => _product = p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PhotoPicker(count: _photos, onAdd: () => setState(() => _photos = (_photos + 1).clamp(0, 4)), onRemove: () => setState(() => _photos = (_photos - 1).clamp(0, 4))),
            const SizedBox(height: 16),
            NumberField(controller: _quantity, label: 'Quantité', suffix: _product.unit),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: NumberField(controller: _price, label: 'Prix de départ', suffix: 'F', onChanged: (_) => setState(() {}))),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberField(
                    controller: _floor,
                    label: 'Prix plancher',
                    suffix: 'F',
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final f = parseNum(v);
                      final p = parseNum(_price.text);
                      if (f == null || f <= 0) return 'Valeur requise';
                      if (p != null && f > p) return 'Supérieur au départ';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Durée de la vente', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 24, label: Text('24 h')),
                ButtonSegment(value: 48, label: Text('48 h')),
                ButtonSegment(value: 72, label: Text('72 h')),
              ],
              selected: {_hours},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _hours = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _condition,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'État du lot (maturité, défauts…)', alignLabelWithHint: true),
            ),
            if (schedule.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Évolution du prix', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final (label, price) in schedule)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(width: 56, child: Text(label, style: const TextStyle(color: AppColors.muted))),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (_, c) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 10,
                                      width: c.maxWidth * price / schedule.first.$2,
                                      decoration: BoxDecoration(color: AppColors.flash.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(5)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(width: 72, child: Text('${groupThousands(price)} F', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.recycling,
              color: AppColors.green,
              text: 'Lot non vendu à la fin ? Vous pourrez le proposer en sous-produit (alimentation animale, compost) ou en don.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.flash),
              onPressed: _submit,
              icon: const Icon(Icons.bolt),
              label: const Text('Lancer la Vente Flash'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
