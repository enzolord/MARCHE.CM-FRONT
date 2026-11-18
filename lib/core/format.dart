/// Petites fonctions de mise en forme (montants en FCFA, dates en français).
library;

const _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// 12500 -> "12 500"
String groupThousands(num value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/// 12500 -> "12 500 FCFA"
String fcfa(num value) => '${groupThousands(value)} FCFA';

/// 2.5 -> "2,5" ; 3.0 -> "3"
String qty(num value) {
  if (value == value.roundToDouble()) return groupThousands(value);
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String longDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String time(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String dateTime(DateTime d) => '${shortDate(d)} à ${time(d)}';

/// Durée restante lisible : "2 j 4 h", "5 h 12 min", "8 min".
String remaining(Duration d) {
  if (d.isNegative || d == Duration.zero) return 'terminé';
  if (d.inDays > 0) return '${d.inDays} j ${d.inHours % 24} h';
  if (d.inHours > 0) return '${d.inHours} h ${(d.inMinutes % 60).toString().padLeft(2, '0')} min';
  if (d.inMinutes > 0) return '${d.inMinutes} min';
  return '${d.inSeconds} s';
}

/// "il y a 5 min", "il y a 3 h", "hier", "12 nov."
String ago(DateTime d, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return shortDate(d);
}

/// Masque un numéro : 677123456 -> "6•• ••• •56"
String maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '•••';
  return '${digits[0]}•• ••• •${digits.substring(digits.length - 2)}';
}

/// Formatte un numéro camerounais : 677123456 -> "+237 6 77 12 34 56"
String prettyPhone(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length != 9) return phone;
  return '+237 ${d[0]} ${d.substring(1, 3)} ${d.substring(3, 5)} ${d.substring(5, 7)} ${d.substring(7)}';
}
