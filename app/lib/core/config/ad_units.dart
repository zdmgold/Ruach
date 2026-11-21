/// AdMob ids. Until the owner supplies production ids (blueprint open item 8)
/// only Google's sample ids are used, copied from the example app of the
/// google_mobile_ads package (version 9.2.0) and its iOS Info.plist.
final class AdUnits {
  const AdUnits({
    required this.appId,
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  /// Google's sample ids for Android.
  static const AdUnits androidTest = AdUnits(
    appId: 'ca-app-pub-3940256099942544~3347511713',
    banner: 'ca-app-pub-3940256099942544/9214589741',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  /// Google's sample ids for iOS.
  static const AdUnits iosTest = AdUnits(
    appId: 'ca-app-pub-3940256099942544~1458002511',
    banner: 'ca-app-pub-3940256099942544/2435281174',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  );

  final String appId;

  /// Adaptive banner unit.
  final String banner;
  final String interstitial;
  final String rewarded;

  /// True while these are Google's sample ids.
  bool get isTest => appId.startsWith('ca-app-pub-3940256099942544');
}
