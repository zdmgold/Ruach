import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/verse.dart';

const List<String> _languages = <String>[
  'en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he',
];

const Map<String, int> _expectedPerMoment = <String, int>{
  'upgrade': 6,
  'track-intro': 16,
  'welcome-back': 20,
  'milestone': 30,
  'win': 40,
  'podium': 40,
  'encouragement': 60,
  'daily': 120,
};

Map<String, Object?> _load(String language) {
  final List<int> bytes = gzip.decode(
    File('assets/verses/$language.json.gz').readAsBytesSync(),
  );
  return jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
}

List<Map<String, Object?>> _verses(Map<String, Object?> bundle) =>
    (bundle['verses']! as List<Object?>).cast<Map<String, Object?>>();

void main() {
  final Map<String, List<Map<String, Object?>>> byLanguage =
      <String, List<Map<String, Object?>>>{
    for (final String l in _languages) l: _verses(_load(l)),
  };

  test('every language has a bundle for the same references', () {
    final Set<String> english = byLanguage['en']!
        .map((Map<String, Object?> v) => v['ref']! as String)
        .toSet();
    expect(english.length, 332);
    for (final String l in _languages) {
      final Set<String> refs = byLanguage[l]!
          .map((Map<String, Object?> v) => v['ref']! as String)
          .toSet();
      expect(refs, english, reason: l);
    }
  });

  test('every verse has text, a valid reference and known moments', () {
    for (final String l in _languages) {
      final Map<String, Object?> bundle = _load(l);
      expect(bundle['language'], l);
      expect(bundle['schema'], 1);
      for (final Map<String, Object?> v in byLanguage[l]!) {
        final String ref = v['ref']! as String;
        expect(VerseRef.tryParse(ref), isNotNull, reason: '$l $ref');
        expect((v['text']! as String).trim(), isNotEmpty, reason: '$l $ref');
        final List<Object?> moments = v['moments']! as List<Object?>;
        expect(moments, isNotEmpty, reason: '$l $ref');
        for (final Object? m in moments) {
          expect(VerseMoment.fromTag(m! as String), isNotNull, reason: '$l $ref');
        }
      }
    }
  });

  test('each moment has the planned number of verses in every language', () {
    for (final String l in _languages) {
      final Map<String, int> counts = <String, int>{};
      for (final Map<String, Object?> v in byLanguage[l]!) {
        for (final Object? m in v['moments']! as List<Object?>) {
          counts[m! as String] = (counts[m] ?? 0) + 1;
        }
      }
      expect(counts, _expectedPerMoment, reason: l);
    }
  });

  test('every language has a licence notice', () {
    for (final String l in _languages) {
      final File f = File('assets/notices/scripture-$l.txt');
      expect(f.existsSync(), isTrue, reason: l);
      expect(f.readAsStringSync().trim(), isNotEmpty, reason: l);
    }
  });
}
