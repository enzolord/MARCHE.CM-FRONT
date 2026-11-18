import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'phone_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.icon, this.color, this.title, this.text);
  final IconData icon;
  final Color color;
  final String title;
  final String text;
}

const _slides = [
  _Slide(Icons.handshake_rounded, AppColors.green, 'Vendez et achetez sans intermédiaire',
      'Les producteurs publient leurs récoltes, les transformateurs trouvent la bonne quantité, au bon prix, près de chez eux.'),
  _Slide(Icons.lock_rounded, AppColors.blue, 'Un paiement qui protège les deux',
      'Le transformateur paie par Mobile Money. L’argent reste bloqué jusqu’à la livraison, puis il est versé au producteur.'),
  _Slide(Icons.bolt_rounded, AppColors.flash, 'Ventes Flash : zéro gaspillage',
      'Un lot trop mûr ? Vendez-le vite à prix dégressif aux transformateurs les plus proches.'),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const PhoneScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const BrandLogoSmall(),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const PhoneScreen())),
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(s.icon, size: 96, color: s.color),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 14),
                        Text(s.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.muted, height: 1.45)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.green : AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == _slides.length - 1 ? 'Commencer' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandLogoSmall extends StatelessWidget {
  const BrandLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.storefront_rounded, color: AppColors.green),
        SizedBox(width: 6),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'MARCHE', style: TextStyle(color: AppColors.green)),
            TextSpan(text: '.CM', style: TextStyle(color: AppColors.gold)),
          ]),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
