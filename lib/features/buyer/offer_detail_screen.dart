import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../messages/chat_screen.dart';
import 'checkout_screen.dart';

class OfferDetailScreen extends StatelessWidget {
  const OfferDetailScreen({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = offer.producer == state.me;
    final market = state.priceOf(offer.product);
    final p = offer.producer;
    final canBuy = state.role == Role.transformateur && offer.status == OfferStatus.active;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.greenLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.greenLight, alignment: Alignment.center, child: Text(offer.product.emoji, style: const TextStyle(fontSize: 110))),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Pill('${offer.photos} photo(s)', color: AppColors.ink, icon: Icons.photo_library_outlined, filled: true),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    GradeBadge(offer.grade),
                    if (offer.groupSale) const Pill('Vente groupée', color: AppColors.blue, icon: Icons.groups),
                    Pill(offer.status.label, color: offer.status.color),
                  ]),
                  const SizedBox(height: 10),
                  Text(offer.product.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: fcfa(offer.unitPrice), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.green)),
                      TextSpan(text: ' / ${offer.product.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 16)),
                    ]),
                  ),
                  if (market != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _compare(offer.unitPrice, market.price, market.market),
                      style: TextStyle(color: offer.unitPrice <= market.price ? AppColors.green : AppColors.flash, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _Info(Icons.inventory_2_outlined, 'Quantité disponible', '${qty(offer.quantity)} ${offer.product.unit}'),
                          _Info(Icons.shopping_basket_outlined, 'Commande minimum', '${qty(offer.minOrder)} ${offer.product.unit}'),
                          _Info(Icons.event_available, 'Disponible dès le', longDate(offer.availableFrom)),
                          _Info(Icons.warehouse_outlined, 'Point de collecte', offer.collectionPoint),
                          if (offer.distanceKm > 0) _Info(Icons.route_outlined, 'Distance', '${qty(offer.distanceKm)} km de vous'),
                        ],
                      ),
                    ),
                  ),
                  if (offer.description.isNotEmpty) ...[
                    const SectionTitle('Description', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
                    Text(offer.description, style: const TextStyle(height: 1.45)),
                  ],
                  const SectionTitle('Producteur', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          UserAvatar(p, radius: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Flexible(child: Text(p.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                                  if (p.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
                                ]),
                                const SizedBox(height: 2),
                                Text('${p.role.label} · ${p.city}${p.members > 0 ? ' · ${p.members} membres' : ''}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Stars(p.rating, reviews: p.reviews),
                                  const SizedBox(width: 10),
                                  Pill('Confiance ${(p.trustScore * 100).round()} %', color: AppColors.green),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const InfoBanner(
                    icon: Icons.verified_user_outlined,
                    color: AppColors.green,
                    text: 'Paiement protégé : votre argent reste bloqué jusqu’à la livraison. Le lot est pesé et contrôlé au point de collecte avant de partir.',
                  ),
                  if (mine) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: KpiCard(label: 'Vues', value: '${offer.views}', icon: Icons.visibility_outlined, color: AppColors.blue)),
                        const SizedBox(width: 10),
                        Expanded(child: KpiCard(label: 'Valeur du lot', value: fcfa(offer.total), icon: Icons.payments_outlined)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: canBuy
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => go<void>(context, ChatScreen(conversation: state.conversationWith(p, '${offer.product.name} — ${qty(offer.quantity)} ${offer.product.unit}'))),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Négocier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => go<void>(context, CheckoutScreen(offer: offer)),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Commander'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  static String _compare(int price, int market, String place) {
    final diff = ((price - market) / market * 100).round();
    if (diff == 0) return 'Au prix du marché ($place)';
    return diff < 0 ? '${-diff} % sous le prix moyen à $place' : '$diff % au-dessus du prix moyen à $place';
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          const SizedBox(width: 8),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
