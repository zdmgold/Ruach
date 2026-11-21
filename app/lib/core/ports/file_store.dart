/// Whole-file storage for the progress file and its backup. The adapter
/// (platform/storage_service.dart) maps names to files in the app's private
/// folder; the save sequence itself lives in `progress_codec.dart`, so it can
/// be tested with an in-memory fake.
abstract interface class FileStore {
  /// The text of [name], or null when the file does not exist.
  Future<String?> read(String name);

  /// Writes [content] to [name], creating or replacing it.
  Future<void> write(String name, String content);

  /// Renames [from] to [to], replacing [to] if it exists.
  Future<void> rename(String from, String to);

  /// Deletes [name]; does nothing if it does not exist.
  Future<void> delete(String name);

  Future<bool> exists(String name);
}

/// Small preferences (the settings JSON, flags such as "onboarding seen").
abstract interface class KeyValueStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}
