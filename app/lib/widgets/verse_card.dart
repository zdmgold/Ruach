import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';

/// One verse with its reference, on the verse surface. It appears only on
/// screens outside the race. The verse text is in the player's app language;
/// the reference is formatted for that language by the caller.
class VerseCard extends StatelessWidget {
  const VerseCard({
    required this.text,
    required this.reference,
    super.key,
    this.onShare,
    this.shareLabel,
    this.onReadChapter,
    this.readLabel,
  })  : assert(onShare == null || shareLabel != null, 'Share needs a label'),
        assert(onReadChapter == null || readLabel != null, 'Read chapter needs a label');

  final String text;
  final String reference;

  /// Shows a Share action when set.
  final VoidCallback? onShare;
  final String? shareLabel;

  /// Shows a Read chapter action when set (once the reader ships).
  final VoidCallback? onReadChapter;
  final String? readLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final bool hasActions = onShare != null || onReadChapter != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.verseCardSurface,
        borderRadius: BorderRadius.circular(AppRadii.hero),
        border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(text, style: theme.type.body),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    reference,
                    style: theme.type.footnote.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (hasActions) ...<Widget>[
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: <Widget>[
                  if (onShare != null)
                    AppChip(label: shareLabel!, icon: AppIcons.share, onTap: onShare),
                  if (onReadChapter != null)
                    AppChip(label: readLabel!, icon: AppIcons.verse, onTap: onReadChapter),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
