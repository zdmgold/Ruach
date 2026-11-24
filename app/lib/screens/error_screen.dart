import 'package:flutter/widgets.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/widgets/error_view.dart';

/// The full-screen fallback for an unexpected error, with the app's own words
/// around the shared [ErrorView]. Reporting (an email with the local log) is
/// offered only when the shell supplies [onReport].
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({required this.onRetry, super.key, this.onReport});

  final VoidCallback onRetry;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return ColoredBox(
      color: AppTheme.of(context).colors.bgPrimary,
      child: ErrorView(
        title: l.errorTitle,
        message: l.errorMessage,
        retryLabel: l.errorRetry,
        onRetry: onRetry,
        reportLabel: onReport == null ? null : l.errorReport,
        onReport: onReport,
      ),
    );
  }
}
