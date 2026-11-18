import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// Contrats de pré-récolte : prix et volume fixés avant la saison.
class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final list = state.myContracts;
    return Scaffold(
      appBar: AppBar(title: const Text('Contrats pré-récolte')),
      floatingActionButton: state.isSeller
          ? FloatingActionButton.extended(
              onPressed: () => _propose(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Proposer'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const InfoBanner(
            icon: Icons.handshake,
            color: AppColors.green,
            text: 'Le transformateur verse un acompte (20 %) à la signature. Le producteur sécurise son revenu, le transformateur ses volumes.',
          ),
          const SizedBox(height: 12),
          if (list.isEmpty) const Text('Aucun contrat pour le moment.', style: TextStyle(color: AppColors.muted)),
          for (final c in list)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProductThumb(c.product, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${qty(c.quantity)} ${c.product.unit} de ${c.product.name.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(state.me == c.producer ? 'Avec ${c.buyer.displayName}' : 'Avec ${c.producer.displayName}', style: const TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Pill(c.status.label, color: c.status.color),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AmountRow('Prix fixé', '${fcfa(c.fixedPrice)}/${c.product.unit}'),
                    AmountRow('Récolte prévue', longDate(c.harvestDate)),
                    AmountRow('Valeur du contrat', fcfa(c.total)),
                    AmountRow('Acompte (${(c.depositRate * 100).round()} %)', fcfa(c.deposit), bold: true),
                    if (c.status == ContractStatus.propose) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        onPressed: () {
                          state.signContract(c);
                          toast(context, 'Contrat signé électroniquement');
                        },
                        child: const Text('Signer le contrat'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _propose(BuildContext context, AppState state) async {
    var product = Catalog.tomate;
    var buyer = state.data.transformateur;
    final q = TextEditingController();
    final p = TextEditingController();
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
              const Text('Proposer un contrat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              DropdownButtonFormField<Product>(
                initialValue: product,
                decoration: const InputDecoration(labelText: 'Produit'),
                items: [for (final x in Catalog.all) DropdownMenuItem(value: x, child: Text('${x.emoji}  ${x.name}'))],
                onChanged: (v) => setSheet(() => product = v ?? product),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppUser>(
                initialValue: buyer,
                decoration: const InputDecoration(labelText: 'Transformateur'),
                items: [
                  for (final u in [state.data.transformateur, state.data.transformateur2, state.data.transformateur3])
                    DropdownMenuItem(value: u, child: Text(u.displayName)),
                ],
                onChanged: (v) => setSheet(() => buyer = v ?? buyer),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: NumberField(controller: q, label: 'Quantité', suffix: product.unit)),
                  const SizedBox(width: 12),
                  Expanded(child: NumberField(controller: p, label: 'Prix fixé', suffix: 'F')),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Envoyer la proposition')),
            ],
          ),
        ),
      ),
    );
    final quantity = parseNum(q.text);
    final price = parseNum(p.text);
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      q.dispose();
      p.dispose();
    });
    if (ok != true || quantity == null || price == null || quantity <= 0 || price <= 0) return;
    state.proposeContract(product: product, quantity: quantity, price: price.round(), harvest: DateTime.now().add(const Duration(days: 90)), buyer: buyer);
    if (context.mounted) toast(context, 'Proposition envoyée à ${buyer.displayName}');
  }
}
