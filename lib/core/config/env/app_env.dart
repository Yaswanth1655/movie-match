import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  /// Reqres user API (`/users`). Sent as `x-api-key` on every request.
  /// Prefer `.env` `REQRES_API_KEY=`; fallback: `--dart-define=REQRES_API_KEY=...`.
  static String get reqresApiKey =>
      _envOrDefine('REQRES_API_KEY', const String.fromEnvironment('REQRES_API_KEY'));

  static String get tmdbApiKey =>
      _envOrDefine('TMDB_API_KEY', const String.fromEnvironment('TMDB_API_KEY'));

  static String get omdbApiKey =>
      _envOrDefine('OMDB_API_KEY', const String.fromEnvironment('OMDB_API_KEY'));

  static String _envOrDefine(String key, String fromDefine) {
    final raw = dotenv.env[key];
    final trimmed = raw?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return fromDefine.trim();
  }

  static const reqresBaseUrl = 'https://reqres.in/api';
  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const omdbBaseUrl = 'https://www.omdbapi.com';
}
