import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/race_result.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/gift_badge.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/primary_button.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/star_badge.dart';

/// After a race: stars, Gifts, a verse, and the ways to go on. The result is
/// saved once when the screen opens; an interstitial may follow the save.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, this.onShare});

  final ShareText? onShare;

  /// How much of the Ruach meter the "start with extra boost" reward fills.
  static const double rewardedStartingBoost = 0.5;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _started = false;
  bool _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_save(AppScope.of(context)));
  }

  Future<void> _save(AppScope scope) async {
    await scope.race.commit();
    if (!mounted) return;
    setState(() => _saved = true);
    final RaceResult? result = scope.race.result;
    final bool dailyAfterFirst =
        result?.mode == RaceMode.dailyRun && scope.daily.attemptsToday >= 1;
    await scope.ads.maybeShowInterstitial(afterFirstDailyAttempt: dailyAfterFirst);
  }

  VerseMoment _moment(RaceResult r) {
    if (r.playerWon) return VerseMoment.win;
    if (r.player.finished && r.playerPosition <= 3) return VerseMoment.podium;
    return VerseMoment.encouragement;
  }

  void _home() => Navigator.of(context).popUntil((Route<void> r) => r.isFirst);

  void _again(RaceResult r) => unawaited(
        Navigator.of(context).pushReplacementNamed(
          Routes.trackIntro,
          arguments: TrackIntroArgs(mode: r.mode, trackId: r.trackId),
        ),
      );

  void _next(String trackId) => unawaited(
        Navigator.of(context).pushReplacementNamed(
          Routes.trackIntro,
          arguments: TrackIntroArgs(mode: RaceMode.journey, trackId: trackId),
        ),
      );

  Future<void> _boosted(AppScope scope, RaceConfig config) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool earned = await scope.ads.showRewarded();
    if (!earned || !mounted) return;
    unawaited(
      navigator.pushReplacementNamed(
        Routes.race,
        arguments: RaceArgs(
          config: config,
          wind: Vec2.zero,
          startingBoost: ResultScreen.rewardedStartingBoost,
        ),
      ),
    );
  }

  /// The next Journey track after [trackId], if there is one and it is open.
  String? _nextTrack(AppScope scope, RaceResult r) {
    if (r.mode != RaceMode.journey || r.stars == 0) return null;
    final int i = TrackIds.journey.indexOf(r.trackId);
    if (i < 0 || i + 1 >= TrackIds.journey.length) return null;
    final String next = TrackIds.journey[i + 1];
    return Unlocks.track(next, scope.progress.value) ? next : null;
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    final RaceProvider race = scope.race;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[race, scope.ads, scope.progress]),
      builder: (BuildContext context, Widget? _) {
        final RaceResult? r = race.result;
        final NavBar navBar = NavBar(
          title: l.appName,
          onBack: _home,
          backLabel: l.resultHome,
        );
        if (r == null) {
          return ScreenFrame(navBar: navBar, children: const <Widget>[]);
        }
        final bool escape = r.mode == RaceMode.escapeRun;
        final int gifts = race.giftsGained;
        final String? next = _saved ? _nextTrack(scope, r) : null;
        final Duration? best = r.player.bestLap;
        final String headline = r.playerWon
            ? l.resultWon
            : (r.player.finished && r.playerPosition <= 3 ? l.resultPodium : l.resultFinished);
        final RaceConfig? config = race.simulation?.config;
        final bool canBoost = _saved &&
            config != null &&
            r.mode != RaceMode.dailyRun &&
            scope.ads.rewardedReady;
        return ScreenFrame(
          bannerHeight: scope.ads.bannersAllowed ? 50 : 0,
          navBar: navBar,
          children: <Widget>[
            const SizedBox(height: AppSpacing.s24),
            Center(
              child: Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.type.title1.copyWith(color: theme.colors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Center(
              child: StarBadge(
                stars: r.stars,
                semanticLabel: l.starsEarned(r.stars),
                size: AppIconSizes.hero,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: <Widget>[
                  if (escape)
                    AppChip(label: l.resultEscapeDistance(race.escapeMetres.floor()))
                  else
                    AppChip(
                      label: l.resultPosition(r.playerPosition, r.standings.length),
                      tone: ChipTone.accent,
                    ),
                  if (best != null) AppChip(label: l.resultTime(formatLapTime(best))),
                  if (gifts > 0)
                    GiftBadge(count: gifts, semanticLabel: l.giftCountSemantic(gifts)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            VerseBlock(
              load: () => scope.verses.pick(_moment(r), seed: r.seed),
              onShare: widget.onShare,
            ),
            const SizedBox(height: AppSpacing.s24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (next != null)
                    PrimaryButton(label: l.resultNextTrack, onPressed: () => _next(next)),
                  if (next != null) const SizedBox(height: AppSpacing.s8),
                  if (next == null)
                    PrimaryButton(label: l.resultRaceAgain, onPressed: () => _again(r))
                  else
                    AppRow(label: l.resultRaceAgain, onTap: () => _again(r)),
                  if (canBoost)
                    AppRow(
                      icon: AppIcons.boost,
                      label: l.resultBoostStart,
                      onTap: () => unawaited(_boosted(scope, config)),
                    ),
                  AppRow(label: l.resultHome, onTap: _home),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
