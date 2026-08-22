import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _env(String key) {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env[key];
  }

  /// The backend API base URL, loaded from the active .env file.
  /// Falls back to a safe localhost URL if the variable is not set.
  static String get baseUrl =>
      _env('API_BASE_URL') ?? 'http://10.0.2.2:8000/api/v1';

  /// The current app environment ("development" or "production").
  static String get appEnv => _env('APP_ENV') ?? 'development';

  /// Whether the app is running in production mode.
  static bool get isProduction => appEnv == 'production';

  /// Whether verbose debug logging is enabled.
  static bool get debugEnabled =>
      (_env('APP_DEBUG') ?? 'true').toLowerCase() == 'true';

  /// App display name (e.g. "Mfumo wa Bei" or "Mfumo wa Bei (Dev)").
  static String get appName => _env('APP_NAME') ?? 'Mfumo wa Bei';
}
