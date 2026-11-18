import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marche_cm/app.dart';
import 'package:marche_cm/core/theme.dart';
import 'package:marche_cm/data/app_state.dart';
import 'package:marche_cm/data/models.dart';
import 'package:marche_cm/features/shell/home_shell.dart';

Widget _shell(AppState state) => AppScope(
      state: state,
      child: MaterialApp(theme: buildTheme(), home: const HomeShell()),
    );

void main() {
  testWidgets('le démarrage mène à la présentation', (tester) async {
    await tester.pumpWidget(MarcheApp(state: AppState()));
    expect(find.textContaining('MARCHE'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('espace producteur', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final state = AppState()..chooseRole(Role.producteur);
    await tester.pumpWidget(_shell(state));
    await tester.pump();
    expect(find.textContaining('Bonjour'), findsOneWidget);
    expect(find.text('Offres'), findsWidgets);
    await tester.tap(find.text('Offres').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Publier'), findsOneWidget);
  });

  testWidgets('espace transformateur', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final state = AppState()..chooseRole(Role.transformateur);
    await tester.pumpWidget(_shell(state));
    await tester.pump();
    expect(find.text('Marché'), findsWidgets);
    expect(find.text('Flash'), findsOneWidget);
  });

  testWidgets('espaces transporteur et agent', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final state = AppState()..chooseRole(Role.transporteur);
    await tester.pumpWidget(_shell(state));
    await tester.pump();
    expect(find.text('Missions'), findsWidgets);
    state.switchRole(Role.agent);
    await tester.pump();
    expect(find.text('Point de collecte'), findsOneWidget);
  });
}
