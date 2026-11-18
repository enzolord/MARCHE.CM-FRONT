import 'package:flutter/material.dart';

import '../../core/cards.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../buyer/flash_detail_screen.dart';
import '../buyer/offer_detail_screen.dart';
import '../shell/home_shell.dart';
import 'flash_form_screen.dart';
import 'offer_form_screen.dart';

class MyOffersScreen extends StatelessWidget {
  const MyOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final offers = state.myOffers;
    final flash = state.myFlashLots;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes offres'),
          actions: const [TopActions()],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Offres (${offers.length})'),
              Tab(text: 'Ventes Flash (${flash.length})'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () {
              final tab = DefaultTabController.of(context).index;
              go<void>(context, tab == 0 ? const OfferFormScreen() : const FlashFormScreen());
            },
            icon: const Icon(Icons.add),
            label: const Text('Publier'),
          ),
        ),
        body: TabBarView(
          children: [
            offers.isEmpty
                ? EmptyState(
                    icon: Icons.storefront,
                    title: 'Aucune offre',
                    message: 'Publiez votre première récolte : les transformateurs de votre zone seront alertés.',
                    action: 'Publier une offre',
                    onAction: () => go<void>(context, const OfferFormScreen()),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: offers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = offers[i];
                      return OfferCard(
                        offer: o,
                        showProducer: false,
                        trailing: _OfferMenu(offer: o),
                        onTap: () => go<void>(context, OfferDetailScreen(offer: o)),
                      );
                    },
                  ),
            flash.isEmpty
                ? EmptyState(
                    icon: Icons.bolt,
                    title: 'Aucune Vente Flash',
                    message: 'Un lot qui risque de se perdre ? Vendez-le vite à prix dégressif.',
                    action: 'Lancer une Vente Flash',
                    onAction: () => go<void>(context, const FlashFormScreen()),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: flash.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return const InfoBanner(
                          icon: Icons.trending_down,
                          color: AppColors.flash,
                          text: 'Le prix baisse toutes les 6 h jusqu’à votre prix plancher. Un lot non vendu peut être proposé en sous-produit ou en don.',
                        );
                      }
                      final lot = flash[i - 1];
                      return FlashCard(lot: lot, onTap: () => go<void>(context, FlashDetailScreen(lot: lot)));
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _OfferMenu extends StatelessWidget {
  const _OfferMenu({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (v) async {
        final state = AppScope.read(context);
        if (v == 'withdraw') {
          final ok = await confirm(context, title: 'Retirer cette offre ?', message: 'Elle ne sera plus visible par les transformateurs.', ok: 'Retirer', danger: true);
          if (ok) state.withdrawOffer(offer);
        } else if (v == 'flash' && context.mounted) {
          go<void>(context, FlashFormScreen(product: offer.product, quantity: offer.quantity, price: offer.unitPrice));
        } else if (v == 'stats' && context.mounted) {
          await showSuccess(
            context,
            icon: Icons.insights,
            color: AppColors.blue,
            title: '${offer.views} vues',
            message: 'Publiée ${ago(offer.createdAt)}. Les offres avec photos reçoivent en moyenne 3 fois plus de demandes.',
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'stats', child: Text('Statistiques')),
        if (offer.product.perishable && offer.status == OfferStatus.active)
          const PopupMenuItem(value: 'flash', child: Text('Passer en Vente Flash')),
        if (offer.status == OfferStatus.active) const PopupMenuItem(value: 'withdraw', child: Text('Retirer l’offre')),
      ],
    );
  }
}
