import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

/// Espace transporteur : missions proposées, en cours et terminées.
class TransporterHome extends StatefulWidget {
  const TransporterHome({super.key});

  @override
  State<TransporterHome> createState() => _TransporterHomeState();
}

class _TransporterHomeState extends State<TransporterHome> {
  bool _available = true;
  bool _refrigerated = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final missions = state.missions;
    final proposed = missions.where((m) => m.status == MissionStatus.proposee).toList();
    final current = missions.where((m) => m.status == MissionStatus.acceptee || m.status == MissionStatus.enCours).toList();
    final done = missions.where((m) => m.status == MissionStatus.terminee).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missions'),
          actions: const [TopActions()],
          bottom: TabBar(tabs: [
            Tab(text: 'Proposées (${proposed.length})'),
            Tab(text: 'En cours (${current.length})'),
            Tab(text: 'Terminées'),
          ]),
        ),
        body: Column(
          children: [
            Material(
              color: Colors.white,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.circle, size: 14, color: _available ? AppColors.green : AppColors.muted),
                    title: Text(_available ? 'Disponible pour des missions' : 'Indisponible'),
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.ac_unit),
                    title: const Text('Véhicule réfrigéré'),
                    value: _refrigerated,
                    onChanged: (v) => setState(() => _refrigerated = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(context, _available ? proposed : const [], 'Aucune mission proposée', _available ? 'Les missions près de vous apparaîtront ici.' : 'Passez en « disponible » pour recevoir des missions.'),
                  _list(context, current, 'Aucune mission en cours', 'Acceptez une mission proposée.'),
                  _list(context, done, 'Aucune mission terminée', 'Votre historique apparaîtra ici.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Mission> list, String title, String message) {
    if (list.isEmpty) return EmptyState(icon: Icons.local_shipping_outlined, title: title, message: message);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _MissionCard(mission: list[i]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final m = mission;
    final o = m.order;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductThumb(o.product, size: 40, flash: o.isFlash),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${qty(o.weighedKg ?? o.quantity)} ${o.product.unit} · ${o.product.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(fcfa(m.fee), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            _Stop(icon: Icons.radio_button_checked, color: AppColors.green, label: 'Enlèvement', place: m.pickup),
            Padding(
              padding: const EdgeInsets.only(left: 9),
              child: Container(width: 2, height: 16, color: AppColors.line),
            ),
            _Stop(icon: Icons.place, color: AppColors.red, label: 'Livraison', place: m.dropoff),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              Pill('${qty(m.distanceKm)} km', color: AppColors.muted, icon: Icons.route),
              Pill(dateTime(m.when), color: AppColors.blue, icon: Icons.schedule),
              if (o.isFlash) const Pill('Express', color: AppColors.flash, icon: Icons.bolt),
              if (m.refrigerated) const Pill('Froid', color: AppColors.blue, icon: Icons.ac_unit),
              Pill(m.status.label, color: m.status.color),
            ]),
            if (m.status != MissionStatus.terminee) ...[
              const SizedBox(height: 12),
              switch (m.status) {
                MissionStatus.proposee => FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: () {
                      state.acceptMission(m);
                      toast(context, 'Mission acceptée');
                    },
                    child: const Text('Accepter la mission'),
                  ),
                MissionStatus.acceptee => FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: () => state.startMission(m),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scanner le lot et démarrer'),
                  ),
                _ => FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44), backgroundColor: AppColors.flash),
                    onPressed: () async {
                      if (await confirm(context, title: 'Livraison effectuée ?', message: 'Le transformateur sera invité à confirmer la réception.', ok: 'Oui, livré')) {
                        state.finishMission(m);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Marquer comme livré'),
                  ),
              },
            ],
          ],
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.color, required this.label, required this.place});

  final IconData icon;
  final Color color;
  final String label;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label : ', style: const TextStyle(color: AppColors.muted)),
            TextSpan(text: place, style: const TextStyle(fontWeight: FontWeight.w600)),
          ])),
        ),
      ],
    );
  }
}
