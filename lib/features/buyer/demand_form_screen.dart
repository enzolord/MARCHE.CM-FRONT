import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// Publication d'un besoin en matières premières.
class DemandFormScreen extends StatefulWidget {
  const DemandFormScreen({super.key});

  @override
  State<DemandFormScreen> createState() => _DemandFormScreenState();
}

class _DemandFormScreenState extends State<DemandFormScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  Product _product = Catalog.tomate;
  Grade? _grade;
  late String _region;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _recurring = false;

  @override
  void initState() {
    super.initState();
    _region = AppScope.read(context).me?.region ?? 'Littoral';
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final state = AppScope.read(context);
    state.publishDemand(
      product: _product,
      quantity: parseNum(_quantity.text)!,
      maxPrice: parseNum(_price.text)!.round(),
      deadline: _deadline,
      region: _region,
      grade: _grade,
      recurring: _recurring,
    );
    await showSuccess(context, title: 'Besoin publié', message: 'Les producteurs qui correspondent sont alertés. Vous recevrez leurs propositions ici.', icon: Icons.campaign);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final market = AppScope.of(context).priceOf(_product);
    return Scaffold(
      appBar: AppBar(title: const Text('Publier un besoin')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Product>(
              initialValue: _product,
              decoration: const InputDecoration(labelText: 'Produit recherché'),
              items: [for (final p in Catalog.all) DropdownMenuItem(value: p, child: Text('${p.emoji}  ${p.name}'))],
              onChanged: (p) => setState(() => _product = p ?? _product),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: NumberField(controller: _quantity, label: 'Quantité', suffix: _product.unit)),
                const SizedBox(width: 12),
                Expanded(child: NumberField(controller: _price, label: 'Prix maximum', suffix: 'F/${_product.unit}')),
              ],
            ),
            if (market != null) ...[
              const SizedBox(height: 8),
              Text('Repère : ${fcfa(market.price)}/${_product.unit} à ${market.market}', style: const TextStyle(color: AppColors.blue)),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'Région d’approvisionnement'),
              items: [for (final r in Catalog.regions) DropdownMenuItem(value: r, child: Text(r))],
              onChanged: (v) => setState(() => _region = v ?? _region),
            ),
            const SizedBox(height: 16),
            const Text('Grade exigé', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Indifférent'), selected: _grade == null, onSelected: (_) => setState(() => _grade = null)),
                for (final g in Grade.values)
                  ChoiceChip(label: Text('${g.code} · ${g.label}'), selected: _grade == g, onSelected: (_) => setState(() => _grade = g)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
              leading: const Icon(Icons.event),
              title: const Text('Livraison souhaitée avant le'),
              subtitle: Text(longDate(_deadline)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _deadline = d);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Besoin récurrent'),
              subtitle: const Text('Je commande ce produit chaque mois'),
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.campaign), label: const Text('Publier le besoin')),
          ],
        ),
      ),
    );
  }
}
