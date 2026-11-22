import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/primary_button.dart';

/// The full-screen fallback for a fatal error: what happened in plain words,
/// Retry, and an optional way to email the log. It draws on the plain screen
/// background and needs nothing else to work, so it can show even when most
/// of the app has failed.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    super.key,
    this.reportLabel,
    this.onReport,
  }) : assert(onReport == null || reportLabel != null, 'Report needs a label');

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? reportLabel;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return ColoredBox(
      color: theme.colors.bgPrimary,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppIcon(AppIcons.warning, size: AppIconSizes.hero, color: theme.colors.warning),
                  const SizedBox(height: AppSpacing.s16),
                  Semantics(
                    header: true,
                    child: Text(title, textAlign: TextAlign.center, style: theme.type.title1),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(message, textAlign: TextAlign.center, style: theme.type.body),
                  const SizedBox(height: AppSpacing.s24),
                  PrimaryButton(label: retryLabel, icon: AppIcons.restart, onPressed: onRetry),
                  if (onReport != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.s16),
                    AppChip(label: reportLabel!, icon: AppIcons.support, onTap: onReport),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
