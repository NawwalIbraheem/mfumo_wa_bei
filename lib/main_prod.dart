import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

/// PRODUCTION entry point.
/// Build with: flutter build apk --release -t lib/main_prod.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MfumoWaBeiApp());
}
