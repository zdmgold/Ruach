import 'package:ruach/core/models/json_read.dart';

/// How the player steers (blueprint section 2). Every scheme produces the same
/// `DriveInput`.
enum ControlScheme { halves, buttons, dragSteer, tilt }

/// Which side of the screen the main controls sit on.
enum Handedness { right, left }

/// The theme the player chose. `system` follows the device.
enum ThemeChoice { system, light, dark }

/// The player's preferences, kept in the key-value store. Immutable: change a
/// value with [copyWith].
final class Settings {
  const Settings({
    this.controlScheme = ControlScheme.halves,
    this.controlSchemeChosen = false,
    this.handedness = Handedness.right,
    this.oneHandedLayout = false,
    this.tiltSensitivity = 1,
    this.tiltCalibration = 0,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.effectsVolume = 1,
    this.musicVolume = 0.6,
    this.hapticsEnabled = true,
    this.themeChoice = ThemeChoice.system,
    this.languageCode,
    this.readerLanguageCode,
    this.remindersEnabled = false,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.onboardingDone = false,
    this.ghostEnabled = true,
  });

  /// Reads settings from decoded JSON. Anything missing or invalid becomes the
  /// default, and numbers are forced into range.
  factory Settings.fromJson(Object? json) {
    const Settings d = Settings();
    final Map<String, Object?> m = asJsonMap(json);
    return Settings(
      // Until the player picks a scheme themselves, the touch-the-sides
      // default applies, whatever an earlier version saved.
      controlScheme: readBool(m['controlSchemeChosen'], false)
          ? enumByName(ControlScheme.values, m['controlScheme'], d.controlScheme)
          : d.controlScheme,
      controlSchemeChosen: readBool(m['controlSchemeChosen'], false),
      handedness: enumByName(Handedness.values, m['handedness'], d.handedness),
      oneHandedLayout: readBool(m['oneHandedLayout'], d.oneHandedLayout),
      tiltSensitivity: _clamp(readDouble(m['tiltSensitivity'], d.tiltSensitivity), minTiltSensitivity, maxTiltSensitivity),
      tiltCalibration: _clamp(readDouble(m['tiltCalibration'], d.tiltCalibration), -1.5, 1.5),
      soundEnabled: readBool(m['soundEnabled'], d.soundEnabled),
      musicEnabled: readBool(m['musicEnabled'], d.musicEnabled),
      effectsVolume: _clamp(readDouble(m['effectsVolume'], d.effectsVolume), 0, 1),
      musicVolume: _clamp(readDouble(m['musicVolume'], d.musicVolume), 0, 1),
      hapticsEnabled: readBool(m['hapticsEnabled'], d.hapticsEnabled),
      themeChoice: enumByName(ThemeChoice.values, m['themeChoice'], d.themeChoice),
      languageCode: readStringOrNull(m['languageCode']),
      readerLanguageCode: readStringOrNull(m['readerLanguageCode']),
      remindersEnabled: readBool(m['remindersEnabled'], d.remindersEnabled),
      reminderHour: readInt(m['reminderHour'], d.reminderHour).clamp(0, 23).toInt(),
      reminderMinute: readInt(m['reminderMinute'], d.reminderMinute).clamp(0, 59).toInt(),
      onboardingDone: readBool(m['onboardingDone'], d.onboardingDone),
      ghostEnabled: readBool(m['ghostEnabled'], d.ghostEnabled),
    );
  }

  static const double minTiltSensitivity = 0.25;
  static const double maxTiltSensitivity = 2;

  final ControlScheme controlScheme;

  /// True once the player has picked a scheme in Settings.
  final bool controlSchemeChosen;
  final Handedness handedness;

  /// Moves every control into thumb reach of one hand.
  final bool oneHandedLayout;

  /// Multiplier on tilt steering, 0.25 to 2.
  final double tiltSensitivity;

  /// The rest angle measured by the calibration screen, in radians.
  final double tiltCalibration;

  final bool soundEnabled;
  final bool musicEnabled;

  /// 0 to 1.
  final double effectsVolume;

  /// 0 to 1.
  final double musicVolume;

  final bool hapticsEnabled;
  final ThemeChoice themeChoice;

  /// The app language, or null to follow the device.
  final String? languageCode;

  /// The reader's language (batch p8b), or null until the player picks one.
  final String? readerLanguageCode;

  /// Opt-in Daily Run reminder.
  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;

  final bool onboardingDone;

  /// Show the Time Trial ghost car.
  final bool ghostEnabled;

  Settings copyWith({
    ControlScheme? controlScheme,
    bool? controlSchemeChosen,
    Handedness? handedness,
    bool? oneHandedLayout,
    double? tiltSensitivity,
    double? tiltCalibration,
    bool? soundEnabled,
    bool? musicEnabled,
    double? effectsVolume,
    double? musicVolume,
    bool? hapticsEnabled,
    ThemeChoice? themeChoice,
    String? languageCode,
    bool clearLanguage = false,
    String? readerLanguageCode,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? onboardingDone,
    bool? ghostEnabled,
  }) =>
      Settings(
        controlScheme: controlScheme ?? this.controlScheme,
        controlSchemeChosen: controlSchemeChosen ?? this.controlSchemeChosen,
        handedness: handedness ?? this.handedness,
        oneHandedLayout: oneHandedLayout ?? this.oneHandedLayout,
        tiltSensitivity: _clamp(tiltSensitivity ?? this.tiltSensitivity, minTiltSensitivity, maxTiltSensitivity),
        tiltCalibration: _clamp(tiltCalibration ?? this.tiltCalibration, -1.5, 1.5),
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        effectsVolume: _clamp(effectsVolume ?? this.effectsVolume, 0, 1),
        musicVolume: _clamp(musicVolume ?? this.musicVolume, 0, 1),
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        themeChoice: themeChoice ?? this.themeChoice,
        languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
        readerLanguageCode: readerLanguageCode ?? this.readerLanguageCode,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        reminderHour: (reminderHour ?? this.reminderHour).clamp(0, 23).toInt(),
        reminderMinute: (reminderMinute ?? this.reminderMinute).clamp(0, 59).toInt(),
        onboardingDone: onboardingDone ?? this.onboardingDone,
        ghostEnabled: ghostEnabled ?? this.ghostEnabled,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'controlScheme': controlScheme.name,
        'controlSchemeChosen': controlSchemeChosen,
        'handedness': handedness.name,
        'oneHandedLayout': oneHandedLayout,
        'tiltSensitivity': tiltSensitivity,
        'tiltCalibration': tiltCalibration,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'effectsVolume': effectsVolume,
        'musicVolume': musicVolume,
        'hapticsEnabled': hapticsEnabled,
        'themeChoice': themeChoice.name,
        'languageCode': languageCode,
        'readerLanguageCode': readerLanguageCode,
        'remindersEnabled': remindersEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'onboardingDone': onboardingDone,
        'ghostEnabled': ghostEnabled,
      };

  @override
  bool operator ==(Object other) {
    if (other is! Settings) return false;
    final Map<String, Object?> a = toJson();
    final Map<String, Object?> b = other.toJson();
    for (final String key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

double _clamp(double value, double min, double max) =>
    value.clamp(min, max).toDouble();
