enum AdFormat { banner, interstitial, rewarded }

/// The outcome of asking an ad to show.
enum AdShowResult {
  /// The ad was shown and closed.
  shown,

  /// A rewarded ad was watched to the end.
  rewardEarned,

  /// Nothing was shown: not loaded, not allowed, or it failed. Never an
  /// error for the player.
  unavailable,
}

/// Ad loading and showing. The adapter (platform/ad_service.dart) only does
/// what the gate in `AdState` and the pacing rules in the ad provider allow;
/// this port never decides policy.
abstract interface class AdsPort {
  /// Starts the SDK. Called only after consent says ads may be requested.
  Future<void> initialize();

  /// Starts loading an ad of [format]. Returns true when one is ready.
  Future<bool> load(AdFormat format);

  bool isReady(AdFormat format);

  /// Shows a loaded interstitial or rewarded ad.
  Future<AdShowResult> show(AdFormat format);

  /// Height in logical pixels of the adaptive banner for [width], or 0 when
  /// none is loaded.
  Future<double> bannerHeight(double width);
}
