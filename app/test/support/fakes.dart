import 'package:ruach/core/ports/file_store.dart';

/// An in-memory [FileStore]. Set [failWrites] or [failRenames] to simulate
/// storage errors, or edit [files] to simulate damage.
final class FakeFileStore implements FileStore {
  final Map<String, String> files = <String, String>{};
  bool failWrites = false;
  bool failRenames = false;
  final List<String> calls = <String>[];

  @override
  Future<String?> read(String name) async => files[name];

  @override
  Future<void> write(String name, String content) async {
    calls.add('write $name');
    if (failWrites) throw StateError('disk full');
    files[name] = content;
  }

  @override
  Future<void> rename(String from, String to) async {
    calls.add('rename $from $to');
    if (failRenames) throw StateError('rename failed');
    final String? text = files.remove(from);
    if (text == null) throw StateError('missing $from');
    files[to] = text;
  }

  @override
  Future<void> delete(String name) async {
    calls.add('delete $name');
    files.remove(name);
  }

  @override
  Future<bool> exists(String name) async => files.containsKey(name);
}

/// An in-memory [KeyValueStore].
final class FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}
