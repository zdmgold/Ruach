import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/daily_seed.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/primary_button.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/star_badge.dart';

/// Before a race: the track, its verse, the vehicle and the start button.
/// The Daily Run's second and later attempts of a day are "extra": they ask
/// for a rewarded video, unless the player has Remove Ads.
class TrackIntroScreen extends StatefulWidget {
  const TrackIntroScreen({
    required this.mode,
    required this.trackId,
    super.key,
    this.onShare,
  });

  final RaceMode mode;
  final String trackId;
  final ShareText? onShare;

  @override
  State<TrackIntroScreen> createState() => _TrackIntroScreenState();
}

class _TrackIntroScreenState extends State<TrackIntroScreen> {
  final int _seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  bool _busy = false;
  bool _videoUnavailable = false;

  bool get _isDaily => widget.mode == RaceMode.dailyRun;

  RaceConfig _config(AppScope scope) {
    final Track track = TrackCatalog.byId(widget.trackId)!;
    if (_isDaily) {
      final DailyChallenge c = scope.daily.challenge;
      return ModeRules.build(
        mode: widget.mode,
        track: track,
        vehicle: VehicleCatalog.byId(c.vehicleId)!,
        roster: RivalCatalog.all,
        seed: c.seed,
        laps: c.laps,
      );
    }
    return ModeRules.build(
      mode: widget.mode,
      track: track,
      vehicle: scope.garage.selected,
      roster: RivalCatalog.all,
      seed: _seed,
      upgrades: scope.garage.levels,
    );
  }

  Future<void> _start(AppScope scope) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _videoUnavailable = false;
    });
    final NavigatorState navigator = Navigator.of(context);
    if (_isDaily && scope.daily.nextAttemptIsExtra && !scope.entitlement.adsRemoved) {
      final bool earned = await scope.ads.showRewarded();
      if (!earned) {
        if (mounted) {
          setState(() {
            _busy = false;
            _videoUnavailable = true;
          });
        }
        return;
      }
    }
    final RaceConfig config = _config(scope);
    if (_isDaily) await scope.daily.startAttempt();
    if (!mounted) return;
    setState(() => _busy = false);
    unawaited(
      navigator.pushNamed(
        Routes.race,
        arguments: RaceArgs(
          config: config,
          wind: _isDaily ? scope.daily.challenge.wind : Vec2.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[scope.progress, scope.garage, scope.daily]),
      builder: (BuildContext context, Widget? _) {
        final RaceConfig config = _config(scope);
        final Vehicle vehicle = config.vehicle;
        final int stars = scope.progress.value.starsOn(widget.trackId);
        final int? bestMillis = scope.progress.value.bestLapMillis[widget.trackId];
        final bool escape = widget.mode == RaceMode.escapeRun;
        final bool extra = _isDaily && scope.daily.nextAttemptIsExtra && !scope.entitlement.adsRemoved;
        return ScreenFrame(
          navBar: NavBar(
            title: trackName(l, widget.trackId),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            const SizedBox(height: AppSpacing.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: <Widget>[
                  AppChip(label: eraName(l, config.track.era), tone: ChipTone.accent),
                  if (!escape) AppChip(label: l.introLaps(config.laps)),
                  if (config.rivals.isNotEmpty) AppChip(label: l.introRivals(config.rivals.length)),
                  if (bestMillis != null)
                    AppChip(label: l.introBestLap(formatLapTime(Duration(milliseconds: bestMillis)))),
                  if (escape && scope.progress.value.escapeRunBestMetres > 0)
                    AppChip(label: l.introEscapeBest(scope.progress.value.escapeRunBestMetres)),
                ],
              ),
            ),
            if (stars > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StarBadge(stars: stars, semanticLabel: l.starsEarned(stars)),
                ),
              ),
            const SizedBox(height: AppSpacing.s16),
            VerseBlock(
              load: () => scope.verses.trackIntro(config.track.id),
              onShare: widget.onShare,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppRow(
              icon: AppIcons.vehicle,
              label: l.introChooseVehicle,
              subtitle: vehicleName(l, vehicle.kind),
              onTap: _isDaily
                  ? null
                  : () => unawaited(Navigator.of(context).pushNamed(Routes.garage)),
            ),
            if (_videoUnavailable)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Text(
                  l.introExtraUnavailable,
                  style: theme.type.body.copyWith(color: theme.colors.textSecondary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: PrimaryButton(
                label: extra ? l.introExtraAttempt : l.introStart,
                icon: extra ? AppIcons.play : null,
                onPressed: _busy ? null : () => unawaited(_start(scope)),
              ),
            ),
          ],
        );
      },
    );
  }
}
