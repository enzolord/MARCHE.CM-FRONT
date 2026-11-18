import 'package:flutter/material.dart';

import '../../core/cards.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../shell/home_shell.dart';
import 'flash_detail_screen.dart';

/// Espace Ventes Flash côté transformateur.
class FlashMarketScreen extends StatefulWidget {
  const FlashMarketScreen({super.key});

  @override
  State<FlashMarketScreen> createState() => _FlashMarketScreenState();
}

class _FlashMarketScreenState extends State<FlashMarketScreen> {
  bool _endingSoon = false;
  double _maxKm = 300;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final lots = state
        .openFlashLots(now)
        .where((l) => l.distanceKm <= _maxKm)
        .where((l) => !_endingSoon || l.end.difference(now).inHours < 12)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.bolt, color: AppColors.flash), SizedBox(width: 4), Text('Ventes Flash')]),
        actions: const [TopActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.flashLight, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.recycling, color: AppColors.flash, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lots mûrs ou à écouler vite, à prix dégressif. Idéal pour purées, jus, farines et chips. Le premier qui paie emporte le lot.',
                    style: TextStyle(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(label: const Text('Se termine bientôt'), selected: _endingSoon, onSelected: (v) => setState(() => _endingSoon = v)),
              for (final km in [100.0, 300.0, 1200.0])
                ChoiceChip(
                  label: Text(km >= 1200 ? 'Tout le pays' : '< ${km.round()} km'),
                  selected: _maxKm == km,
                  onSelected: (_) => setState(() => _maxKm = km),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (lots.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(icon: Icons.bolt, title: 'Aucun lot pour ces filtres', message: 'Activez les alertes : vous recevrez un SMS dès qu’un lot est publié près de vous.'),
            ),
          for (final lot in lots)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FlashCard(lot: lot, onTap: () => go<void>(context, FlashDetailScreen(lot: lot))),
            ),
        ],
      ),
    );
  }
}
