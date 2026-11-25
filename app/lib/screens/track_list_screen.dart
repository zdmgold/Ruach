import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/star_rules.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/app_switch.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/pressable.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';
import 'package:ruach/widgets/star_badge.dart';

/// The tracks of one mode, grouped by era. Journey shows every track in
/// order (locked ones too, so the road ahead is visible) with a Then/Now
/// switch; the other modes list only the tracks that are open.
class TrackListScreen extends StatefulWidget {
  const TrackListScreen({required this.mode, super.key, this.banner});

  final RaceMode mode;
  final Widget? banner;

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  bool _now = false;

  bool get _isJourney => widget.mode == RaceMode.journey;

  List<String> _ids() {
    if (_isJourney) {
      return _now
          ? <String>[
              for (final String id in TrackIds.journey.take(12)) TrackIds.nowVariantOf(id),
            ]
          : TrackIds.journey;
    }
    return TrackIds.all;
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[scope.progress, scope.ads, scope.settings]),
      builder: (BuildContext context, Widget? _) {
        final Progress progress = scope.progress.value;
        final List<String> ids = _ids().where((String id) {
          return _isJourney || Unlocks.track(id, progress);
        }).toList();
        final bool bannerOn = scope.ads.bannersAllowed;
        final List<Widget> children = <Widget>[];
        if (_isJourney) children.add(_toggle(l));
        if (widget.mode == RaceMode.timeTrial) {
          children.add(
            AppRow(
              label: l.ghostShow,
              trailing: AppSwitch(
                value: scope.settings.value.ghostEnabled,
                semanticLabel: l.ghostShow,
                onChanged: (bool v) => unawaited(
                  scope.settings.update((Settings x) => x.copyWith(ghostEnabled: v)),
                ),
              ),
            ),
          );
        }
        Era? era;
        for (final String id in ids) {
          final Track track = TrackCatalog.byId(id)!;
          if (track.era != era) {
            era = track.era;
            children.add(SectionHeader(eraName(l, track.era)));
          }
          children.add(_row(context, l, progress, id));
        }
        return ScreenFrame(
          bannerHeight: bannerOn ? 50 : 0,
          banner: bannerOn ? widget.banner : null,
          navBar: NavBar(
            title: modeName(l, widget.mode),
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l.commonBack,
          ),
          children: children,
        );
      },
    );
  }

  Widget _toggle(AppLocalizations l) {
    Widget chip(String label, bool selected, bool now) => Pressable(
          onTap: () => setState(() => _now = now),
          semanticLabel: label,
          builder: (BuildContext context, bool pressed) => AppChip(
            label: label,
            tone: selected ? ChipTone.accent : ChipTone.neutral,
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
      child: Row(
        children: <Widget>[
          chip(l.variantThen, !_now, false),
          const SizedBox(width: AppSpacing.s8),
          chip(l.variantNow, _now, true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l, Progress progress, String id) {
    final bool open = Unlocks.track(id, progress);
    final String name = trackName(l, id);
    if (!open) {
      return AppRow(icon: AppIcons.locked, label: name, subtitle: l.commonLocked);
    }
    final int stars = progress.starsOn(StarRules.starKey(widget.mode, id));
    final int? best = widget.mode == RaceMode.timeTrial ? progress.bestLapMillis[id] : null;
    return AppRow(
      icon: AppIcons.play,
      label: name,
      subtitle: best == null
          ? null
          : l.trackListBestLap(formatLapTime(Duration(milliseconds: best))),
      trailing: stars > 0 ? StarBadge(stars: stars, semanticLabel: l.starsEarned(stars)) : null,
      onTap: () => unawaited(
        Navigator.of(context).pushNamed(
          Routes.trackIntro,
          arguments: TrackIntroArgs(mode: widget.mode, trackId: id),
        ),
      ),
    );
  }
}
