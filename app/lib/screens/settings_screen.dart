import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/config/app_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/language_names.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/app_segmented.dart';
import 'package:ruach/widgets/app_slider.dart';
import 'package:ruach/widgets/app_switch.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';

/// Opens a web or mail address. Supplied by the app shell.
typedef OpenUrl = Future<bool> Function(Uri uri);

/// Every preference, the purchase and consent rows, and the legal pages. A
/// row appears only when it can do something: Privacy choices only when the
/// consent platform says the region requires them, Tilt setup only while Tilt
/// is the chosen control.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onOpenUrl, this.banner});

  final OpenUrl? onOpenUrl;
  final Widget? banner;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _message;

  static const int _reminderStepMinutes = 15;

  void _note(String? text) {
    if (mounted) setState(() => _message = text);
  }

  Future<void> _setReminder(AppScope scope, AppLocalizations l, bool on) async {
    final bool ok = await scope.daily.setReminder(
      enabled: on,
      title: l.reminderTitle,
      body: l.reminderBody,
    );
    _note(on && !ok ? l.settingsReminderDenied : null);
  }

  Future<void> _setReminderTime(AppScope scope, AppLocalizations l, int minutes) async {
    await scope.settings.update(
      (Settings s) => s.copyWith(reminderHour: minutes ~/ 60, reminderMinute: minutes % 60),
    );
    if (scope.settings.value.remindersEnabled) await _setReminder(scope, l, true);
  }

  Future<void> _restore(AppScope scope, AppLocalizations l) async {
    final bool found = await scope.entitlement.restore();
    _note(found ? l.settingsRestoreDone : l.settingsRestoreNone);
  }

  void _open(Uri uri) {
    final OpenUrl? open = widget.onOpenUrl;
    if (open != null) unawaited(open(uri));
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        scope.settings,
        scope.locale,
        scope.consent,
        scope.entitlement,
        scope.ads,
      ]),
      builder: (BuildContext context, Widget? _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    final NavigatorState nav = Navigator.of(context);
    final Settings s = scope.settings.value;
    void update(Settings Function(Settings) change) => unawaited(scope.settings.update(change));
    void push(String route) => unawaited(nav.pushNamed(route));

    final bool bannerOn = scope.ads.bannersAllowed;
    final int reminderMinutes = s.reminderHour * 60 + s.reminderMinute;
    final bool adsRemoved = scope.entitlement.adsRemoved;
    final String privacyUrl = AppConfig.privacyUrl;

    return ScreenFrame(
      bannerHeight: bannerOn ? 50 : 0,
      banner: bannerOn ? widget.banner : null,
      navBar: NavBar(
        title: l.settingsTitle,
        onBack: () => unawaited(nav.maybePop()),
        backLabel: l.commonBack,
      ),
      children: <Widget>[
        if (_message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(_message!, style: theme.type.body.copyWith(color: theme.colors.textPrimary)),
            ),
          ),
        SectionHeader(l.settingsLanguage),
        AppRow(
          icon: AppIcons.language,
          label: l.settingsLanguage,
          subtitle: scope.locale.isOverridden
              ? LanguageNames.of(scope.locale.code)
              : l.settingsLanguageSystem,
          onTap: () => push(Routes.language),
        ),
        SectionHeader(l.settingsTheme),
        _pad(
          AppSegmented<ThemeChoice>(
            selected: s.themeChoice,
            onChanged: (ThemeChoice c) => unawaited(scope.theme.setChoice(c)),
            options: <SegmentOption<ThemeChoice>>[
              SegmentOption<ThemeChoice>(value: ThemeChoice.system, label: l.themeSystem),
              SegmentOption<ThemeChoice>(value: ThemeChoice.light, label: l.themeLight),
              SegmentOption<ThemeChoice>(value: ThemeChoice.dark, label: l.themeDark),
            ],
          ),
        ),
        SectionHeader(l.settingsControls),
        _pad(
          AppSegmented<ControlScheme>(
            selected: s.controlScheme,
            onChanged: (ControlScheme c) => update((Settings v) => v.copyWith(controlScheme: c)),
            options: <SegmentOption<ControlScheme>>[
              SegmentOption<ControlScheme>(value: ControlScheme.buttons, label: l.controlButtons),
              SegmentOption<ControlScheme>(value: ControlScheme.dragSteer, label: l.controlDrag),
              SegmentOption<ControlScheme>(value: ControlScheme.tilt, label: l.controlTilt),
            ],
          ),
        ),
        if (s.controlScheme == ControlScheme.tilt)
          AppRow(
            icon: AppIcons.tilt,
            label: l.settingsTiltSetup,
            onTap: () => push(Routes.tiltCalibration),
          ),
        _labelled(
          theme,
          l.settingsHandedness,
          AppSegmented<Handedness>(
            selected: s.handedness,
            onChanged: (Handedness h) => update((Settings v) => v.copyWith(handedness: h)),
            options: <SegmentOption<Handedness>>[
              SegmentOption<Handedness>(value: Handedness.right, label: l.handRight),
              SegmentOption<Handedness>(value: Handedness.left, label: l.handLeft),
            ],
          ),
        ),
        _switchRow(
          l.settingsOneHanded,
          s.oneHandedLayout,
          (bool v) => update((Settings x) => x.copyWith(oneHandedLayout: v)),
        ),
        SectionHeader(l.settingsSoundHeader),
        _switchRow(
          l.settingsSoundEffects,
          s.soundEnabled,
          (bool v) => update((Settings x) => x.copyWith(soundEnabled: v)),
        ),
        if (s.soundEnabled)
          _slider(
            theme,
            l.settingsEffectsVolume,
            s.effectsVolume,
            l,
            (double v) => update((Settings x) => x.copyWith(effectsVolume: v)),
          ),
        _switchRow(
          l.settingsMusic,
          s.musicEnabled,
          (bool v) => update((Settings x) => x.copyWith(musicEnabled: v)),
        ),
        if (s.musicEnabled)
          _slider(
            theme,
            l.settingsMusicVolume,
            s.musicVolume,
            l,
            (double v) => update((Settings x) => x.copyWith(musicVolume: v)),
          ),
        _switchRow(
          l.settingsHaptics,
          s.hapticsEnabled,
          (bool v) => update((Settings x) => x.copyWith(hapticsEnabled: v)),
        ),
        SectionHeader(l.settingsReminders),
        _switchRow(
          l.settingsReminders,
          s.remindersEnabled,
          (bool v) => unawaited(_setReminder(scope, l, v)),
        ),
        if (s.remindersEnabled)
          _labelled(
            theme,
            l.settingsReminderTime,
            AppSlider(
              value: reminderMinutes.toDouble(),
              min: 0,
              max: 24 * 60 - _reminderStepMinutes.toDouble(),
              divisions: (24 * 60) ~/ _reminderStepMinutes - 1,
              semanticLabel: l.settingsReminderTime,
              valueLabel: formatClock(s.reminderHour, s.reminderMinute),
              onChanged: (double v) => unawaited(_setReminderTime(scope, l, v.round())),
            ),
            value: formatClock(s.reminderHour, s.reminderMinute),
          ),
        SectionHeader(l.settingsRemoveAds),
        AppRow(
          icon: AppIcons.removeAds,
          label: l.settingsRemoveAds,
          subtitle: adsRemoved ? l.settingsAdsRemoved : null,
          onTap: () => push(Routes.upgrade),
        ),
        AppRow(
          icon: AppIcons.restorePurchase,
          label: l.settingsRestore,
          onTap: () => unawaited(_restore(scope, l)),
        ),
        if (scope.consent.value.privacyOptionsRequired)
          AppRow(
            icon: AppIcons.privacy,
            label: l.settingsPrivacyChoices,
            onTap: () => unawaited(scope.consent.showPrivacyOptions()),
          ),
        SectionHeader(l.settingsAbout),
        AppRow(
          icon: AppIcons.support,
          label: l.settingsSupport,
          onTap: () => _open(Uri(scheme: 'mailto', path: AppConfig.supportEmail)),
        ),
        if (privacyUrl.isNotEmpty)
          AppRow(
            icon: AppIcons.privacy,
            label: l.settingsPrivacyPolicy,
            onTap: () => _open(Uri.parse(privacyUrl)),
          ),
        AppRow(
          icon: AppIcons.licenses,
          label: l.settingsLicenses,
          onTap: () => push(Routes.licenses),
        ),
      ],
    );
  }

  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: child,
      );

  Widget _labelled(AppThemeData theme, String label, Widget child, {String? value}) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(label, style: theme.type.footnote.copyWith(color: theme.colors.textSecondary)),
                ),
                if (value != null)
                  Text(value, style: theme.type.footnote.copyWith(color: theme.colors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            child,
          ],
        ),
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) => AppRow(
        label: label,
        trailing: AppSwitch(value: value, onChanged: onChanged, semanticLabel: label),
      );

  Widget _slider(
    AppThemeData theme,
    String label,
    double value,
    AppLocalizations l,
    ValueChanged<double> onChanged,
  ) {
    final int percent = (value * 100).round();
    return _labelled(
      theme,
      label,
      AppSlider(
        value: value,
        semanticLabel: label,
        valueLabel: l.settingsPercent(percent),
        divisions: 20,
        onChanged: onChanged,
      ),
      value: l.settingsPercent(percent),
    );
  }
}
