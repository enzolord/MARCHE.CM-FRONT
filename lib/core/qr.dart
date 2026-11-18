import 'package:material_ui/material_ui.dart';

/// Représentation visuelle d'un code QR de traçabilité (démo).
/// En production, utiliser un vrai encodeur QR (paquet qr_flutter).
class TraceCode extends StatelessWidget {
  const TraceCode(this.data, {super.key, this.size = 120});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CodePainter(data)),
      );
}

class _CodePainter extends CustomPainter {
  _CodePainter(this.data);

  final String data;
  static const n = 25;

  bool _finder(int r, int c) {
    bool inBox(int r0, int c0) => r >= r0 && r < r0 + 7 && c >= c0 && c < c0 + 7;
    return inBox(0, 0) || inBox(0, n - 7) || inBox(n - 7, 0);
  }

  bool _finderOn(int r, int c) {
    var rr = r, cc = c;
    if (cc >= n - 7) cc -= n - 7;
    if (rr >= n - 7) rr -= n - 7;
    final ring = rr == 0 || rr == 6 || cc == 0 || cc == 6;
    final core = rr >= 2 && rr <= 4 && cc >= 2 && cc <= 4;
    return ring || core;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    var seed = 0;
    for (final u in data.codeUnits) {
      seed = (seed * 31 + u) & 0x7fffffff;
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        bool on;
        if (_finder(r, c)) {
          on = _finderOn(r, c);
        } else {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          on = (seed >> 16) % 2 == 0;
        }
        if (on) canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell + 0.3, cell + 0.3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CodePainter old) => old.data != data;
}
