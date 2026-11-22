import 'package:ruach/core/catalog/verse_moments.dart';
import 'package:ruach/core/logic/verse_repository.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/providers/locale_provider.dart';
import 'package:ruach/providers/progress_provider.dart';

/// Picks the verse for a moment in the player's language and remembers which
/// ones they have seen, so the library fills in and repeats come last.
final class VerseProvider {
  VerseProvider(this._repository, this._progress, this._locale);

  final VerseRepository _repository;
  final ProgressProvider _progress;
  final LocaleProvider _locale;

  /// A verse for [moment]. [seed] makes the choice repeatable (the Daily Run
  /// passes its verse seed). The verse is recorded as seen.
  Future<Verse?> pick(VerseMoment moment, {required int seed}) async {
    final Verse? v = await _repository.pick(
      moment: moment,
      language: _locale.code,
      seed: seed,
      seenIds: _progress.value.seenVerseIds,
    );
    if (v != null) await markSeen(v);
    return v;
  }

  /// The fixed intro verse of a track, recorded as seen.
  Future<Verse?> trackIntro(String trackId) async {
    final VerseRef? ref = VerseMoments.trackIntro(trackId);
    if (ref == null) return null;
    final Verse? v = await _repository.forRef(_locale.code, ref);
    if (v != null) await markSeen(v);
    return v;
  }

  Future<void> markSeen(Verse v) async {
    if (_progress.value.seenVerseIds.contains(v.id)) return;
    await _progress.change(
      (Progress p) => p.copyWith(seenVerseIds: <String>{...p.seenVerseIds, v.id}),
    );
  }

  /// The verses the player has seen, for the library screen.
  Future<List<Verse>> library() =>
      _repository.library(_locale.code, _progress.value.seenVerseIds);
}
