import 'package:ruach/core/models/verse.dart';

/// Per-language verse numbering. Verses are keyed everywhere by canonical
/// references (the numbering the curated data and the cards use). A source
/// text may number a few chapters differently (Psalm titles, Joel, Malachi);
/// this map translates between the two so a card in any language opens the
/// right chapter in the reader.
///
/// The default is the identity. The reader's data (batch p8a) fills in the
/// differences per language from the full texts.
final class VerseMap {
  VerseMap(this.language, Map<String, VerseRef> overrides)
      : _toLocal = Map<String, VerseRef>.unmodifiable(overrides),
        _toCanonical = <String, VerseRef>{
          for (final MapEntry<String, VerseRef> e in overrides.entries)
            if (VerseRef.tryParse(e.key) case final VerseRef canonical)
              e.value.key: canonical,
        };

  /// No differences.
  factory VerseMap.identity(String language) =>
      VerseMap(language, const <String, VerseRef>{});

  /// Reads `{ "Ps.51.1": "Ps.51.3", ... }` (canonical single verse to local
  /// reference). Entries that do not parse are skipped; it never throws.
  factory VerseMap.fromJson(String language, Object? json) {
    final Map<String, VerseRef> overrides = <String, VerseRef>{};
    if (json is Map<Object?, Object?>) {
      json.forEach((Object? key, Object? value) {
        if (key is! String || value is! String) return;
        final VerseRef? from = VerseRef.tryParse(key);
        final VerseRef? to = VerseRef.tryParse(value);
        if (from == null || to == null || from.isRange || to.isRange) return;
        overrides[from.key] = to;
      });
    }
    return VerseMap(language, overrides);
  }

  final String language;
  final Map<String, VerseRef> _toLocal;
  final Map<String, VerseRef> _toCanonical;

  bool get isIdentity => _toLocal.isEmpty;

  /// The local reference for a canonical one. A range is mapped at both ends;
  /// if the ends land in different chapters only the first verse is kept.
  VerseRef toLocal(VerseRef canonical) {
    final VerseRef start = _single(_toLocal, canonical.book, canonical.chapter, canonical.verse);
    if (!canonical.isRange) return start;
    final VerseRef end = _single(_toLocal, canonical.book, canonical.chapter, canonical.endVerse);
    if (end.book != start.book || end.chapter != start.chapter || end.verse < start.verse) {
      return start;
    }
    return VerseRef(book: start.book, chapter: start.chapter, verse: start.verse, endVerse: end.verse);
  }

  /// The canonical reference for a local one; the reverse of [toLocal].
  VerseRef toCanonical(VerseRef local) {
    final VerseRef start = _single(_toCanonical, local.book, local.chapter, local.verse);
    if (!local.isRange) return start;
    final VerseRef end = _single(_toCanonical, local.book, local.chapter, local.endVerse);
    if (end.book != start.book || end.chapter != start.chapter || end.verse < start.verse) {
      return start;
    }
    return VerseRef(book: start.book, chapter: start.chapter, verse: start.verse, endVerse: end.verse);
  }

  static VerseRef _single(Map<String, VerseRef> table, String book, int chapter, int verse) =>
      table['$book.$chapter.$verse'] ?? VerseRef(book: book, chapter: chapter, verse: verse);
}
