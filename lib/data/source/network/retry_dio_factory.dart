import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';

/// Builds a [Dio] whose error path auto-retries transient failures with
/// exponential backoff + jitter, and publishes a single "reconnecting…" signal
/// that the UI can subscribe to.
///
/// Designed for two failure shapes:
///   * No internet (airplane mode, DNS, socket reset) → [DioExceptionType.connectionError].
///   * Flaky link / 30% drop simulation → connection/receive timeouts and 5xx.
///
/// The banner stream is *reference-counted*: if 3 calls retry at once, we still
/// emit a single `true` until all of them complete (no flashing).
class RetryDioFactory {
  RetryDioFactory._();

  /// Max number of retry attempts per request (4 attempts total = 1 initial + 3 retries).
  static const int _maxRetries = 3;

  /// Base backoff. Effective delays: ~500ms, ~1s, ~2s (+ up to 250ms jitter).
  static const Duration _baseDelay = Duration(milliseconds: 500);

  static final StreamController<bool> _retryingController =
      StreamController<bool>.broadcast();
  static int _activeRetries = 0;

  /// Emits `true` while any request is currently waiting between retries,
  /// `false` once all retries have either succeeded or terminally failed.
  static Stream<bool> get retryingStream => _retryingController.stream;

  /// Whether at least one request is currently in its retry-backoff window.
  static bool get isRetrying => _activeRetries > 0;

  static void _enterRetry() {
    _activeRetries += 1;
    if (_activeRetries == 1) {
      _retryingController.add(true);
    }
  }

  static void _exitRetry() {
    if (_activeRetries == 0) return;
    _activeRetries -= 1;
    if (_activeRetries == 0) {
      _retryingController.add(false);
    }
  }

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          final retries = (requestOptions.extra['retries'] as int?) ?? 0;
          final statusCode = error.response?.statusCode;
          final isRetriable = error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              (statusCode != null && statusCode >= 500) ||
              statusCode == 408 ||
              statusCode == 429;

          if (!isRetriable || retries >= _maxRetries) {
            return handler.next(error);
          }

          requestOptions.extra['retries'] = retries + 1;
          final attempt = retries + 1;
          final baseMs =
              _baseDelay.inMilliseconds * pow(2, retries).toInt();
          final jitterMs = Random().nextInt(250);
          final delay = Duration(milliseconds: baseMs + jitterMs);

          developer.log(
            'Retrying ${requestOptions.method} ${requestOptions.uri} '
            '(attempt $attempt/$_maxRetries) in ${delay.inMilliseconds}ms '
            'due to ${error.type}${statusCode != null ? ' [$statusCode]' : ''}',
            name: 'RetryDioFactory',
          );

          _enterRetry();
          try {
            await Future.delayed(delay);
          } finally {
            _exitRetry();
          }

          try {
            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );

    return dio;
  }
}
