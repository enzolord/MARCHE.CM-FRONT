import 'package:flutter/material.dart';

import '../../core/cards.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';
import 'offer_detail_screen.dart';

enum _Sort {
  distance('Plus proches'),
  price('Prix croissant'),
  recent('Plus récentes'),
  rating('Mieux notés');

  const _Sort(this.label);
  final String label;
}

/// Catalogue des offres, avec recherche et filtres.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, this.standalone = false, this.category});

  final bool standalone;
  final String? category;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _search = TextEditingController();
  String? _category;
  _Sort _sort = _Sort.distance;
  double _maxKm = 1200;
  Grade? _grade;
  bool _groupOnly = false;
  bool _verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _activeFilters => (_maxKm < 1200 ? 1 : 0) + (_grade != null ? 1 : 0) + (_groupOnly ? 1 : 0) + (_verifiedOnly ? 1 : 0);

  List<Offer> _filter(List<Offer> all) {
    final q = _search.text.trim().toLowerCase();
    final list = all.where((o) {
      if (q.isNotEmpty &&
          !o.product.name.toLowerCase().contains(q) &&
          !o.city.toLowerCase().contains(q) &&
          !o.producer.displayName.toLowerCase().contains(q)) {
        return false;
      }
      if (_category != null && o.product.category != _category) return false;
      if (o.distanceKm > _maxKm) return false;
      if (_grade != null && o.grade != _grade) return false;
      if (_groupOnly && !o.groupSale) return false;
      if (_verifiedOnly && !o.producer.verified) return false;
      return true;
    }).toList();
    switch (_sort) {
      case _Sort.distance:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case _Sort.price:
        list.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
      case _Sort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.rating:
        list.sort((a, b) => b.producer.rating.compareTo(a.producer.rating));
    }
    return list;
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback fn) {
            setSheet(fn);
            setState(() {});
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(_maxKm >= 1200 ? 'Distance : toutes' : 'Distance : moins de ${_maxKm.round()} km', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(value: _maxKm, min: 25, max: 1200, divisions: 47, onChanged: (v) => update(() => _maxKm = v)),
                  const Text('Grade', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: const Text('Tous'), selected: _grade == null, onSelected: (_) => update(() => _grade = null)),
                      for (final g in Grade.values)
                        ChoiceChip(label: Text('${g.code} · ${g.label}'), selected: _grade == g, onSelected: (_) => update(() => _grade = g)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ventes groupées (coopératives)'),
                    value: _groupOnly,
                    onChanged: (v) => update(() => _groupOnly = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Producteurs vérifiés uniquement'),
                    value: _verifiedOnly,
                    onChanged: (v) => update(() => _verifiedOnly = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => update(() {
                            _maxKm = 1200;
                            _grade = null;
                            _groupOnly = false;
                            _verifiedOnly = false;
                          }),
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voir les offres'))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = _filter(state.marketOffers);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marché'),
        actions: widget.standalone ? null : const [TopActions()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    autofocus: widget.standalone && widget.category == null,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Produit, ville, producteur…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _openFilters,
                  icon: CountBadge(count: _activeFilters, child: const Icon(Icons.tune)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: const Text('Tout'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                ),
                for (final c in Catalog.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Text('${results.length} offre(s)', style: const TextStyle(color: AppColors.muted)),
                const Spacer(),
                PopupMenuButton<_Sort>(
                  initialValue: _sort,
                  onSelected: (s) => setState(() => _sort = s),
                  itemBuilder: (_) => [for (final s in _Sort.values) PopupMenuItem(value: s, child: Text(s.label))],
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.sort, size: 18),
                        const SizedBox(width: 4),
                        Text(_sort.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(icon: Icons.search_off, title: 'Aucune offre', message: 'Élargissez vos filtres ou publiez une demande : les producteurs vous répondront.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => OfferCard(
                      offer: results[i],
                      onTap: () => go<void>(context, OfferDetailScreen(offer: results[i])),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
