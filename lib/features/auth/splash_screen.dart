import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, _, _) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.green,
      body: Center(child: BrandLogo(light: true, size: 1.4)),
    );
  }
}

/// Logo texte de MARCHE.CM.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.light = false, this.size = 1});

  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.green;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72 * size,
          height: 72 * size,
          decoration: BoxDecoration(
            color: light ? Colors.white : AppColors.green,
            borderRadius: BorderRadius.circular(22 * size),
          ),
          child: Icon(Icons.storefront_rounded, size: 42 * size, color: light ? AppColors.green : Colors.white),
        ),
        SizedBox(height: 14 * size),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'MARCHE', style: TextStyle(color: fg)),
            const TextSpan(text: '.CM', style: TextStyle(color: AppColors.gold)),
          ]),
          style: TextStyle(fontSize: 30 * size, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        SizedBox(height: 4 * size),
        Text(
          'Du champ à l’usine, en confiance',
          style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 14 * size),
        ),
      ],
    );
  }
}
