import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:ruach/core/logic/locale_rules.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/providers/settings_provider.dart';

/// The app language: the player's choice, or the best match for the device.
final class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._settings, {required String Function() deviceTag})
      : _deviceTag = deviceTag {
    _code = _compute();
    _settings.addListener(_onSettings);
  }

  final SettingsProvider _settings;
  final String Function() _deviceTag;
  late String _code;

  /// One of `LocaleRules.supported`.
  String get code => _code;

  bool get isRtl => LocaleRules.isRtl(_code);

  /// True when the player has picked a language (not following the device).
  bool get isOverridden => LocaleRules.isSupported(_settings.value.languageCode);

  Locale get locale => switch (_code) {
        'pt_BR' => const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
        'zh_Hans' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        _ => Locale(_code),
      };

  /// Picks a language, or follows the device when [code] is null.
  Future<void> setLanguage(String? code) => _settings.update(
        (Settings s) => code == null
            ? s.copyWith(clearLanguage: true)
            : s.copyWith(languageCode: LocaleRules.isSupported(code) ? code : null),
      );

  /// Re-reads the device language (for example after the system changes it).
  void deviceChanged() => _onSettings();

  String _compute() => LocaleRules.effective(
        chosen: _settings.value.languageCode,
        deviceTag: _deviceTag(),
      );

  void _onSettings() {
    final String next = _compute();
    if (next != _code) {
      _code = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }
}
