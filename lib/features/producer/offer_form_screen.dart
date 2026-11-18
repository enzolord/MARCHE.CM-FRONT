import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// Publication d'une offre de récolte.
class OfferFormScreen extends StatefulWidget {
  const OfferFormScreen({super.key});

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _minOrder = TextEditingController(text: '1');
  final _description = TextEditingController();
  Product _product = Catalog.tomate;
  Grade _grade = Grade.a;
  DateTime _available = DateTime.now().add(const Duration(days: 2));
  late String _point;
  int _photos = 0;

  @override
  void initState() {
    super.initState();
    final city = AppScope.read(context).me?.city ?? '';
    _point = Catalog.collectionPoints.firstWhere((p) => p.startsWith(city), orElse: () => Catalog.collectionPoints.first);
  }

  @override
  void dispose() {
    for (final c in [_quantity, _price, _minOrder, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _available,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (d != null) setState(() => _available = d);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final state = AppScope.read(context);
    state.publishOffer(
      product: _product,
      quantity: parseNum(_quantity.text)!,
      unitPrice: parseNum(_price.text)!.round(),
      availableFrom: _available,
      grade: _grade,
      collectionPoint: _point,
      description: _description.text.trim(),
      photos: _photos,
      minOrder: parseNum(_minOrder.text) ?? 1,
    );
    await showSuccess(
      context,
      title: state.offline ? 'Offre enregistrée' : 'Offre publiée !',
      message: state.offline
          ? 'Vous êtes hors ligne : l’offre partira automatiquement au retour du réseau.'
          : 'Les transformateurs qui cherchent ce produit près de chez vous viennent d’être alertés.',
      icon: state.offline ? Icons.cloud_upload : Icons.campaign,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final market = state.priceOf(_product);
    final price = parseNum(_price.text);
    final quantity = parseNum(_quantity.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle offre')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Label('Produit'),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in Catalog.all)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${p.emoji} ${p.name}'),
                        selected: _product == p,
                        onSelected: (_) => setState(() => _product = p),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Photos'),
            PhotoPicker(count: _photos, onAdd: () => setState(() => _photos = (_photos + 1).clamp(0, 4)), onRemove: () => setState(() => _photos = (_photos - 1).clamp(0, 4))),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: NumberField(controller: _quantity, label: 'Quantité', suffix: _product.unit, onChanged: (_) => setState(() {}))),
                const SizedBox(width: 12),
                Expanded(child: NumberField(controller: _price, label: 'Prix unitaire', suffix: 'F/${_product.unit}', onChanged: (_) => setState(() {}))),
              ],
            ),
            if (market != null) ...[
              const SizedBox(height: 10),
              InfoBanner(
                icon: Icons.query_stats,
                color: AppColors.blue,
                text: 'Prix moyen à ${market.market} : ${fcfa(market.price)}/${_product.unit} '
                    '(${market.trend >= 0 ? '+' : ''}${market.trend.toStringAsFixed(1).replaceAll('.', ',')} % sur 7 jours).'
                    '${price != null && price > market.price * 1.15 ? ' Votre prix est au-dessus du marché.' : ''}',
              ),
            ],
            if (price != null && quantity != null) ...[
              const SizedBox(height: 10),
              Text('Valeur du lot : ${fcfa(price * quantity)} — vous recevez 100 % du prix, sans commission.', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            NumberField(controller: _minOrder, label: 'Commande minimum', suffix: _product.unit),
            const SizedBox(height: 16),
            const _Label('Qualité estimée'),
            SegmentedButton<Grade>(
              segments: [for (final g in Grade.values) ButtonSegment(value: g, label: Text('${g.code} · ${g.label}'))],
              selected: {_grade},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _grade = s.first),
            ),
            const SizedBox(height: 6),
            const Text('Le grade est confirmé par l’agent au point de collecte.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
              tileColor: Colors.white,
              leading: const Icon(Icons.event_available),
              title: const Text('Disponible à partir du'),
              subtitle: Text(longDate(_available)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _point,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Point de collecte', prefixIcon: Icon(Icons.warehouse_outlined)),
              items: [for (final p in Catalog.collectionPoints) DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _point = v ?? _point),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (variété, conditionnement…)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.shield_outlined,
              color: AppColors.green,
              text: 'Votre numéro n’est jamais affiché. Les échanges et le paiement passent par MARCHE.CM : vous êtes payé à coup sûr.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(state.offline ? Icons.save_alt : Icons.campaign),
              label: Text(state.offline ? 'Enregistrer (hors ligne)' : 'Publier l’offre'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}

/// Sélection de photos (simulée dans la démo).
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({super.key, required this.count, required this.onAdd, required this.onRemove});

  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.image, color: AppColors.green, size: 32),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: InkWell(
                      onTap: onRemove,
                      child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          if (count < 4)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.add_a_photo_outlined, color: AppColors.muted), SizedBox(height: 4), Text('Ajouter', style: TextStyle(fontSize: 12, color: AppColors.muted))],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

