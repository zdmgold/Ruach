import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/models/json_read.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/core/ports/verse_source.dart';

/// One language's curated verses.
final class VerseBundle {
  VerseBundle(this.language, List<Verse> verses)
      : verses = List<Verse>.unmodifiable(
          List<Verse>.of(verses)..sort((Verse a, Verse b) => a.ref.key.compareTo(b.ref.key)),
        ) {
    for (final Verse v in this.verses) {
      _byRef[v.ref.key] = v;
      for (final VerseMoment m in v.moments) {
        (_byMoment[m] ??= <Verse>[]).add(v);
      }
    }
  }

  /// Reads a decoded bundle (`{language, schema, source, verses: [...]}`).
  /// Entries without a valid reference or text are skipped. Never throws.
  factory VerseBundle.fromJson(String language, Object? json) {
    final Map<String, Object?> m = asJsonMap(json);
    final List<Verse> verses = <Verse>[];
    for (final Object? item in asJsonList(m['verses'])) {
      final Map<String, Object?> v = asJsonMap(item);
      final VerseRef? ref = VerseRef.tryParse(readString(v['ref'], ''));
      final String text = readString(v['text'], '');
      if (ref == null || text.isEmpty) continue;
      final Set<VerseMoment> moments = <VerseMoment>{
        for (final Object? tag in asJsonList(v['moments']))
          if (tag is String && VerseMoment.fromTag(tag) != null) VerseMoment.fromTag(tag)!,
      };
      verses.add(Verse(ref: ref, language: language, text: text, moments: moments));
    }
    return VerseBundle(language, verses);
  }

  final String language;

  /// Sorted by reference key, so the order is the same in every language.
  final List<Verse> verses;
  final Map<String, Verse> _byRef = <String, Verse>{};
  final Map<VerseMoment, List<Verse>> _byMoment = <VerseMoment, List<Verse>>{};

  bool get isEmpty => verses.isEmpty;

  Verse? byRef(VerseRef ref) => _byRef[ref.key];

  /// The verses curated for [moment], in reference order.
  List<Verse> forMoment(VerseMoment moment) =>
      List<Verse>.unmodifiable(_byMoment[moment] ?? const <Verse>[]);
}

/// Chooses verses for the cards and the Verse library.
///
/// The choice depends only on the moment, the seed and what has been seen, so
/// the same result always shows the same verse. Because every language holds
/// the same references in the same order, the same seed picks the same verse
/// in every language.
final class VerseRepository {
  VerseRepository(this._source, {this.fallbackLanguage = 'en'});

  final VerseDataSource _source;

  /// Used when a language's bundle is missing or unreadable.
  final String fallbackLanguage;

  final Map<String, VerseBundle> _cache = <String, VerseBundle>{};

  /// The bundle for [language], or the fallback language's if that one cannot
  /// be read. Returns an empty bundle only if both fail.
  Future<VerseBundle> bundle(String language) async {
    final VerseBundle? cached = _cache[language];
    if (cached != null) return cached;
    VerseBundle loaded = await _read(language);
    if (loaded.isEmpty && language != fallbackLanguage) {
      loaded = await _read(fallbackLanguage);
    }
    _cache[language] = loaded;
    return loaded;
  }

  Future<VerseBundle> _read(String language) async {
    try {
      return VerseBundle.fromJson(language, await _source.load(language));
    } on Object {
      return VerseBundle(language, const <Verse>[]);
    }
  }

  /// A verse for [moment]. Unseen verses (by reference, in any language) are
  /// preferred; when all have been seen, any is allowed. Returns null only if
  /// no verse is available for the moment.
  Future<Verse?> pick({
    required VerseMoment moment,
    required String language,
    required int seed,
    Set<String> seenIds = const <String>{},
  }) async {
    final VerseBundle b = await bundle(language);
    final List<Verse> all = b.forMoment(moment);
    if (all.isEmpty) return null;
    final Set<String> seenRefs = <String>{
      for (final String id in seenIds) _refPart(id),
    };
    final List<Verse> unseen = <Verse>[
      for (final Verse v in all)
        if (!seenRefs.contains(v.ref.key)) v,
    ];
    final List<Verse> pool = unseen.isEmpty ? all : unseen;
    final SeededRng rng = SeededRng(seed).fork('verse:${moment.tag}');
    return pool[rng.nextInt(pool.length)];
  }

  /// The verse at a specific reference, for example a track's intro verse.
  Future<Verse?> forRef(String language, VerseRef ref) async =>
      (await bundle(language)).byRef(ref);

  /// Looks up a saved id (`language:reference`) in the player's current
  /// language, so a verse seen in another language still opens.
  Future<Verse?> byId(String id, {String? language}) async {
    final int colon = id.indexOf(':');
    if (colon < 1) return null;
    final VerseRef? ref = VerseRef.tryParse(id.substring(colon + 1));
    if (ref == null) return null;
    return forRef(language ?? id.substring(0, colon), ref);
  }

  /// The player's seen verses in [language], in reference order, for the
  /// Verse library.
  Future<List<Verse>> library(String language, Set<String> seenIds) async {
    final VerseBundle b = await bundle(language);
    final Set<String> seenRefs = <String>{for (final String id in seenIds) _refPart(id)};
    return <Verse>[
      for (final Verse v in b.verses)
        if (seenRefs.contains(v.ref.key)) v,
    ];
  }

  static String _refPart(String id) {
    final int colon = id.indexOf(':');
    return colon < 0 ? id : id.substring(colon + 1);
  }
}
