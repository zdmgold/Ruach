import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ruach/core/logic/locale_rules.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/language_names.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/empty_state.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';

/// One notice: who it credits and the full text.
final class LicenseNotice {
  const LicenseNotice({required this.title, required this.text});

  final String title;
  final String text;
}

/// Reads a bundled text file.
typedef LoadText = Future<String> Function(String path);

/// Reads the licences Flutter collected from the packages in the app.
typedef LoadPackageNotices = Future<List<LicenseNotice>> Function();

Future<List<LicenseNotice>> flutterPackageNotices() async {
  final Map<String, StringBuffer> byPackage = <String, StringBuffer>{};
  await for (final LicenseEntry entry in LicenseRegistry.licenses) {
    final String text = entry.paragraphs.map((LicenseParagraph p) => p.text).join('\n');
    for (final String package in entry.packages) {
      (byPackage[package] ??= StringBuffer()).writeln('$text\n');
    }
  }
  final List<String> names = byPackage.keys.toList()..sort();
  return <LicenseNotice>[
    for (final String n in names) LicenseNotice(title: n, text: byPackage[n].toString().trim()),
  ];
}

/// Every notice the app owes: each scripture translation's credit, the
/// bundled font and icons, and the software packages. Notices expand when
/// tapped, so the list stays short enough to scan.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key, this.loadText, this.loadPackages});

  final LoadText? loadText;
  final LoadPackageNotices? loadPackages;

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  Future<_Notices>? _future;
  final Set<String> _open = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load(AppLocalizations.of(context));
  }

  Future<_Notices> _load(AppLocalizations l) async {
    final LoadText read = widget.loadText ?? rootBundle.loadString;
    final List<LicenseNotice> scripture = <LicenseNotice>[];
    for (final String code in LocaleRules.supported) {
      scripture.add(
        LicenseNotice(
          title: LanguageNames.of(code),
          text: await read('assets/notices/scripture-$code.txt'),
        ),
      );
    }
    final List<LicenseNotice> software = <LicenseNotice>[
      LicenseNotice(title: l.licenseBarlow, text: await read('assets/notices/barlow-OFL.txt')),
      LicenseNotice(title: l.licensePhosphor, text: await read('assets/notices/phosphor-MIT.txt')),
      ...await (widget.loadPackages ?? flutterPackageNotices)(),
    ];
    return _Notices(scripture, software);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return FutureBuilder<_Notices>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<_Notices> snapshot) {
        final _Notices? n = snapshot.data;
        return ScreenFrame(
          navBar: NavBar(
            title: l.licensesTitle,
            onBack: () => unawaited(Navigator.of(context).maybePop()),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s48),
                child: EmptyState(icon: AppIcons.licenses, title: l.licensesLoadFailed),
              ),
            if (n != null) ...<Widget>[
              SectionHeader(l.licensesScripture),
              for (final LicenseNotice x in n.scripture) ..._notice(theme, 's:${x.title}', x),
              SectionHeader(l.licensesSoftware),
              for (final LicenseNotice x in n.software) ..._notice(theme, 'p:${x.title}', x),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _notice(AppThemeData theme, String id, LicenseNotice n) {
    final bool open = _open.contains(id);
    return <Widget>[
      AppRow(
        label: n.title,
        onTap: () => setState(() => open ? _open.remove(id) : _open.add(id)),
      ),
      if (open)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16),
          child: Text(n.text, style: theme.type.footnote.copyWith(color: theme.colors.textSecondary)),
        ),
    ];
  }
}

final class _Notices {
  const _Notices(this.scripture, this.software);

  final List<LicenseNotice> scripture;
  final List<LicenseNotice> software;
}
