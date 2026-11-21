/// Remote switches read from a static `flags.json`. Every value has a safe
/// default, used when the file cannot be fetched or is malformed.
final class RemoteFlags {
  const RemoteFlags({
    this.adsEnabled = true,
    this.readerDownloadEnabled = true,
  });

  static const RemoteFlags defaults = RemoteFlags();

  final bool adsEnabled;
  final bool readerDownloadEnabled;

  /// Reads decoded JSON. Anything missing or of the wrong type keeps its
  /// default; it never throws.
  factory RemoteFlags.fromJson(Object? json) {
    if (json is! Map<Object?, Object?>) return defaults;
    bool read(String key, bool fallback) {
      final Object? v = json[key];
      return v is bool ? v : fallback;
    }

    return RemoteFlags(
      adsEnabled: read('adsEnabled', true),
      readerDownloadEnabled: read('readerDownloadEnabled', true),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RemoteFlags &&
      other.adsEnabled == adsEnabled &&
      other.readerDownloadEnabled == readerDownloadEnabled;

  @override
  int get hashCode => Object.hash(adsEnabled, readerDownloadEnabled);
}

abstract interface class FlagsPort {
  /// Fetches the flags. Returns [RemoteFlags.defaults] on any failure.
  Future<RemoteFlags> fetch();
}

/// Downloadable Bible packs (phase 8). Bytes are verified by the caller
/// against the manifest's SHA-256 before they are kept.
abstract interface class PacksPort {
  /// The manifest text, or throws on a network failure.
  Future<String> fetchManifest();

  /// The bytes at [url].
  Future<List<int>> download(Uri url);
}
