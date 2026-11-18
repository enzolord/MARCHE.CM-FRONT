import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../producer/offer_form_screen.dart';

/// Ouverture d'un litige après livraison.
class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key, required this.order});

  final Order order;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  static const _reasons = ['Quantité manquante', 'Qualité non conforme', 'Produit abîmé', 'Retard de livraison', 'Autre'];
  String? _reason;
  final _details = TextEditingController();
  int _photos = 0;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = AppScope.read(context);
    final text = _details.text.trim();
    state.openDispute(widget.order, text.isEmpty ? _reason! : '$_reason — $text');
    await showSuccess(
      context,
      icon: Icons.gavel,
      color: AppColors.red,
      title: 'Litige enregistré',
      message: 'Les fonds restent bloqués. Un administrateur examine le contrôle qualité, vos photos et la réponse du producteur, puis décide sous 48 h.',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un problème')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoBanner(
            icon: Icons.lock_clock,
            text: 'Commande ${widget.order.shortId} : le paiement reste gelé pendant l’examen du litige. Vous n’avez pas à négocier directement avec le producteur.',
          ),
          const SizedBox(height: 20),
          const Text('Quel est le problème ?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _reasons) ChoiceChip(label: Text(r), selected: _reason == r, onSelected: (_) => setState(() => _reason = r)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _details,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Décrivez ce que vous avez constaté', alignLabelWithHint: true),
          ),
          const SizedBox(height: 20),
          const Text('Photos (fortement recommandé)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          PhotoPicker(count: _photos, onAdd: () => setState(() => _photos = (_photos + 1).clamp(0, 4)), onRemove: () => setState(() => _photos = (_photos - 1).clamp(0, 4))),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: _reason == null ? null : _submit,
            child: const Text('Ouvrir le litige'),
          ),
        ],
      ),
    );
  }
}
