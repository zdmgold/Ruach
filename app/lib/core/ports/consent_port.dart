import 'package:ruach/core/models/ad_state.dart';

/// What the consent platform reports after a refresh.
final class ConsentSnapshot {
  const ConsentSnapshot({
    required this.status,
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  final ConsentStatus status;
  final bool canRequestAds;
  final bool privacyOptionsRequired;
}

/// Google's User Messaging Platform (blueprint section 7). The adapter is in
/// platform/consent_service.dart.
abstract interface class ConsentPort {
  /// Refreshes consent state. A failed or offline refresh returns the last
  /// stored values rather than resetting them.
  Future<ConsentSnapshot> refresh();

  /// Shows the consent form if the region requires it and it is available.
  /// Returns the state afterwards.
  Future<ConsentSnapshot> showFormIfRequired();

  /// Shows the Privacy choices form. Returns the state afterwards.
  Future<ConsentSnapshot> showPrivacyOptions();
}
