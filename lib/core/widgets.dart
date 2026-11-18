import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import 'format.dart';
import 'theme.dart';

/// Vignette d'un produit (emoji sur fond coloré, en attendant les photos).
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.product, {super.key, this.size = 56, this.flash = false});

  final Product product;
  final double size;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: flash ? AppColors.flashLight : AppColors.greenLight,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Text(product.emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, this.radius = 20});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = switch (user.role) {
      Role.producteur || Role.cooperative => AppColors.green,
      Role.transformateur => AppColors.blue,
      Role.transporteur => AppColors.flash,
      Role.agent => AppColors.muted,
    };
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        user.initials,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: radius * 0.75),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color, this.icon, this.filled = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradeBadge extends StatelessWidget {
  const GradeBadge(this.grade, {super.key});

  final Grade grade;

  @override
  Widget build(BuildContext context) =>
      Pill('Grade ${grade.code}', color: grade.color, icon: Icons.workspace_premium);
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Identité vérifiée',
        child: Icon(Icons.verified, size: size, color: AppColors.blue),
      );
}

class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.reviews, this.size = 14});

  final double rating;
  final int? reviews;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.gold),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1).replaceAll('.', ','),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
        ),
        if (reviews != null)
          Text(' ($reviews)', style: TextStyle(fontSize: size, color: AppColors.muted)),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.greenLight,
              child: Icon(icon, size: 36, color: AppColors.green),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text, this.color = AppColors.blue, this.margin});

  final IconData icon;
  final String text;
  final Color color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

/// Bandeau affiché quand l'application est hors ligne.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.offline) return const SizedBox.shrink();
    return Material(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hors ligne — vos actions seront envoyées au retour du réseau',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => state.setOffline(false),
                child: const Text('Reconnecter', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, required this.value, required this.icon, this.color = AppColors.green, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 2, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reconstruit son contenu chaque seconde (comptes à rebours).
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder, this.period = const Duration(seconds: 1)});

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration period;

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.period, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

class AmountRow extends StatelessWidget {
  const AmountRow(this.label, this.value, {super.key, this.bold = false, this.color, this.hint});

  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style.copyWith(color: color ?? (bold ? AppColors.ink : AppColors.muted))),
                if (hint != null)
                  Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Petite courbe d'évolution des prix.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, this.color = AppColors.green, this.height = 36, this.width = 90});

  final List<int> values;
  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _SparkPainter(values, color)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce((a, b) => a < b ? a : b).toDouble();
    final hi = values.reduce((a, b) => a > b ? a : b).toDouble();
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - lo) / span * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}

/// Choix de l'opérateur Mobile Money.
class PaymentPicker extends StatelessWidget {
  const PaymentPicker({super.key, required this.value, required this.onChanged});

  final MobileMoney value;
  final ValueChanged<MobileMoney> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in MobileMoney.values) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: value == m ? AppColors.green : AppColors.line, width: value == m ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        m == MobileMoney.mtn ? 'MTN' : 'OM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: m == MobileMoney.mtn ? AppColors.ink : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    if (value == m) const Icon(Icons.check_circle, color: AppColors.green, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (m != MobileMoney.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

/// Feuille de confirmation après une action réussie.
Future<void> showSuccess(BuildContext context, {required String title, required String message, IconData icon = Icons.check_circle, Color color = AppColors.green}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris')),
          ],
        ),
      ),
    ),
  );
}

/// Demande une confirmation simple. Renvoie true si l'utilisateur accepte.
Future<bool> confirm(BuildContext context, {required String title, required String message, String ok = 'Confirmer', bool danger = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0, 44)) : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return result ?? false;
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Raccourci de navigation.
Future<T?> go<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Ligne « icône + texte » utilisée dans les fiches.
class IconLine extends StatelessWidget {
  const IconLine(this.icon, this.text, {super.key, this.color = AppColors.muted, this.size = 13.5});

  final IconData icon;
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: size + 3, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: size)),
        ),
      ],
    );
  }
}

/// Badge de compteur sur une icône (notifications, messages).
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.flash,
        child: child,
      );
}

/// Champ numérique avec suffixe d'unité.
class NumberField extends StatelessWidget {
  const NumberField({super.key, required this.controller, required this.label, this.suffix, this.hint, this.validator, this.onChanged});

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix, helperText: hint),
      validator: validator ?? (v) => (parseNum(v) ?? 0) <= 0 ? 'Valeur requise' : null,
      onChanged: onChanged,
    );
  }
}

double? parseNum(String? v) =>
    v == null ? null : double.tryParse(v.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'));

/// Prix courant d'un lot Flash, mis à jour en direct.
class FlashPrice extends StatelessWidget {
  const FlashPrice(this.lot, {super.key, this.big = false});

  final FlashLot lot;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Ticker(
      period: const Duration(seconds: 30),
      builder: (context, now) {
        final price = lot.priceAt(now);
        return Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '${groupThousands(price)} F',
              style: TextStyle(fontSize: big ? 28 : 18, fontWeight: FontWeight.w900, color: AppColors.flash),
            ),
            TextSpan(text: ' /${lot.product.unit}  ', style: const TextStyle(color: AppColors.muted)),
            if (price < lot.initialPrice)
              TextSpan(
                text: '${groupThousands(lot.initialPrice)} F',
                style: const TextStyle(color: AppColors.muted, decoration: TextDecoration.lineThrough),
              ),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: big ? TextAlign.center : TextAlign.start,
        );
      },
    );
  }
}
