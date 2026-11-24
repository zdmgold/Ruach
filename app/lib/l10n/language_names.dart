/// Each language written in itself, so a player who cannot read the current
/// language can still find their own. These are names, not interface text, so
/// they are the same in every language and are not in the ARB files.
abstract final class LanguageNames {
  static const Map<String, String> native = <String, String>{
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt_BR': 'Português (Brasil)',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'ja': '日本語',
    'ko': '한국어',
    'zh_Hans': '简体中文',
    'he': 'עברית',
  };

  /// The name for [code], or the code itself if it is not known.
  static String of(String code) => native[code] ?? code;
}
