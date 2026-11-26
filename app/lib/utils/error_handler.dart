import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

/// Receives every error the handler sees. The real implementation (batch
/// p2e) writes to the local log; tests pass a recording function.
typedef ErrorReporter = void Function(
  Object error,
  StackTrace? stack, {
  required bool fatal,
});

/// An unexpected error that should replace the screen with the fallback view.
@immutable
class FatalError {
  const FatalError(this.error, this.stack);

  final Object error;
  final StackTrace? stack;
}

/// The global error handler (blueprint section 4, error taxonomy).
///
/// - Errors thrown while building a widget (the widgets library) and errors
///   that escape every other handler (uncaught asynchronous errors) are
///   reported as fatal and published on [fatal], so the app root can show
///   the full-screen fallback with a Retry button and an email-the-log link.
///
/// Nothing here shows UI itself; the app root listens to [fatal].
class AppErrorHandler {
  AppErrorHandler(this._reporter);

  final ErrorReporter _reporter;

  /// The most recent fatal error, or null when the app is healthy.
  final ValueNotifier<FatalError?> fatal = ValueNotifier<FatalError?>(null);

  /// Takes over the framework and platform error hooks. Call once, from main,
  /// before the app starts.
  void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      // A widget that fails to build leaves a blank spot with no way out, so
      // it takes the player to the fallback view (Retry returns to Home).
      report(details.exception, details.stack, fatal: details.library == 'widgets library');
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report(error, stack, fatal: true);
      return true;
    };
  }

  /// Records an error. A fatal one also switches the app to the fallback view.
  void report(Object error, StackTrace? stack, {bool fatal = false}) {
    try {
      _reporter(error, stack, fatal: fatal);
    } catch (_) {
      // Reporting must never throw: it would hide the original error.
    }
    if (fatal) {
      this.fatal.value = FatalError(error, stack);
    }
  }

  /// Returns the app to normal after the player taps Retry.
  void clear() {
    fatal.value = null;
  }
}
