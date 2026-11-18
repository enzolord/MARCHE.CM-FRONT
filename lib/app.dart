import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'data/app_state.dart';
import 'features/auth/splash_screen.dart';
import 'features/shell/home_shell.dart';

class MarcheApp extends StatelessWidget {
  const MarcheApp({super.key, required this.state, this.startTab});

  final AppState state;

  /// Si renseigné, l'application s'ouvre directement sur cet onglet.
  final int? startTab;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'MARCHE.CM',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('fr', 'CM'),
        supportedLocales: const [Locale('fr', 'CM'), Locale('fr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: startTab == null ? const SplashScreen() : HomeShell(initialIndex: startTab!),
      ),
    );
  }
}
