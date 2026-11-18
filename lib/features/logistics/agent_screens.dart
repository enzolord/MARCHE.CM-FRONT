import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/qr.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../producer/offer_form_screen.dart';
import '../shell/home_shell.dart';

/// Espace agent terrain : réception, pesée et contrôle qualité des lots.
class AgentHome extends StatelessWidget {
  const AgentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final here = state.lotsToControl.where((o) => o.status == OrderStatus.auPointCollecte).toList();
    final expected = state.lotsToControl.where((o) => o.status != OrderStatus.auPointCollecte).toList();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Point de collecte'),
            Text(state.me!.city, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: const [TopActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: KpiCard(label: 'Lots à contrôler', value: '${here.length}', icon: Icons.inventory_2_outlined, color: AppColors.flash)),
              const SizedBox(width: 10),
              Expanded(child: KpiCard(label: 'Lots attendus', value: '${expected.length}', icon: Icons.schedule, color: AppColors.blue)),
              const SizedBox(width: 10),
              Expanded(child: KpiCard(label: 'Contrôlés', value: '${state.controlledLots.length}', icon: Icons.verified_outlined)),
            ],
          ),
          ),
          const SectionTitle('Présents au point de collecte', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          if (here.isEmpty) const Text('Aucun lot en attente de contrôle.', style: TextStyle(color: AppColors.muted)),
          for (final o in here) _LotTile(order: o, onTap: () => go<void>(context, ControlScreen(order: o))),
          const SectionTitle('Attendus', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          if (expected.isEmpty) const Text('Aucun dépôt annoncé.', style: TextStyle(color: AppColors.muted)),
          for (final o in expected)
            _LotTile(
              order: o,
              onTap: () {
                state.declareDeposit(o);
                toast(context, 'Lot ${o.shortId} réceptionné');
              },
              actionLabel: 'Réceptionner',
            ),
        ],
      ),
    );
  }
}

class _LotTile extends StatelessWidget {
  const _LotTile({required this.order, required this.onTap, this.actionLabel = 'Contrôler'});

  final Order order;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ProductThumb(order.product, size: 44, flash: order.isFlash),
        title: Text('${order.shortId} · ${qty(order.quantity)} ${order.product.unit} ${order.product.name.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        subtitle: Text('De ${order.producer.displayName}, pour ${order.buyer.displayName}'),
        trailing: FilledButton.tonal(onPressed: onTap, style: FilledButton.styleFrom(minimumSize: const Size(0, 40)), child: Text(actionLabel)),
      ),
    );
  }
}

/// Fiche de contrôle : pesée, grade, conformité, photo et QR code.
class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key, required this.order});

  final Order order;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late final TextEditingController _weight;
  final _note = TextEditingController();
  Grade _grade = Grade.a;
  bool _conforme = true;
  int _photos = 1;
  final _checks = <String, bool>{
    'Aspect et couleur conformes': true,
    'Pas de moisissure ni pourriture': true,
    'Humidité acceptable': true,
    'Emballage correct': true,
  };

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: qty(widget.order.quantity).replaceAll(' ', ''));
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final w = parseNum(_weight.text);
    if (w == null || w <= 0) {
      toast(context, 'Indiquez le poids mesuré');
      return;
    }
    AppScope.read(context).recordControl(widget.order, weightKg: w, grade: _grade, conforme: _conforme, note: _note.text.trim());
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_conforme ? 'Lot validé' : 'Lot refusé', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (_conforme) ...[
                TraceCode(widget.order.qrCode ?? widget.order.id, size: 160),
                const SizedBox(height: 8),
                Text(widget.order.qrCode ?? '', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                const Text('Imprimez l’étiquette et collez-la sur le lot. Le transporteur la scanne à l’enlèvement.', textAlign: TextAlign.center),
              ] else
                const Text('Le transformateur est remboursé automatiquement et le producteur est prévenu.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Terminer')),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final announced = o.quantity;
    final measured = parseNum(_weight.text) ?? 0;
    final gap = announced == 0 ? 0 : ((measured - announced) / announced * 100);
    return Scaffold(
      appBar: AppBar(title: Text('Contrôle ${o.shortId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: ProductThumb(o.product, size: 48),
              title: Text(o.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Annoncé : ${qty(announced)} ${o.product.unit} · ${o.producer.displayName}'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Poids mesuré',
              suffixText: 'kg',
              prefixIcon: const Icon(Icons.scale),
              helperText: measured > 0 ? 'Écart : ${gap >= 0 ? '+' : ''}${gap.toStringAsFixed(1).replaceAll('.', ',')} %' : null,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Grade attribué', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<Grade>(
            segments: [for (final g in Grade.values) ButtonSegment(value: g, label: Text('Grade ${g.code}'))],
            selected: {_grade},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _grade = s.first),
          ),
          const SizedBox(height: 6),
          Text(_grade.label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 16),
          const Text('Points de contrôle', style: TextStyle(fontWeight: FontWeight.w700)),
          for (final e in _checks.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: e.value,
              title: Text(e.key),
              onChanged: (v) => setState(() {
                _checks[e.key] = v ?? false;
                _conforme = _checks.values.every((x) => x);
              }),
            ),
          const SizedBox(height: 8),
          PhotoPicker(count: _photos, onAdd: () => setState(() => _photos = (_photos + 1).clamp(0, 4)), onRemove: () => setState(() => _photos = (_photos - 1).clamp(0, 4))),
          const SizedBox(height: 16),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Observation (facultatif)')),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_conforme ? 'Lot conforme' : 'Lot non conforme', style: TextStyle(fontWeight: FontWeight.w800, color: _conforme ? AppColors.green : AppColors.red)),
            subtitle: Text(_conforme ? 'Le lot part en livraison' : 'L’acheteur sera remboursé'),
            value: _conforme,
            onChanged: (v) => setState(() => _conforme = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _conforme ? AppColors.green : AppColors.red),
            onPressed: _save,
            icon: Icon(_conforme ? Icons.qr_code_2 : Icons.block),
            label: Text(_conforme ? 'Valider et générer le QR code' : 'Refuser le lot'),
          ),
        ],
      ),
    );
  }
}

class AgentHistoryScreen extends StatelessWidget {
  const AgentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lots = AppScope.of(context).controlledLots;
    return Scaffold(
      appBar: AppBar(title: const Text('Lots contrôlés')),
      body: lots.isEmpty
          ? const EmptyState(icon: Icons.fact_check_outlined, title: 'Aucun contrôle', message: 'Les lots que vous contrôlez apparaîtront ici.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final o = lots[i];
                return Card(
                  child: ListTile(
                    leading: TraceCode(o.qrCode ?? o.id, size: 44),
                    title: Text('${o.shortId} · ${o.product.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${qty(o.weighedKg ?? o.quantity)} kg · ${o.producer.displayName}'),
                    trailing: GradeBadge(o.grade!),
                  ),
                );
              },
            ),
    );
  }
}
