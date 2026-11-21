/// Supplies the decoded JSON of a language's bundled verses. The adapter
/// (platform/asset_verse_source.dart) reads and decompresses the asset; core
/// never touches files.
abstract interface class VerseDataSource {
  /// The decoded JSON for [language] (for example `en` or `pt_BR`), or null
  /// when there is no bundle for it. May throw on a read failure.
  Future<Object?> load(String language);
}
