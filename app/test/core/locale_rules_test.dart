import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/locale_rules.dart';

void main() {
  test('device tags resolve to the supported languages', () {
    expect(LocaleRules.resolve('en_GB'), 'en');
    expect(LocaleRules.resolve('en-US'), 'en');
    expect(LocaleRules.resolve('es-419'), 'es');
    expect(LocaleRules.resolve('pt-PT'), 'pt_BR');
    expect(LocaleRules.resolve('pt_BR'), 'pt_BR');
    expect(LocaleRules.resolve('zh-Hant-TW'), 'zh_Hans');
    expect(LocaleRules.resolve('zh_Hans_CN'), 'zh_Hans');
    expect(LocaleRules.resolve('iw'), 'he');
    expect(LocaleRules.resolve('he-IL'), 'he');
    expect(LocaleRules.resolve('ja'), 'ja');
    expect(LocaleRules.resolve('sv-SE'), 'en');
    expect(LocaleRules.resolve(''), 'en');
  });

  test('every supported code resolves to itself', () {
    for (final String code in LocaleRules.supported) {
      expect(LocaleRules.resolve(code), code);
    }
    expect(LocaleRules.supported.length, 11);
  });

  test('right to left is Arabic and Hebrew only', () {
    expect(LocaleRules.supported.where(LocaleRules.isRtl).toList(), <String>['ar', 'he']);
  });

  test('a supported choice wins over the device', () {
    expect(LocaleRules.effective(chosen: 'ko', deviceTag: 'fr'), 'ko');
    expect(LocaleRules.effective(chosen: null, deviceTag: 'fr'), 'fr');
    expect(LocaleRules.effective(chosen: 'xx', deviceTag: 'de'), 'de');
  });
}
