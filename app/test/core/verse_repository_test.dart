import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/verse_map.dart';
import 'package:ruach/core/logic/verse_repository.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/core/ports/verse_source.dart';

const List<String> _languages = <String>[
  'en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he',
];

final class _AssetSource implements VerseDataSource {
  @override
  Future<Object?> load(String language) async {
    final File f = File('assets/verses/$language.json.gz');
    if (!f.existsSync()) return null;
    return jsonDecode(utf8.decode(gzip.decode(f.readAsBytesSync())));
  }
}

final class _MapSource implements VerseDataSource {
  _MapSource(this.data, {this.throwFor = const <String>{}});

  final Map<String, Object?> data;
  final Set<String> throwFor;
  int loads = 0;

  @override
  Future<Object?> load(String language) async {
    loads++;
    if (throwFor.contains(language)) throw StateError('unreadable');
    return data[language];
  }
}

Map<String, Object?> _bundle(List<(String, String, List<String>)> verses) => <String, Object?>{
      'verses': <Object?>[
        for (final (String ref, String text, List<String> moments) in verses)
          <String, Object?>{'ref': ref, 'text': text, 'moments': moments},
      ],
    };

void main() {
  group('VerseBundle', () {
    test('skips entries with a bad reference, empty text or unknown moment', () {
      final VerseBundle b = VerseBundle.fromJson('en', <String, Object?>{
        'verses': <Object?>[
          <String, Object?>{'ref': 'Gen.1.1', 'text': 'ok', 'moments': <String>['win', 'nonsense']},
          <String, Object?>{'ref': 'bad', 'text': 'x', 'moments': <String>['win']},
          <String, Object?>{'ref': 'Gen.1.2', 'text': '', 'moments': <String>['win']},
          'junk',
        ],
      });
      expect(b.verses.length, 1);
      expect(b.verses.single.moments, <VerseMoment>{VerseMoment.win});
    });

    test('never throws on junk', () {
      expect(VerseBundle.fromJson('en', null).isEmpty, isTrue);
      expect(VerseBundle.fromJson('en', 5).isEmpty, isTrue);
    });
  });

  group('VerseRepository with a small bundle', () {
    final Map<String, Object?> data = <String, Object?>{
      'en': _bundle(<(String, String, List<String>)>[
        ('Ps.23.1', 'A', <String>['win']),
        ('Ps.23.2', 'B', <String>['win']),
        ('Ps.23.3', 'C', <String>['win']),
        ('John.3.16', 'D', <String>['daily']),
      ]),
      'es': _bundle(<(String, String, List<String>)>[
        ('Ps.23.1', 'a', <String>['win']),
        ('Ps.23.2', 'b', <String>['win']),
        ('Ps.23.3', 'c', <String>['win']),
      ]),
    };

    test('the same inputs always give the same verse', () async {
      final VerseRepository r = VerseRepository(_MapSource(data));
      final Verse? a = await r.pick(moment: VerseMoment.win, language: 'en', seed: 5);
      final Verse? b = await VerseRepository(_MapSource(data)).pick(moment: VerseMoment.win, language: 'en', seed: 5);
      expect(a!.id, b!.id);
    });

    test('the same seed picks the same reference in every language', () async {
      final VerseRepository r = VerseRepository(_MapSource(data));
      for (int seed = 0; seed < 20; seed++) {
        final Verse? en = await r.pick(moment: VerseMoment.win, language: 'en', seed: seed);
        final Verse? es = await r.pick(moment: VerseMoment.win, language: 'es', seed: seed);
        expect(en!.ref, es!.ref);
        expect(es.language, 'es');
      }
    });

    test('different seeds reach every verse', () async {
      final VerseRepository r = VerseRepository(_MapSource(data));
      final Set<String> seen = <String>{
        for (int s = 0; s < 60; s++) (await r.pick(moment: VerseMoment.win, language: 'en', seed: s))!.ref.key,
      };
      expect(seen.length, 3);
    });

    test('unseen verses are preferred, then anything', () async {
      final VerseRepository r = VerseRepository(_MapSource(data));
      for (int s = 0; s < 30; s++) {
        final Verse? v = await r.pick(
          moment: VerseMoment.win,
          language: 'en',
          seed: s,
          seenIds: <String>{'en:Ps.23.1', 'es:Ps.23.2'},
        );
        expect(v!.ref.key, 'Ps.23.3');
      }
      final Verse? all = await r.pick(
        moment: VerseMoment.win,
        language: 'en',
        seed: 1,
        seenIds: <String>{'en:Ps.23.1', 'en:Ps.23.2', 'en:Ps.23.3'},
      );
      expect(all, isNotNull);
    });

    test('a moment with no verses gives null', () async {
      final VerseRepository r = VerseRepository(_MapSource(data));
      expect(await r.pick(moment: VerseMoment.upgrade, language: 'en', seed: 1), isNull);
    });

    test('a missing or unreadable language falls back to English', () async {
      final VerseRepository r = VerseRepository(_MapSource(data, throwFor: <String>{'fr'}));
      expect((await r.bundle('de')).language, 'en');
      expect((await r.bundle('fr')).language, 'en');
      expect((await r.pick(moment: VerseMoment.win, language: 'fr', seed: 1))!.language, 'en');
    });

    test('bundles are cached', () async {
      final _MapSource source = _MapSource(data);
      final VerseRepository r = VerseRepository(source);
      await r.bundle('en');
      await r.bundle('en');
      expect(source.loads, 1);
    });

    test('byId, forRef and library', () async {
      final VerseRepository r = VerseRepository(_MapSource(data));
      expect((await r.byId('en:John.3.16'))!.text, 'D');
      expect((await r.byId('en:Ps.23.2', language: 'es'))!.text, 'b');
      expect(await r.byId('nocolon'), isNull);
      expect(await r.byId('en:garbage'), isNull);
      expect((await r.forRef('en', VerseRef.tryParse('Ps.23.3')!))!.text, 'C');
      final List<Verse> lib = await r.library('es', <String>{'en:Ps.23.3', 'en:Ps.23.1', 'en:John.3.16'});
      expect(lib.map((Verse v) => v.ref.key).toList(), <String>['Ps.23.1', 'Ps.23.3']);
    });
  });

  group('the bundled verses', () {
    final VerseRepository repo = VerseRepository(_AssetSource());

    test('all 11 languages load with the same references', () async {
      final Set<String> english = <String>{for (final Verse v in (await repo.bundle('en')).verses) v.ref.key};
      expect(english.length, 332);
      for (final String l in _languages) {
        final VerseBundle b = await repo.bundle(l);
        expect(b.language, l, reason: l);
        expect(<String>{for (final Verse v in b.verses) v.ref.key}, english, reason: l);
      }
    });

    test('every moment has verses in every language', () async {
      for (final String l in _languages) {
        for (final VerseMoment m in VerseMoment.values) {
          expect((await repo.pick(moment: m, language: l, seed: 1)), isNotNull, reason: '$l ${m.tag}');
        }
      }
    });

    test('the same seed picks the same reference everywhere', () async {
      for (final VerseMoment m in VerseMoment.values) {
        for (int seed = 1; seed <= 5; seed++) {
          final String expected = (await repo.pick(moment: m, language: 'en', seed: seed))!.ref.key;
          for (final String l in _languages) {
            expect((await repo.pick(moment: m, language: l, seed: seed))!.ref.key, expected, reason: '$l ${m.tag} $seed');
          }
        }
      }
    });
  });

  group('VerseMap', () {
    VerseRef r(String s) => VerseRef.tryParse(s)!;

    test('identity changes nothing', () {
      final VerseMap m = VerseMap.identity('en');
      expect(m.isIdentity, isTrue);
      expect(m.toLocal(r('Ps.23.1-3')), r('Ps.23.1-3'));
      expect(m.toCanonical(r('John.3.16')), r('John.3.16'));
    });

    test('overrides translate both ways', () {
      final VerseMap m = VerseMap.fromJson('he', <String, Object?>{
        'Joel.3.1': 'Joel.4.1',
        'Ps.51.1': 'Ps.51.3',
        'Ps.51.2': 'Ps.51.4',
      });
      expect(m.isIdentity, isFalse);
      expect(m.toLocal(r('Joel.3.1')), r('Joel.4.1'));
      expect(m.toCanonical(r('Joel.4.1')), r('Joel.3.1'));
      expect(m.toLocal(r('Ps.51.1-2')), r('Ps.51.3-4'));
      expect(m.toCanonical(r('Ps.51.3-4')), r('Ps.51.1-2'));
      expect(m.toLocal(r('Ps.51.9')), r('Ps.51.9'));
    });

    test('a range whose ends fall in different chapters keeps its first verse', () {
      final VerseMap m = VerseMap.fromJson('he', <String, Object?>{
        'Joel.2.28': 'Joel.3.1',
        'Joel.2.29': 'Joel.4.1',
      });
      expect(m.toLocal(r('Joel.2.28-29')), r('Joel.3.1'));
    });

    test('bad entries are skipped', () {
      final VerseMap m = VerseMap.fromJson('he', <String, Object?>{
        'nope': 'Ps.1.1',
        'Ps.1.1': 5,
        'Ps.1.2-3': 'Ps.1.3',
        'Ps.1.4': 'Ps.1.5-6',
      });
      expect(m.isIdentity, isTrue);
      expect(VerseMap.fromJson('he', 'junk').isIdentity, isTrue);
    });
  });
}
