import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MarcheApp(state: AppState()));
}
