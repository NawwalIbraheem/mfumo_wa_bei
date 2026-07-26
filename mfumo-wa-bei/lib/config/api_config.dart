import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  /// The backend API base URL, loaded from the active .env file.
  /// Falls back to a safe localhost URL if the variable is not set.
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';

  /// The current app environment ("development" or "production").
  static String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'development';

  /// Whether the app is running in production mode.
  static bool get isProduction => appEnv == 'production';

  /// Whether verbose debug logging is enabled.
  static bool get debugEnabled =>
      (dotenv.env['APP_DEBUG'] ?? 'true').toLowerCase() == 'true';

  /// App display name (e.g. "Mfumo wa Bei" or "Mfumo wa Bei (Dev)").
  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'Mfumo wa Bei';
}
