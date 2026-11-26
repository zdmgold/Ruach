import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/locale_rules.dart';
import 'package:ruach/l10n/app_localizations.dart';

Locale _locale(String code) => switch (code) {
      'pt_BR' => const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      'zh_Hans' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      _ => Locale(code),
    };

void main() {
  test('every supported language has a translation that loads', () async {
    expect(AppLocalizations.supportedLocales.length, LocaleRules.supported.length);
    for (final String code in LocaleRules.supported) {
      final AppLocalizations l = await AppLocalizations.delegate.load(_locale(code));
      expect(l.appName, 'Ruach', reason: code);
      expect(l.giftCount(1), isNotEmpty, reason: code);
      expect(l.giftCount(12), contains('12'), reason: code);
      expect(l.streakDays(0), isNotEmpty, reason: code);
    }
  });

  test('plural forms differ by count in languages that have them', () async {
    final AppLocalizations ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(ar.giftCount(2), isNot(ar.giftCount(12)));
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.giftCount(1), '1 Gift');
  });
}
