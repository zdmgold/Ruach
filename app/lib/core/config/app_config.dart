/// Fixed facts about the app that more than one layer needs.
abstract final class AppConfig {
  static const String appName = 'Ruach';
  static const String storeTitle = 'Ruach: Bible Car Racing Game';
  static const String applicationId = 'com.zdmgold.ruach';

  /// Shown in Settings and on the website; also the target of "email the log".
  static const String supportEmail = 'stmakarios@gmail.com';

  /// The Cloudflare Pages address, with no trailing slash, for example
  /// `https://ruach.pages.dev`. Empty until the owner connects the site
  /// (blueprint open item 3); while empty, remote flags are not fetched and
  /// safe defaults apply.
  static const String siteBase = '';

  /// The static flags file on the site, or empty when [siteBase] is empty.
  static String get flagsUrl => siteBase.isEmpty ? '' : '$siteBase/flags.json';

  /// The Bible pack manifest (phase 8), or empty when [siteBase] is empty.
  static String get packManifestUrl =>
      siteBase.isEmpty ? '' : '$siteBase/scripture/manifest.json';
}
