import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import 'role_screen.dart';
import 'splash_screen.dart';

/// Connexion par numéro de téléphone (pas de mot de passe).
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phone = TextEditingController();
  bool _accepted = true;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _valid => RegExp(r'^6\d{8}$').hasMatch(_phone.text.replaceAll(' ', ''));

  void _submit() {
    if (!_valid || !_accepted) return;
    AppScope.read(context).requestOtp(_phone.text);
    go<void>(context, const OtpScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const BrandLogo(),
            const SizedBox(height: 40),
            const Text('Votre numéro de téléphone', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Nous vous envoyons un code par SMS. Pas de mot de passe à retenir.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            TextField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              style: const TextStyle(fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.w600),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('🇨🇲 +237', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '6XX XX XX XX',
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('J’accepte les conditions d’utilisation et la charte de confiance MARCHE.CM', style: TextStyle(fontSize: 13.5)),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _valid && _accepted ? _submit : null, child: const Text('Recevoir le code')),
            const SizedBox(height: 24),
            const InfoBanner(
              icon: Icons.sms_outlined,
              text: 'Pas de smartphone ? Composez *237*7# pour publier une offre par USSD.',
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 60;
  int _tries = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    final state = AppScope.read(context);
    if (state.verifyOtp(_code.text)) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const RoleScreen()));
      return;
    }
    setState(() {
      _tries++;
      _error = _tries >= 3 ? 'Trop d’essais. Demandez un nouveau code.' : 'Code incorrect (${3 - _tries} essai(s) restant(s)).';
      _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = AppScope.of(context).pendingPhone;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Code de vérification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Saisissez le code à 6 chiffres envoyé au ${prettyPhone(phone)}.', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 28),
            TextField(
              controller: _code,
              autofocus: true,
              enabled: _tries < 3,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: const TextStyle(fontSize: 30, letterSpacing: 14, fontWeight: FontWeight.w800),
              decoration: InputDecoration(hintText: '••••••', errorText: _error),
              onChanged: (v) {
                setState(() => _error = null);
                if (v.length == 6) _verify();
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: _seconds > 0
                  ? Text('Renvoyer le code dans $_seconds s', style: const TextStyle(color: AppColors.muted))
                  : TextButton(
                      onPressed: () => setState(() {
                        _tries = 0;
                        _error = null;
                        _start();
                        toast(context, 'Nouveau code envoyé par SMS');
                      }),
                      child: const Text('Renvoyer le code'),
                    ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _code.text.length == 6 && _tries < 3 ? _verify : null, child: const Text('Valider')),
            const SizedBox(height: 24),
            const InfoBanner(icon: Icons.info_outline, text: 'Version de démonstration : saisissez n’importe quel code à 6 chiffres, par exemple 123456.'),
          ],
        ),
      ),
    );
  }
}
