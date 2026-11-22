import 'package:flutter/foundation.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/providers/settings_provider.dart';

/// Light, dark or follow-the-device, persisted through the settings. The
/// default is light-leaning only in that "system" is the default choice.
final class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._settings) : _choice = _settings.value.themeChoice {
    _settings.addListener(_onSettings);
  }

  final SettingsProvider _settings;
  ThemeChoice _choice;

  ThemeChoice get choice => _choice;

  Future<void> setChoice(ThemeChoice choice) =>
      _settings.update((Settings s) => s.copyWith(themeChoice: choice));

  /// True when the dark palette should be used, given whether the device is
  /// currently dark.
  bool isDark({required bool deviceIsDark}) => switch (_choice) {
        ThemeChoice.system => deviceIsDark,
        ThemeChoice.light => false,
        ThemeChoice.dark => true,
      };

  void _onSettings() {
    if (_settings.value.themeChoice != _choice) {
      _choice = _settings.value.themeChoice;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }
}
