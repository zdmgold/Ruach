import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/verse.dart';

void main() {
  test('moment tags round-trip and are unique', () {
    final Set<String> tags = <String>{};
    for (final VerseMoment m in VerseMoment.values) {
      expect(VerseMoment.fromTag(m.tag), m);
      tags.add(m.tag);
    }
    expect(tags.length, 8);
    expect(VerseMoment.fromTag('nope'), isNull);
    expect(VerseMoment.welcomeBack.tag, 'welcome-back');
  });

  test('references parse and print', () {
    final VerseRef single = VerseRef.tryParse('John.3.16')!;
    expect(single.book, 'John');
    expect(single.chapter, 3);
    expect(single.verse, 16);
    expect(single.isRange, isFalse);
    expect(single.key, 'John.3.16');

    final VerseRef range = VerseRef.tryParse('Ps.23.1-3')!;
    expect(range.isRange, isTrue);
    expect(range.endVerse, 3);
    expect(range.key, 'Ps.23.1-3');
    expect(range, VerseRef.tryParse('Ps.23.1-3'));
  });

  test('bad references return null', () {
    for (final String bad in <String>['', 'John', 'John.3', 'John.x.1', 'John.0.1', '.3.16', 'Ps.23.5-2', 'Ps.23.1-2-3', 'Ps.23.0']) {
      expect(VerseRef.tryParse(bad), isNull, reason: bad);
    }
  });

  test('a verse is identified by language and place', () {
    const VerseRef ref = VerseRef(book: 'Ps', chapter: 23, verse: 1);
    const Verse en = Verse(ref: ref, language: 'en', text: 'a');
    const Verse enOther = Verse(ref: ref, language: 'en', text: 'b');
    const Verse es = Verse(ref: ref, language: 'es', text: 'a');
    expect(en.id, 'en:Ps.23.1');
    expect(en, enOther);
    expect(en == es, isFalse);
  });
}
