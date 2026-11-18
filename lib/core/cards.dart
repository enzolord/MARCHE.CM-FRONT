import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import 'format.dart';
import 'theme.dart';
import 'widgets.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.onTap, this.score, this.showProducer = true, this.trailing});

  final Offer offer;
  final VoidCallback? onTap;
  final int? score;
  final bool showProducer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(offer.product, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (score != null) Pill('$score %', color: AppColors.flash, icon: Icons.bolt),
                        ?trailing,
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '${groupThousands(offer.unitPrice)} F',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.green, fontSize: 16),
                        ),
                        TextSpan(text: ' /${offer.product.unit}  ·  ${qty(offer.quantity)} ${offer.product.unit} dispo.'),
                      ]),
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        GradeBadge(offer.grade),
                        if (offer.groupSale) const Pill('Vente groupée', color: AppColors.blue, icon: Icons.groups),
                        if (offer.status != OfferStatus.active) Pill(offer.status.label, color: offer.status.color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (showProducer)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              offer.producer.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (offer.producer.verified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 14)],
                          const SizedBox(width: 8),
                          Stars(offer.producer.rating, size: 12),
                        ],
                      ),
                    const SizedBox(height: 2),
                    IconLine(
                      Icons.place_outlined,
                      offer.distanceKm > 0
                          ? '${offer.city} · ${qty(offer.distanceKm)} km · dès le ${shortDate(offer.availableFrom)}'
                          : '${offer.city} · dès le ${shortDate(offer.availableFrom)}',
                      size: 12.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashCard extends StatelessWidget {
  const FlashCard({super.key, required this.lot, this.onTap, this.compact = false});

  final FlashLot lot;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.flash.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Ticker(
          builder: (context, now) {
            final left = lot.end.difference(now);
            final urgent = left.inHours < 6;
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProductThumb(lot.product, size: compact ? 44 : 56, flash: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lot.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${qty(lot.quantity)} ${lot.product.unit} · ${lot.city}${lot.distanceKm > 0 ? ' · ${qty(lot.distanceKm)} km' : ''}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Pill(lot.discountAt(now) == 0 ? 'Nouveau' : '-${lot.discountAt(now)} %', color: AppColors.flash, filled: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: FlashPrice(lot)),
                      Pill(
                        lot.sold ? 'Vendu' : remaining(left),
                        color: lot.sold ? AppColors.muted : (urgent ? AppColors.red : AppColors.flash),
                        icon: lot.sold ? Icons.check : Icons.timer_outlined,
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: (now.difference(lot.start).inMinutes / lot.end.difference(lot.start).inMinutes).clamp(0.0, 1.0),
                        backgroundColor: AppColors.flashLight,
                        color: urgent ? AppColors.red : AppColors.flash,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.asBuyer, this.onTap});

  final Order order;
  final bool asBuyer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final other = asBuyer ? order.producer : order.buyer;
    final s = order.status;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductThumb(order.product, size: 52, flash: order.isFlash),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.shortId, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted, fontSize: 12.5)),
                        if (order.isFlash) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.bolt, size: 14, color: AppColors.flash),
                        ],
                        const Spacer(),
                        Text(ago(order.history.isEmpty ? order.createdAt : order.history.last.at), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${qty(order.quantity)} ${order.product.unit} · ${order.product.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      '${asBuyer ? 'De' : 'Pour'} ${other.displayName} · ${fcfa(asBuyer ? order.totalPaid : order.goodsAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Pill(s.label, color: s.color, icon: s.icon),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class DemandCard extends StatelessWidget {
  const DemandCard({super.key, required this.demand, this.score, this.onTap, this.action});

  final Demand demand;
  final int? score;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProductThumb(demand.product, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recherche ${qty(demand.quantity)} ${demand.product.unit} de ${demand.product.name.toLowerCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          '${demand.buyer.displayName} · ${demand.buyer.city}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (score != null) Pill('$score %', color: AppColors.flash, icon: Icons.bolt),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill('Max ${fcfa(demand.maxPrice)}/${demand.product.unit}', color: AppColors.green),
                  Pill('Avant le ${shortDate(demand.deadline)}', color: AppColors.blue, icon: Icons.event),
                  if (demand.grade != null) GradeBadge(demand.grade!),
                  if (demand.recurring) const Pill('Récurrent', color: AppColors.muted, icon: Icons.autorenew),
                  Pill('${demand.responses} réponse(s)', color: AppColors.muted),
                ],
              ),
              if (action != null) ...[const SizedBox(height: 10), action!],
            ],
          ),
        ),
      ),
    );
  }
}
