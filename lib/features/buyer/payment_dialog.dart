import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

/// Simule le paiement Mobile Money : demande envoyée, validation par code PIN
/// sur le téléphone, puis confirmation (callback de l'agrégateur).
Future<bool> payWithMobileMoney(BuildContext context, {required int amount, required MobileMoney operator, required String phone}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PaymentDialog(amount: amount, operator: operator, phone: phone),
  );
  return ok ?? false;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.amount, required this.operator, required this.phone});

  final int amount;
  final MobileMoney operator;
  final String phone;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  int _step = 0; // 0 envoi, 1 attente PIN, 2 succès
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _timers
      ..add(Timer(const Duration(milliseconds: 1200), () => _go(1)))
      ..add(Timer(const Duration(milliseconds: 3600), () => _go(2)));
  }

  void _go(int step) {
    if (mounted) setState(() => _step = step);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _step == 2;
    return AlertDialog(
      icon: done
          ? const Icon(Icons.check_circle, color: AppColors.green, size: 56)
          : Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: widget.operator.color, borderRadius: BorderRadius.circular(14)),
              child: Text(
                widget.operator == MobileMoney.mtn ? 'MTN' : 'OM',
                style: TextStyle(fontWeight: FontWeight.w900, color: widget.operator == MobileMoney.mtn ? AppColors.ink : Colors.white),
              ),
            ),
      title: Text(done ? 'Paiement reçu' : fcfa(widget.amount), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            switch (_step) {
              0 => 'Envoi de la demande de paiement à ${widget.operator.label}…',
              1 => 'Validez le paiement en composant votre code PIN sur le téléphone ${prettyPhone(widget.phone)}.',
              _ => 'L’argent est bloqué en séquestre. Il ne sera versé au producteur qu’après la livraison.',
            },
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
          if (!done) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        if (!done)
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler'))
        else
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Voir ma commande'),
          ),
      ],
    );
  }
}
