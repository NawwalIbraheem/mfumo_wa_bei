import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

/// DEVELOPMENT entry point.
/// Run with: flutter run -t lib/main_dev.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.dev');
  runApp(const MfumoWaBeiApp());
}
