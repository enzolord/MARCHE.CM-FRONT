import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

/// Bourse des prix et météo agricole.
class PricesScreen extends StatelessWidget {
  const PricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bourse des prix')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InfoBanner(
            icon: Icons.info_outline,
            text: 'Prix moyens relevés sur les marchés et sur les ventes conclues dans MARCHE.CM, mis à jour chaque semaine.',
          ),
          const SizedBox(height: 12),
          for (final p in state.prices)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: PriceTile(price: p, expanded: true)),
          const SectionTitle('Météo à 5 jours', padding: EdgeInsets.fromLTRB(0, 16, 0, 8)),
          WeatherStrip(days: state.weather),
          const SizedBox(height: 12),
          const InfoBanner(
            icon: Icons.agriculture,
            color: AppColors.green,
            text: 'Conseil : fortes pluies demain. Récoltez et mettez à l’abri les produits sensibles avant ce soir.',
          ),
        ],
      ),
    );
  }
}

class PriceTile extends StatelessWidget {
  const PriceTile({super.key, required this.price, this.expanded = false});

  final MarketPrice price;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final up = price.trend > 0;
    final flat = price.trend == 0;
    final color = flat ? AppColors.muted : (up ? AppColors.green : AppColors.red);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductThumb(price.product, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(price.market, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            if (expanded) ...[Sparkline(price.history, color: color, width: 70), const SizedBox(width: 12)],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${groupThousands(price.price)} F/${price.product.unit}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(flat ? Icons.trending_flat : (up ? Icons.trending_up : Icons.trending_down), size: 16, color: color),
                    const SizedBox(width: 2),
                    Text('${up ? '+' : ''}${price.trend.toStringAsFixed(1).replaceAll('.', ',')} %', style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherStrip extends StatelessWidget {
  const WeatherStrip({super.key, required this.days});

  final List<WeatherDay> days;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Row(
          children: [
            for (final d in days)
              Expanded(
                child: Column(
                  children: [
                    Text(d.day, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Icon(d.icon, color: d.rainMm > 5 ? AppColors.blue : AppColors.gold),
                    const SizedBox(height: 6),
                    Text('${d.max}°', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${d.min}°', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${d.rainMm} mm', style: const TextStyle(color: AppColors.blue, fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
