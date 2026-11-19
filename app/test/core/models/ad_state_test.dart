import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/ad_state.dart';

void main() {
  test('nothing may load before consent is read', () {
    expect(AdState.initial.canShowBanner, isFalse);
    expect(AdState.initial.canShowInterstitial, isFalse);
    expect(AdState.initial.canShowRewarded, isFalse);
  });

  test('banner and interstitial follow canRequestAds and the purchase', () {
    const AdState allowed = AdState(
      consentStatus: ConsentStatus.obtained,
      canRequestAds: true,
    );
    expect(allowed.canShowBanner, isTrue);
    expect(allowed.canShowInterstitial, isTrue);
    expect(allowed.canShowRewarded, isTrue);

    final AdState removed = allowed.copyWith(adsRemoved: true);
    expect(removed.canShowBanner, isFalse);
    expect(removed.canShowInterstitial, isFalse);
    expect(removed.canShowRewarded, isTrue);
  });

  test('an answered form does not by itself allow requests', () {
    const AdState s = AdState(consentStatus: ConsentStatus.obtained);
    expect(s.canShowBanner, isFalse);
  });

  test('equality and copyWith', () {
    const AdState a = AdState(canRequestAds: true, privacyOptionsRequired: true);
    expect(a, a.copyWith());
    expect(a.hashCode, a.copyWith().hashCode);
    expect(a == a.copyWith(canRequestAds: false), isFalse);
  });
}
