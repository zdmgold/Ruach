import 'package:flutter/foundation.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/logic/star_rules.dart';
import 'package:ruach/core/models/app_error.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/ports/device_ports.dart';

/// The player's saved game. Every change shows at once and is saved after
/// (atomic write with a backup, see `ProgressRepository`). If a save fails the
/// game keeps working in memory, [saveError] shows a warning, and the next
/// change tries again.
final class ProgressProvider extends ValueNotifier<Progress> {
  ProgressProvider(this._repository, {LogPort? log})
      : _log = log,
        super(Progress.fresh());

  final ProgressRepository _repository;
  final LogPort? _log;

  Future<void> _tail = Future<void>.value();
  ProgressOrigin _origin = ProgressOrigin.firstRun;
  bool _noticeDismissed = false;

  /// The latest save failure, or null when the last save worked.
  final ValueNotifier<AppError?> saveError = ValueNotifier<AppError?>(null);

  ProgressOrigin get origin => _origin;

  /// True when saved progress came from a newer app and is read-only.
  bool get readOnly => _repository.readOnly;

  /// True until the player dismisses the one-time "restored from backup" or
  /// "started fresh" notice.
  bool get hasNotice => !_noticeDismissed && (_origin == ProgressOrigin.backup || _origin == ProgressOrigin.startedClean);

  /// Loads the saved game. Never throws.
  Future<void> load() async {
    final ProgressLoad loaded = await _repository.load();
    _origin = loaded.origin;
    _noticeDismissed = false;
    value = loaded.progress;
    if (loaded.needsNotice) _log?.log('progress: ${loaded.origin.name}');
    if (loaded.readOnly) _log?.log('progress: newer schema, read-only');
    notifyListeners();
  }

  void dismissNotice() {
    _noticeDismissed = true;
    notifyListeners();
  }

  /// Applies [change] and saves.
  Future<void> change(Progress Function(Progress current) change) {
    value = change(value);
    return _enqueueSave();
  }

  /// Records [stars] for [key] (see `StarRules.starKey`). Returns the Gifts
  /// earned, which is only the improvement over the best so far.
  Future<int> awardStars(String key, int stars) async {
    final int before = value.giftsEarned;
    await change((Progress p) => StarRules.award(p, key, stars));
    return value.giftsEarned - before;
  }

  /// Completes when every earlier save has finished.
  Future<void> flush() => _tail;

  Future<void> _enqueueSave() {
    final Progress snapshot = value;
    _tail = _tail.then((_) async {
      final AppError? error = await _repository.save(snapshot);
      saveError.value = error;
      if (error != null) _log?.log('progress save failed: ${error.detail}');
    });
    return _tail;
  }

  @override
  void dispose() {
    saveError.dispose();
    super.dispose();
  }
}
