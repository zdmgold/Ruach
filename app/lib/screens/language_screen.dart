import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/locale_rules.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/language_names.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/screen_frame.dart';

/// Choose the app language, or follow the device. Each language is listed in
/// its own name.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: scope.locale,
      builder: (BuildContext context, Widget? _) {
        final bool overridden = scope.locale.isOverridden;
        final String current = scope.locale.code;
        return ScreenFrame(
          navBar: NavBar(
            title: l.settingsLanguage,
            onBack: () => unawaited(Navigator.of(context).maybePop()),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            AppRow(
              label: l.settingsLanguageSystem,
              trailing: overridden ? null : const _Chosen(),
              onTap: () => unawaited(scope.locale.setLanguage(null)),
            ),
            for (final String code in LocaleRules.supported)
              AppRow(
                label: LanguageNames.of(code),
                trailing: overridden && code == current ? const _Chosen() : null,
                onTap: () => unawaited(scope.locale.setLanguage(code)),
              ),
          ],
        );
      },
    );
  }
}

class _Chosen extends StatelessWidget {
  const _Chosen();

  @override
  Widget build(BuildContext context) => Semantics(
        selected: true,
        child: const AppIcon(AppIcons.check),
      );
}
