import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/config/ad_units.dart';
import 'package:ruach/core/config/app_config.dart';

void main() {
  test('only Google sample ids are in use until production ids exist', () {
    for (final AdUnits u in <AdUnits>[AdUnits.androidTest, AdUnits.iosTest]) {
      expect(u.isTest, isTrue);
      expect(u.appId, contains('~'));
      for (final String id in <String>[u.banner, u.interstitial, u.rewarded]) {
        expect(id, startsWith('ca-app-pub-3940256099942544/'));
      }
    }
    expect(AdUnits.androidTest.banner, isNot(AdUnits.iosTest.banner));
  });

  test('identity constants match the locked decisions', () {
    expect(AppConfig.applicationId, 'com.zdmgold.ruach');
    expect(AppConfig.supportEmail, 'stmakarios@gmail.com');
    expect(AppConfig.storeTitle.length, lessThan(30));
  });

  test('flag and pack addresses are empty until the site address is set', () {
    expect(AppConfig.siteBase.isEmpty, AppConfig.flagsUrl.isEmpty);
    expect(AppConfig.siteBase.isEmpty, AppConfig.packManifestUrl.isEmpty);
  });
}
