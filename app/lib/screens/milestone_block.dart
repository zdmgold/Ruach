import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/milestone_rules.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';

/// Shows the next milestone card that has not been celebrated yet, once: it
/// is marked seen the moment it appears and stays on screen until the screen
/// closes. Shows nothing while [enabled] is false or when none is due.
class MilestoneSlot extends StatefulWidget {
  const MilestoneSlot({super.key, this.enabled = true, this.onShare});

  final bool enabled;
  final ShareText? onShare;

  @override
  State<MilestoneSlot> createState() => _MilestoneSlotState();
}

class _MilestoneSlotState extends State<MilestoneSlot> {
  String? _shown;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.progress,
      builder: (BuildContext context, Widget? _) {
        if (_shown == null && widget.enabled) {
          final List<String> due = Milestones.due(scope.progress.value);
          if (due.isNotEmpty) {
            final String id = due.first;
            _shown = id;
            SchedulerBinding.instance.addPostFrameCallback(
              (_) => unawaited(scope.progress.markMilestonesSeen(<String>[id])),
            );
          }
        }
        final String? id = _shown;
        if (id == null) return const SizedBox.shrink();
        return _MilestoneCard(id: id, onShare: widget.onShare);
      },
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.id, this.onShare});

  final String id;
  final ShareText? onShare;

  String _title(AppLocalizations l) {
    final Era? era = Milestones.eraOf(id);
    if (era != null) return l.milestoneEra(eraName(l, era));
    final UpgradeKind? kind = Milestones.upgradeOf(id);
    if (kind != null) return l.milestoneMaxed(upgradeName(l, kind));
    return l.milestoneFirstGift;
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.s16),
        Semantics(
          header: true,
          child: Text(
            _title(l),
            textAlign: TextAlign.center,
            style: theme.type.title2.copyWith(color: theme.colors.accent),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        VerseBlock(
          key: ValueKey<String>(id),
          load: () => scope.verses.pick(VerseMoment.milestone, seed: Milestones.seedOf(id)),
          onShare: onShare,
        ),
      ],
    );
  }
}

/// The welcome-back card for a player who missed some days: a warm line and a
/// verse, shown once on a day. It is marked shown as it appears and stays
/// until the screen closes.
class WelcomeBackSlot extends StatefulWidget {
  const WelcomeBackSlot({super.key, this.onShare});

  final ShareText? onShare;

  @override
  State<WelcomeBackSlot> createState() => _WelcomeBackSlotState();
}

class _WelcomeBackSlotState extends State<WelcomeBackSlot> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    if (!_shown && scope.daily.welcomeBackPending) {
      _shown = true;
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => unawaited(scope.daily.markWelcomeBackShown()),
      );
    }
    if (!_shown) return const SizedBox.shrink();
    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.s16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  l.welcomeBackTitle,
                  style: theme.type.title2.copyWith(color: theme.colors.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                l.welcomeBackNote,
                style: theme.type.body.copyWith(color: theme.colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        VerseBlock(
          load: () => scope.verses.pick(
            VerseMoment.welcomeBack,
            seed: scope.daily.today.key.codeUnits.fold<int>(0, (int a, int c) => (a * 31 + c) & 0x7fffffff),
          ),
          onShare: widget.onShare,
        ),
      ],
    );
  }
}
