import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_state.dart';
import 'data/models.dart';

/// Sur le web, un lien comme `?role=transformateur&onglet=2` ouvre
/// directement un espace (pratique pour les démonstrations).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  final params = Uri.base.queryParameters;
  Role? role;
  for (final r in Role.values) {
    if (r.name == params['role']) role = r;
  }
  if (role != null) state.chooseRole(role);
  runApp(MarcheApp(state: state, startTab: role == null ? null : int.tryParse(params['onglet'] ?? '') ?? 0));
}
