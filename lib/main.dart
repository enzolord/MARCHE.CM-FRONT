import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MarcheApp(state: AppState()));
}
