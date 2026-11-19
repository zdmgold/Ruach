/// The error classes from the blueprint's taxonomy (section 4). Every failure
/// the app handles is one of these, so each has one defined treatment.
///
/// The [detail] text is for the local log only and is in English. What the
/// player reads comes from the language files, chosen by the error's type.
sealed class AppError {
  const AppError(this.detail, {this.cause});

  /// A short technical description for the local log.
  final String detail;

  /// The underlying exception, if any.
  final Object? cause;

  /// True when the player is offered a Retry button.
  bool get offersRetry;

  /// True when the error replaces the whole screen. Only unexpected failures
  /// do; everything else leaves the game usable.
  bool get blocksScreen => false;

  @override
  String toString() => '$runtimeType: $detail';
}

/// Recoverable, caused by the player: a download declined, no connection.
/// Shown inline with Retry; the game is unaffected.
final class UserActionError extends AppError {
  const UserActionError(super.detail, {super.cause});

  @override
  bool get offersRetry => true;
}

/// Recoverable, caused by the system: a hash mismatch or an interrupted
/// download. The partial file is discarded and the step retried once
/// automatically before Retry is shown.
final class SystemError extends AppError {
  const SystemError(super.detail, {super.cause});

  @override
  bool get offersRetry => true;
}

/// Degraded because a third party failed: the ad SDK, the consent form or
/// billing. The slot collapses, the failure is logged, no screen is blocked.
final class ThirdPartyError extends AppError {
  const ThirdPartyError(this.source, String detail, {super.cause})
      : super(detail);

  /// Which service failed, for example `ads` or `billing`.
  final String source;

  @override
  bool get offersRetry => false;
}

/// Degraded because a sensor is missing or unreadable. Controls fall back to
/// buttons with a one-line notice.
final class SensorError extends AppError {
  const SensorError(super.detail, {super.cause});

  @override
  bool get offersRetry => false;
}

/// Degraded because storage failed. The app keeps working in memory, shows a
/// warning banner and retries on the next change.
final class StorageError extends AppError {
  const StorageError(super.detail, {super.cause});

  @override
  bool get offersRetry => true;
}

/// An uncaught exception. The global handler shows a full-screen fallback with
/// Retry and an email-report link.
final class UnexpectedError extends AppError {
  const UnexpectedError(super.detail, {super.cause, this.stack});

  final StackTrace? stack;

  @override
  bool get offersRetry => true;

  @override
  bool get blocksScreen => true;
}
