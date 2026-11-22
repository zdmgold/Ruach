/// Which of the 11 languages the app uses (blueprint section 8).
abstract final class LocaleRules {
  /// App language codes. These are also the names of the verse bundles.
  static const List<String> supported = <String>[
    'en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he',
  ];

  static const String fallback = 'en';

  /// Languages written right to left.
  static const Set<String> rtl = <String>{'ar', 'he'};

  static bool isSupported(String? code) => code != null && supported.contains(code);

  static bool isRtl(String code) => rtl.contains(code);

  /// The supported code that best matches a device locale tag such as
  /// `pt-PT`, `zh-Hant-TW`, `iw` or `en_GB`. Unknown languages give English.
  static String resolve(String tag) {
    final List<String> parts = tag
        .replaceAll('-', '_')
        .split('_')
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return fallback;
    String language = parts.first.toLowerCase();
    if (language == 'iw') language = 'he';
    switch (language) {
      case 'pt':
        return 'pt_BR';
      case 'zh':
        return 'zh_Hans';
      default:
        return supported.contains(language) ? language : fallback;
    }
  }

  /// The language to use: the player's choice if it is supported, otherwise
  /// the best match for the device.
  static String effective({required String? chosen, required String deviceTag}) =>
      isSupported(chosen) ? chosen! : resolve(deviceTag);
}
