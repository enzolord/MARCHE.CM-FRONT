import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';

/// Demande de préfinancement auprès d'une microfinance partenaire,
/// sur la base de l'historique de ventes dans MARCHE.CM.
class PrefinancingScreen extends StatefulWidget {
  const PrefinancingScreen({super.key});

  @override
  State<PrefinancingScreen> createState() => _PrefinancingScreenState();
}

class _PrefinancingScreenState extends State<PrefinancingScreen> {
  double _amount = 300000;
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ceiling = (state.monthSales * 1.5 / 50000).floor() * 50000;
    final max = ceiling < 100000 ? 100000.0 : ceiling.toDouble();
    if (_amount > max) _amount = max;
    final monthly = (_amount * (1 + 0.015 * _months) / _months).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Préfinancement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InfoBanner(
            icon: Icons.account_balance,
            text: 'Financez intrants et main-d’œuvre avant la récolte. Votre historique de ventes MARCHE.CM sert de garantie auprès de la microfinance partenaire.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Votre éligibilité', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  AmountRow('Ventes réalisées sur MARCHE.CM', fcfa(state.monthSales)),
                  AmountRow('Note moyenne', '${state.me!.rating.toStringAsFixed(1).replaceAll('.', ',')} / 5'),
                  AmountRow('Score de confiance', '${(state.me!.trustScore * 100).round()} %'),
                  const Divider(height: 20),
                  AmountRow('Plafond estimé', fcfa(max), bold: true, color: AppColors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Montant : ${fcfa(_amount)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Slider(
            value: _amount,
            min: 50000,
            max: max,
            divisions: ((max - 50000) / 25000).round().clamp(1, 200),
            label: fcfa(_amount),
            onChanged: (v) => setState(() => _amount = v),
          ),
          const Text('Durée de remboursement', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('3 mois')),
              ButtonSegment(value: 6, label: Text('6 mois')),
              ButtonSegment(value: 9, label: Text('9 mois')),
            ],
            selected: {_months},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _months = s.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AmountRow('Mensualité estimée', fcfa(monthly), bold: true),
                  const AmountRow('Taux indicatif', '1,5 % par mois', hint: 'Fixé par le partenaire, à confirmer'),
                  const AmountRow('Remboursement', 'Prélevé sur vos ventes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.prefinancing.isNotEmpty) ...[
            const Text('Mes demandes', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final p in state.prefinancing)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.request_quote_outlined),
                  title: Text('${fcfa(p.amount)} sur ${p.months} mois'),
                  subtitle: Text(p.partner),
                  trailing: Pill(p.status, color: AppColors.blue),
                ),
              ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: () {
              state.requestPrefinancing(_amount.round(), _months);
              showSuccess(context, title: 'Demande envoyée', message: 'Le partenaire vous répond sous 72 h par notification et SMS.', icon: Icons.account_balance);
            },
            child: const Text('Envoyer la demande'),
          ),
        ],
      ),
    );
  }
}
