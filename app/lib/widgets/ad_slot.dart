import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';

/// Holds the banner at the bottom of a menu screen. When there is no ad
/// (loading, failed, removed, switched off) or the keyboard is open, the gap,
/// the border and the height are all zero: no empty box is ever drawn.
///
/// The screen decides whether an ad is allowed (`AdProvider.bannersAllowed`)
/// and passes the loaded banner widget, or null.
class AdSlot extends StatelessWidget {
  const AdSlot({required this.height, super.key, this.ad});

  /// The banner widget, or null when there is none to show.
  final Widget? ad;

  /// The adaptive banner height, as the ad port reports it.
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = (MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0) > 0;
    if (ad == null || height <= 0 || keyboardOpen) return const SizedBox.shrink();
    final AppThemeData theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colors.border, width: AppStroke.hairline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Center(child: ad),
        ),
      ),
    );
  }
}
