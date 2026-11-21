import 'dart:async';

import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/core/ports/file_store.dart';

/// A rolling local log, the only crash and error record (no third-party
/// reporting). Keeps the newest [maxLines] lines in memory and writes them
/// to one file shortly after each change. Nothing here ever throws.
final class LogService implements LogPort {
  LogService(
    this._store, {
    this.maxLines = 400,
    this.writeDelay = const Duration(seconds: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const String fileName = 'ruach_log.txt';

  final FileStore _store;
  final int maxLines;
  final Duration writeDelay;
  final DateTime Function() _now;

  final List<String> _lines = <String>[];
  Timer? _timer;
  bool _loaded = false;

  /// Loads earlier lines from the file. Call once at start; safe to skip.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final String? text = await _store.read(fileName);
      if (text != null && text.isNotEmpty) {
        _lines.insertAll(0, text.split('\n').where((String l) => l.isNotEmpty));
        _trim();
      }
    } on Object {
      // A log that cannot be read is simply empty.
    }
  }

  @override
  void log(String message) {
    final String stamp = _now().toUtc().toIso8601String();
    for (final String line in message.split('\n')) {
      if (line.isEmpty) continue;
      _lines.add('$stamp $line');
    }
    _trim();
    _timer ??= Timer(writeDelay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  /// Writes the log now.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    try {
      await _store.write(fileName, _lines.isEmpty ? '' : '${_lines.join('\n')}\n');
    } on Object {
      // Logging must never break the app.
    }
  }

  @override
  Future<String> readAll() async {
    await load();
    return _lines.join('\n');
  }

  @override
  Future<void> clear() async {
    _lines.clear();
    await flush();
  }

  void _trim() {
    if (_lines.length > maxLines) {
      _lines.removeRange(0, _lines.length - maxLines);
    }
  }
}
