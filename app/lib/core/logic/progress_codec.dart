import 'dart:convert';

import 'package:ruach/core/logic/migrations.dart';
import 'package:ruach/core/models/app_error.dart';
import 'package:ruach/core/models/json_read.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/ports/file_store.dart';

/// How the progress was obtained at launch.
enum ProgressOrigin {
  /// No file existed: a new player.
  firstRun,

  /// Read from the main file.
  primary,

  /// The main file was missing or damaged and the backup was used. The player
  /// sees a one-time notice.
  backup,

  /// Both files were damaged: the app starts clean and shows a one-time
  /// notice.
  startedClean,
}

/// The outcome of reading text into [Progress].
final class DecodedProgress {
  const DecodedProgress.valid(this.progress, {this.newerSchema = false}) : valid = true;

  const DecodedProgress.invalid()
      : valid = false,
        newerSchema = false,
        progress = null;

  final bool valid;
  final Progress? progress;

  /// True when the file was written by a newer app. It is read as far as it is
  /// understood and must never be overwritten.
  final bool newerSchema;
}

/// Text to [Progress] and back, with schema versioning.
abstract final class ProgressCodec {
  static String encode(Progress progress) => jsonEncode(progress.toJson());

  /// Never throws.
  static DecodedProgress decode(String text) {
    final Object? parsed;
    try {
      parsed = jsonDecode(text);
    } on FormatException {
      return const DecodedProgress.invalid();
    }
    if (parsed is! Map<Object?, Object?>) return const DecodedProgress.invalid();
    final Map<String, Object?> map = asJsonMap(parsed);
    final int version = readInt(map['schemaVersion'], 1);
    if (version < 1) return const DecodedProgress.invalid();
    if (version > Progress.currentSchemaVersion) {
      return DecodedProgress.valid(Progress.fromJson(map), newerSchema: true);
    }
    final MigrationResult migrated = Migrations.migrate(
      map,
      from: version,
      to: Progress.currentSchemaVersion,
    );
    if (!migrated.ok) return const DecodedProgress.invalid();
    return DecodedProgress.valid(Progress.fromJson(migrated.json));
  }
}

/// What [ProgressRepository.load] found.
final class ProgressLoad {
  const ProgressLoad(this.progress, this.origin, {this.readOnly = false});

  final Progress progress;
  final ProgressOrigin origin;

  /// True when the saved file is from a newer app. Saving is refused so the
  /// newer data is never overwritten.
  final bool readOnly;

  /// True when the player should see the one-time "restored" or "started
  /// fresh" notice.
  bool get needsNotice =>
      origin == ProgressOrigin.backup || origin == ProgressOrigin.startedClean;
}

/// Loads and saves progress with an atomic write and a backup.
///
/// Save sequence: write a temporary file; if the current file is readable,
/// move it to the backup (a damaged file never replaces a good backup); move
/// the temporary file into place. A crash at any point leaves either the old
/// file, the backup or the new file readable.
final class ProgressRepository {
  ProgressRepository(this._store);

  static const String fileName = 'progress.json';
  static const String backupName = 'progress.json.bak';
  static const String tempName = 'progress.json.tmp';

  final FileStore _store;
  bool _readOnly = false;

  bool get readOnly => _readOnly;

  Future<ProgressLoad> load() async {
    _readOnly = false;
    final String? primary = await _tryRead(fileName);
    final String? backup = await _tryRead(backupName);
    if (primary == null && backup == null) {
      return ProgressLoad(Progress.fresh(), ProgressOrigin.firstRun);
    }
    if (primary != null) {
      final DecodedProgress d = ProgressCodec.decode(primary);
      if (d.valid) {
        _readOnly = d.newerSchema;
        return ProgressLoad(
          d.progress!,
          ProgressOrigin.primary,
          readOnly: d.newerSchema,
        );
      }
    }
    if (backup != null) {
      final DecodedProgress d = ProgressCodec.decode(backup);
      if (d.valid) {
        _readOnly = d.newerSchema;
        return ProgressLoad(
          d.progress!,
          ProgressOrigin.backup,
          readOnly: d.newerSchema,
        );
      }
    }
    return ProgressLoad(Progress.fresh(), ProgressOrigin.startedClean);
  }

  /// Saves [progress]. Returns null on success, or a [StorageError] to show as
  /// a warning; the app keeps working in memory and retries on the next
  /// change.
  Future<AppError?> save(Progress progress) async {
    if (_readOnly) {
      return const StorageError('saved progress is from a newer app; not overwritten');
    }
    try {
      await _store.write(tempName, ProgressCodec.encode(progress));
      final String? current = await _store.read(fileName);
      if (current != null && ProgressCodec.decode(current).valid) {
        await _store.rename(fileName, backupName);
      }
      await _store.rename(tempName, fileName);
      return null;
    } on Object catch (error) {
      try {
        await _store.delete(tempName);
      } on Object {
        // Nothing more can be done; the next save tries again.
      }
      return StorageError('progress save failed', cause: error);
    }
  }

  Future<String?> _tryRead(String name) async {
    try {
      return await _store.read(name);
    } on Object {
      return null;
    }
  }
}
