/// Where in the game a verse card appears (blueprint section 5). The verse
/// shown is chosen from the moment, the language and the race seed.
enum VerseMoment {
  trackIntro('track-intro'),
  win('win'),
  podium('podium'),
  encouragement('encouragement'),
  milestone('milestone'),
  daily('daily'),
  welcomeBack('welcome-back'),
  upgrade('upgrade');

  const VerseMoment(this.tag);

  /// The tag used in the verse data files. Never change an existing value.
  final String tag;

  static VerseMoment? fromTag(String tag) {
    for (final VerseMoment moment in VerseMoment.values) {
      if (moment.tag == tag) return moment;
    }
    return null;
  }
}

/// A language-independent place in the Bible: an OSIS book id, a chapter and
/// a verse or verse range, for example `John.3.16` or `Ps.23.1-3`. Per
/// language verse numbering differences are handled by the verse map in
/// `verse_repository.dart` (batch p2d), never here.
final class VerseRef {
  const VerseRef({
    required this.book,
    required this.chapter,
    required this.verse,
    int? endVerse,
  })  : endVerse = endVerse ?? verse,
        assert(chapter >= 1, 'chapters start at 1'),
        assert(verse >= 1, 'verses start at 1');

  /// Parses `Book.chapter.verse` or `Book.chapter.verse-end`. Returns null for
  /// anything else.
  static VerseRef? tryParse(String text) {
    final List<String> parts = text.split('.');
    if (parts.length != 3 || parts[0].isEmpty) return null;
    final int? chapter = int.tryParse(parts[1]);
    if (chapter == null || chapter < 1) return null;
    final List<String> verses = parts[2].split('-');
    if (verses.isEmpty || verses.length > 2) return null;
    final int? verse = int.tryParse(verses[0]);
    if (verse == null || verse < 1) return null;
    int end = verse;
    if (verses.length == 2) {
      final int? parsed = int.tryParse(verses[1]);
      if (parsed == null || parsed < verse) return null;
      end = parsed;
    }
    return VerseRef(
      book: parts[0],
      chapter: chapter,
      verse: verse,
      endVerse: end,
    );
  }

  /// OSIS book id, for example `Ps`.
  final String book;
  final int chapter;
  final int verse;

  /// The last verse of the range; equal to [verse] for a single verse.
  final int endVerse;

  bool get isRange => endVerse != verse;

  /// The stable key, for example `Ps.23.1-3`. Used in saved progress.
  String get key => isRange
      ? '$book.$chapter.$verse-$endVerse'
      : '$book.$chapter.$verse';

  @override
  bool operator ==(Object other) => other is VerseRef && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

/// One verse as shown on a card: its place, its text in one language, and the
/// moments it is curated for. Two verses are equal when the place and the
/// language are equal.
final class Verse {
  const Verse({
    required this.ref,
    required this.language,
    required this.text,
    this.moments = const <VerseMoment>{},
  });

  final VerseRef ref;

  /// App language code, for example `en` or `pt_BR`.
  final String language;

  final String text;
  final Set<VerseMoment> moments;

  /// Stable id for saved progress and the Verse library.
  String get id => '$language:${ref.key}';

  @override
  bool operator ==(Object other) => other is Verse && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Verse($id)';
}
