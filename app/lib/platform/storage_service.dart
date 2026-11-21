import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:ruach/core/ports/file_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [FileStore] over the app's private support folder. Reads return null for a
/// missing file; everything else throws so the repository can report a
/// [StorageError].
final class DirectoryFileStore implements FileStore {
  DirectoryFileStore(this._directory);

  /// Opens the app's private folder, creating it if needed.
  static Future<DirectoryFileStore> open() async {
    final Directory dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return DirectoryFileStore(dir);
  }

  final Directory _directory;

  File _file(String name) => File('${_directory.path}${Platform.pathSeparator}$name');

  @override
  Future<String?> read(String name) async {
    final File file = _file(name);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String name, String content) async {
    await _file(name).writeAsString(content, flush: true);
  }

  @override
  Future<void> rename(String from, String to) async {
    await _file(from).rename(_file(to).path);
  }

  @override
  Future<void> delete(String name) async {
    final File file = _file(name);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> exists(String name) => _file(name).exists();
}

/// [KeyValueStore] over the platform's preferences.
final class PreferencesStore implements KeyValueStore {
  PreferencesStore() : _prefs = SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
