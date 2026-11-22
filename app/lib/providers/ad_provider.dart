import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/ports/ads_port.dart';
import 'package:ruach/providers/consent_provider.dart';
import 'package:ruach/providers/flags_provider.dart';

/// Decides when an ad may show and asks the ad port to show it.
///
/// Rules (blueprint section 7): nothing before consent allows it; nothing
/// when the player owns Remove Ads (rewarded ads are the player's choice and
/// still work); nothing when the remote switch is off; no interstitial in the
/// player's first session, none within three minutes of the last, and none
/// after the first Daily Run attempt of a day.
final class AdProvider extends ChangeNotifier {
  AdProvider(
    this._ads,
    this._consent,
    this._flags, {
    required this.firstSession,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _consent.addListener(_onChange);
    _flags.addListener(_onChange);
  }

  /// Least time between two interstitials.
  static const Duration interstitialGap = Duration(minutes: 3);

  final AdsPort _ads;
  final ConsentProvider _consent;
  final FlagsProvider _flags;
  final DateTime Function() _clock;

  /// True when this is the first session after install.
  final bool firstSession;

  DateTime? _lastInterstitial;
  bool _initialized = false;
  bool _initializing = false;

  AdState get state => _consent.value;
  bool get _switchOn => _flags.value.adsEnabled;

  bool get bannersAllowed => _switchOn && state.canShowBanner;
  bool get rewardedAllowed => _switchOn && state.canShowRewarded;

  void _onChange() {
    if (state.canRequestAds && _switchOn) unawaited(initialize());
    notifyListeners();
  }

  /// Starts the ad network once consent allows requests.
  Future<void> initialize() async {
    if (_initialized || _initializing || !state.canRequestAds || !_switchOn) return;
    _initializing = true;
    try {
      await _ads.initialize();
      _initialized = true;
      await _ads.load(AdFormat.interstitial);
      await _ads.load(AdFormat.rewarded);
    } on Object {
      // Ads are optional; the game goes on without them.
    } finally {
      _initializing = false;
    }
  }

  /// Whether an interstitial may show now.
  bool interstitialAllowed({bool afterFirstDailyAttempt = false}) {
    if (!_initialized || !_switchOn || !state.canShowInterstitial) return false;
    if (firstSession || afterFirstDailyAttempt) return false;
    final DateTime? last = _lastInterstitial;
    if (last != null && _clock().difference(last) < interstitialGap) return false;
    return _ads.isReady(AdFormat.interstitial);
  }

  /// Shows an interstitial if the rules allow. True if it was shown.
  Future<bool> maybeShowInterstitial({bool afterFirstDailyAttempt = false}) async {
    if (!interstitialAllowed(afterFirstDailyAttempt: afterFirstDailyAttempt)) return false;
    _lastInterstitial = _clock();
    AdShowResult result = AdShowResult.unavailable;
    try {
      result = await _ads.show(AdFormat.interstitial);
    } on Object {
      // Treated as not shown.
    }
    await _reload(AdFormat.interstitial);
    return result != AdShowResult.unavailable;
  }

  bool get rewardedReady => _initialized && rewardedAllowed && _ads.isReady(AdFormat.rewarded);

  /// Shows a rewarded ad the player chose to watch. True only if the reward
  /// was earned.
  Future<bool> showRewarded() async {
    if (!rewardedReady) return false;
    AdShowResult result = AdShowResult.unavailable;
    try {
      result = await _ads.show(AdFormat.rewarded);
    } on Object {
      // Treated as not earned.
    }
    await _reload(AdFormat.rewarded);
    return result == AdShowResult.rewardEarned;
  }

  Future<void> _reload(AdFormat format) async {
    try {
      await _ads.load(format);
    } on Object {
      // The next show finds it not ready.
    }
  }

  @override
  void dispose() {
    _consent.removeListener(_onChange);
    _flags.removeListener(_onChange);
    super.dispose();
  }
}
