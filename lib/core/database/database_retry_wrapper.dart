import 'dart:async';
import 'dart:math';

class DatabaseRetryWrapper {
  DatabaseRetryWrapper._();

  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          rethrow;
        }
        
        final delayMs =
            (initialDelay.inMilliseconds * pow(2, attempts - 1)).round();
        final jitter = Random().nextInt(50);
        await Future.delayed(Duration(milliseconds:  delayMs + jitter));
      }
    }
  }

  static Stream<T> retryStream<T>({
    required Stream<T> Function() streamFactory,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    int attempts = 0;

    void startListening() {
      subscription = streamFactory().listen(
        (data) {
          controller?.add(data);
          attempts = 0;
        },
        onError: (error) {
          attempts++;
          if (attempts < maxAttempts) {
            subscription?.cancel();
            Future.delayed(retryDelay, () {
              if (controller?.isClosed == false) {
                startListening();
              }
            });
          } else {
            controller?.addError(error);
          }
        },
        onDone: () {
          controller?.close();
        },
      );
    }

    controller = StreamController<T>(
      onListen: startListening,
      onCancel: () {
        subscription?.cancel();
      },
      onPause: () {
        subscription?.pause();
      },
      onResume: () {
        subscription?.resume();
      },
    );

    return controller.stream;
  }
}
