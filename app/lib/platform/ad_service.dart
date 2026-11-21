import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:ruach/core/config/ad_units.dart';
import 'package:ruach/core/ports/ads_port.dart';

/// Loads and shows AdMob ads. This class never decides whether an ad may be
/// requested: callers check consent, the Remove Ads entitlement and the
/// pacing rules first (blueprint section 7). Every failure ends as
/// [AdShowResult.unavailable] or `false`; nothing here throws.
final class AdService implements AdsPort {
  AdService(this.units, {this.onError});

  final AdUnits units;
  final void Function(String message)? onError;

  bool _initialized = false;
  gma.InterstitialAd? _interstitial;
  gma.RewardedAd? _rewarded;
  gma.BannerAd? _banner;
  bool _bannerLoaded = false;

  /// The loaded banner, for the ad slot widget to draw, or null.
  gma.BannerAd? get banner => _bannerLoaded ? _banner : null;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await gma.MobileAds.instance.initialize();
      _initialized = true;
    } on Object catch (error) {
      onError?.call('ad SDK failed to start: $error');
    }
  }

  @override
  bool isReady(AdFormat format) => switch (format) {
        AdFormat.banner => _bannerLoaded,
        AdFormat.interstitial => _interstitial != null,
        AdFormat.rewarded => _rewarded != null,
      };

  @override
  Future<bool> load(AdFormat format) async {
    if (!_initialized) return false;
    switch (format) {
      case AdFormat.banner:
        return (await bannerHeight(320)) > 0;
      case AdFormat.interstitial:
        return _loadInterstitial();
      case AdFormat.rewarded:
        return _loadRewarded();
    }
  }

  Future<bool> _loadInterstitial() {
    final Completer<bool> done = Completer<bool>();
    try {
      gma.InterstitialAd.load(
        adUnitId: units.interstitial,
        request: const gma.AdRequest(),
        adLoadCallback: gma.InterstitialAdLoadCallback(
          onAdLoaded: (gma.InterstitialAd ad) {
            _interstitial?.dispose();
            _interstitial = ad;
            if (!done.isCompleted) done.complete(true);
          },
          onAdFailedToLoad: (gma.LoadAdError error) {
            onError?.call('interstitial failed to load: ${error.message}');
            if (!done.isCompleted) done.complete(false);
          },
        ),
      );
    } on Object catch (error) {
      onError?.call('interstitial failed to load: $error');
      if (!done.isCompleted) done.complete(false);
    }
    return done.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
  }

  Future<bool> _loadRewarded() {
    final Completer<bool> done = Completer<bool>();
    try {
      gma.RewardedAd.load(
        adUnitId: units.rewarded,
        request: const gma.AdRequest(),
        rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
          onAdLoaded: (gma.RewardedAd ad) {
            _rewarded?.dispose();
            _rewarded = ad;
            if (!done.isCompleted) done.complete(true);
          },
          onAdFailedToLoad: (gma.LoadAdError error) {
            onError?.call('rewarded ad failed to load: ${error.message}');
            if (!done.isCompleted) done.complete(false);
          },
        ),
      );
    } on Object catch (error) {
      onError?.call('rewarded ad failed to load: $error');
      if (!done.isCompleted) done.complete(false);
    }
    return done.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
  }

  @override
  Future<AdShowResult> show(AdFormat format) async {
    switch (format) {
      case AdFormat.banner:
        return _bannerLoaded ? AdShowResult.shown : AdShowResult.unavailable;
      case AdFormat.interstitial:
        return _showInterstitial();
      case AdFormat.rewarded:
        return _showRewarded();
    }
  }

  Future<AdShowResult> _showInterstitial() {
    final gma.InterstitialAd? ad = _interstitial;
    if (ad == null) return Future<AdShowResult>.value(AdShowResult.unavailable);
    _interstitial = null;
    final Completer<AdShowResult> done = Completer<AdShowResult>();
    ad.fullScreenContentCallback = gma.FullScreenContentCallback<gma.InterstitialAd>(
      onAdDismissedFullScreenContent: (gma.InterstitialAd shown) {
        shown.dispose();
        if (!done.isCompleted) done.complete(AdShowResult.shown);
      },
      onAdFailedToShowFullScreenContent: (gma.InterstitialAd failed, gma.AdError error) {
        onError?.call('interstitial failed to show: ${error.message}');
        failed.dispose();
        if (!done.isCompleted) done.complete(AdShowResult.unavailable);
      },
    );
    try {
      unawaited(ad.show());
    } on Object catch (error) {
      onError?.call('interstitial failed to show: $error');
      ad.dispose();
      if (!done.isCompleted) done.complete(AdShowResult.unavailable);
    }
    return done.future;
  }

  Future<AdShowResult> _showRewarded() {
    final gma.RewardedAd? ad = _rewarded;
    if (ad == null) return Future<AdShowResult>.value(AdShowResult.unavailable);
    _rewarded = null;
    final Completer<AdShowResult> done = Completer<AdShowResult>();
    bool earned = false;
    ad.fullScreenContentCallback = gma.FullScreenContentCallback<gma.RewardedAd>(
      onAdDismissedFullScreenContent: (gma.RewardedAd shown) {
        shown.dispose();
        if (!done.isCompleted) {
          done.complete(earned ? AdShowResult.rewardEarned : AdShowResult.shown);
        }
      },
      onAdFailedToShowFullScreenContent: (gma.RewardedAd failed, gma.AdError error) {
        onError?.call('rewarded ad failed to show: ${error.message}');
        failed.dispose();
        if (!done.isCompleted) done.complete(AdShowResult.unavailable);
      },
    );
    try {
      unawaited(
        ad.show(
          onUserEarnedReward: (gma.AdWithoutView view, gma.RewardItem reward) {
            earned = true;
          },
        ),
      );
    } on Object catch (error) {
      onError?.call('rewarded ad failed to show: $error');
      ad.dispose();
      if (!done.isCompleted) done.complete(AdShowResult.unavailable);
    }
    return done.future;
  }

  @override
  Future<double> bannerHeight(double width) async {
    if (!_initialized) return 0;
    try {
      final gma.AnchoredAdaptiveBannerAdSize? size =
          await gma.AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());
      if (size == null) return 0;
      final Completer<bool> done = Completer<bool>();
      _banner?.dispose();
      _bannerLoaded = false;
      final gma.BannerAd ad = gma.BannerAd(
        adUnitId: units.banner,
        size: size,
        request: const gma.AdRequest(),
        listener: gma.BannerAdListener(
          onAdLoaded: (gma.Ad loaded) {
            _bannerLoaded = true;
            if (!done.isCompleted) done.complete(true);
          },
          onAdFailedToLoad: (gma.Ad failed, gma.LoadAdError error) {
            onError?.call('banner failed to load: ${error.message}');
            failed.dispose();
            _bannerLoaded = false;
            if (!done.isCompleted) done.complete(false);
          },
        ),
      );
      _banner = ad;
      await ad.load();
      final bool ok = await done.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
      return ok ? size.height.toDouble() : 0;
    } on Object catch (error) {
      onError?.call('banner failed to load: $error');
      return 0;
    }
  }

  /// Drops the banner (a screen without one, or Remove Ads).
  void disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _bannerLoaded = false;
  }
}
