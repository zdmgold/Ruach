import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/migrations.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/models/app_error.dart';
import 'package:ruach/core/models/progress.dart';

import '../support/fakes.dart';

Progress _sample() => Progress(
      stars: <String, int>{'nile_banks': 3},
      giftsEarned: 5,
      giftsSpent: 2,
      currentStreak: 4,
      seenVerseIds: <String>{'en:Gen.1.1'},
    );

void main() {
  group('ProgressCodec', () {
    test('a round trip keeps everything and is stable', () {
      final String text = ProgressCodec.encode(_sample());
      final DecodedProgress d = ProgressCodec.decode(text);
      expect(d.valid, isTrue);
      expect(d.newerSchema, isFalse);
      expect(ProgressCodec.encode(d.progress!), text);
      expect(d.progress!.starsOn('nile_banks'), 3);
      expect(d.progress!.gifts, 3);
    });

    test('garbage is invalid, never an exception', () {
      for (final String text in <String>['', 'not json', '[1,2]', '"x"', '{"schemaVersion":0}', '{"schemaVersion":-3}']) {
        expect(ProgressCodec.decode(text).valid, isFalse, reason: text);
      }
    });

    test('a file with no version is read as version 1', () {
      final DecodedProgress d = ProgressCodec.decode('{"giftsEarned":7}');
      expect(d.valid, isTrue);
      expect(d.progress!.giftsEarned, 7);
    });

    test('a newer schema is read but flagged', () {
      final DecodedProgress d = ProgressCodec.decode('{"schemaVersion":99,"giftsEarned":7,"future":true}');
      expect(d.valid, isTrue);
      expect(d.newerSchema, isTrue);
      expect(d.progress!.giftsEarned, 7);
    });
  });

  group('Migrations', () {
    test('runs each step in order and stamps the version', () {
      final List<int> ran = <int>[];
      final MigrationResult r = Migrations.migrate(
        <String, Object?>{'schemaVersion': 1, 'a': 1},
        from: 1,
        to: 3,
        steps: <int, MigrationStep>{
          1: (Map<String, Object?> j) {
            ran.add(1);
            return <String, Object?>{...j, 'b': 2};
          },
          2: (Map<String, Object?> j) {
            ran.add(2);
            return <String, Object?>{...j, 'c': j['b']};
          },
        },
      );
      expect(r.ok, isTrue);
      expect(ran, <int>[1, 2]);
      expect(r.json['c'], 2);
      expect(r.json['schemaVersion'], 3);
    });

    test('a missing or throwing step fails', () {
      expect(Migrations.migrate(<String, Object?>{}, from: 1, to: 2).ok, isFalse);
      expect(
        Migrations.migrate(
          <String, Object?>{},
          from: 1,
          to: 2,
          steps: <int, MigrationStep>{1: (Map<String, Object?> j) => throw StateError('x')},
        ).ok,
        isFalse,
      );
    });

    test('same version needs no steps; bad ranges fail', () {
      expect(Migrations.migrate(<String, Object?>{'a': 1}, from: 1, to: 1).ok, isTrue);
      expect(Migrations.migrate(<String, Object?>{}, from: 0, to: 1).ok, isFalse);
      expect(Migrations.migrate(<String, Object?>{}, from: 3, to: 2).ok, isFalse);
    });
  });

  group('ProgressRepository', () {
    late FakeFileStore store;
    late ProgressRepository repo;
    setUp(() {
      store = FakeFileStore();
      repo = ProgressRepository(store);
    });

    test('first run starts fresh with no notice', () async {
      final ProgressLoad l = await repo.load();
      expect(l.origin, ProgressOrigin.firstRun);
      expect(l.needsNotice, isFalse);
      expect(l.progress.totalStars, 0);
    });

    test('save then load returns the same progress', () async {
      expect(await repo.save(_sample()), isNull);
      final ProgressLoad l = await ProgressRepository(store).load();
      expect(l.origin, ProgressOrigin.primary);
      expect(ProgressCodec.encode(l.progress), ProgressCodec.encode(_sample()));
      expect(store.files.containsKey(ProgressRepository.tempName), isFalse);
    });

    test('the second save keeps the first as the backup', () async {
      await repo.save(Progress(giftsEarned: 1));
      await repo.save(Progress(giftsEarned: 2));
      expect(ProgressCodec.decode(store.files[ProgressRepository.backupName]!).progress!.giftsEarned, 1);
      expect(ProgressCodec.decode(store.files[ProgressRepository.fileName]!).progress!.giftsEarned, 2);
    });

    test('a damaged main file falls back to the backup with a notice', () async {
      await repo.save(Progress(giftsEarned: 1));
      await repo.save(Progress(giftsEarned: 2));
      store.files[ProgressRepository.fileName] = '{broken';
      final ProgressLoad l = await ProgressRepository(store).load();
      expect(l.origin, ProgressOrigin.backup);
      expect(l.needsNotice, isTrue);
      expect(l.progress.giftsEarned, 1);
    });

    test('a missing main file with a backup uses the backup', () async {
      await repo.save(Progress(giftsEarned: 1));
      await repo.save(Progress(giftsEarned: 2));
      store.files.remove(ProgressRepository.fileName);
      expect((await ProgressRepository(store).load()).progress.giftsEarned, 1);
    });

    test('both damaged starts clean with a notice', () async {
      store.files[ProgressRepository.fileName] = 'x';
      store.files[ProgressRepository.backupName] = 'y';
      final ProgressLoad l = await repo.load();
      expect(l.origin, ProgressOrigin.startedClean);
      expect(l.needsNotice, isTrue);
      expect(l.progress.totalStars, 0);
    });

    test('a damaged main file never replaces a good backup', () async {
      await repo.save(Progress(giftsEarned: 1));
      await repo.save(Progress(giftsEarned: 2));
      store.files[ProgressRepository.fileName] = 'damaged';
      await repo.save(Progress(giftsEarned: 3));
      expect(ProgressCodec.decode(store.files[ProgressRepository.backupName]!).progress!.giftsEarned, 1);
      expect(ProgressCodec.decode(store.files[ProgressRepository.fileName]!).progress!.giftsEarned, 3);
    });

    test('a newer schema loads read-only and is never overwritten', () async {
      final String newer = jsonEncode(<String, Object?>{'schemaVersion': 99, 'giftsEarned': 8});
      store.files[ProgressRepository.fileName] = newer;
      final ProgressLoad l = await repo.load();
      expect(l.readOnly, isTrue);
      expect(repo.readOnly, isTrue);
      expect(l.progress.giftsEarned, 8);
      expect(await repo.save(Progress()), isA<StorageError>());
      expect(store.files[ProgressRepository.fileName], newer);
    });

    test('a write failure is reported and leaves the old file intact', () async {
      await repo.save(Progress(giftsEarned: 1));
      store.failWrites = true;
      final AppError? error = await repo.save(Progress(giftsEarned: 2));
      expect(error, isA<StorageError>());
      expect(error!.offersRetry, isTrue);
      expect(ProgressCodec.decode(store.files[ProgressRepository.fileName]!).progress!.giftsEarned, 1);
    });

    test('a rename failure is reported and the temp file is removed', () async {
      await repo.save(Progress(giftsEarned: 1));
      store.failRenames = true;
      expect(await repo.save(Progress(giftsEarned: 2)), isA<StorageError>());
      expect(store.files.containsKey(ProgressRepository.tempName), isFalse);
      expect(ProgressCodec.decode(store.files[ProgressRepository.fileName]!).progress!.giftsEarned, 1);
    });
  });
}
