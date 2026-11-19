import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/settings.dart';

void main() {
  test('defaults match the blueprint', () {
    const Settings s = Settings();
    expect(s.controlScheme, ControlScheme.buttons);
    expect(s.themeChoice, ThemeChoice.system);
    expect(s.languageCode, isNull);
    expect(s.remindersEnabled, isFalse);
    expect(s.onboardingDone, isFalse);
  });

  test('round-trips through JSON text', () {
    final Settings s = const Settings().copyWith(
      controlScheme: ControlScheme.tilt,
      handedness: Handedness.left,
      tiltSensitivity: 1.5,
      themeChoice: ThemeChoice.dark,
      languageCode: 'pt_BR',
      readerLanguageCode: 'he',
      remindersEnabled: true,
      reminderHour: 7,
      reminderMinute: 30,
      onboardingDone: true,
    );
    final Settings back = Settings.fromJson(jsonDecode(jsonEncode(s.toJson())));
    expect(back, s);
    expect(back.hashCode, s.hashCode);
  });

  test('values are forced into range', () {
    final Settings s = Settings.fromJson(<String, Object?>{
      'tiltSensitivity': 50,
      'effectsVolume': -1,
      'musicVolume': 7,
      'reminderHour': 99,
      'reminderMinute': -4,
      'controlScheme': 'teleport',
    });
    expect(s.tiltSensitivity, Settings.maxTiltSensitivity);
    expect(s.effectsVolume, 0);
    expect(s.musicVolume, 1);
    expect(s.reminderHour, 23);
    expect(s.reminderMinute, 0);
    expect(s.controlScheme, ControlScheme.buttons);
  });

  test('damaged input gives defaults', () {
    expect(Settings.fromJson(null), const Settings());
    expect(Settings.fromJson(<Object?>[1, 2]), const Settings());
  });

  test('the language can be cleared back to the device language', () {
    final Settings s = const Settings().copyWith(languageCode: 'de');
    expect(s.languageCode, 'de');
    expect(s.copyWith(clearLanguage: true).languageCode, isNull);
    expect(s.copyWith(soundEnabled: false).languageCode, 'de');
  });
}
