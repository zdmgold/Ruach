import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/race_cues.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/providers/feedback_provider.dart';
import 'package:ruach/providers/settings_provider.dart';

import '../support/fakes.dart';

void main() {
  late SettingsProvider settings;
  late FakeAudio audio;
  late FakeHaptics haptics;
  late FeedbackProvider feedback;

  setUp(() {
    settings = SettingsProvider(FakeKeyValueStore());
    audio = FakeAudio();
    haptics = FakeHaptics();
    feedback = FeedbackProvider(settings, audio: audio, haptics: haptics);
  });

  test('a cue plays its sound and touch', () async {
    feedback.cue(RaceCue.contact);
    await Future<void>.delayed(Duration.zero);
    expect(audio.played, <SoundEffect>[SoundEffect.collision]);
    expect(haptics.played, <HapticKind>[HapticKind.heavy]);
  });

  test('each finish outcome has its own sound', () async {
    feedback.cue(RaceCue.finishWin);
    feedback.cue(RaceCue.finishPodium);
    feedback.cue(RaceCue.finishOther);
    await Future<void>.delayed(Duration.zero);
    expect(audio.played, <SoundEffect>[
      SoundEffect.finishWin,
      SoundEffect.finishPodium,
      SoundEffect.finishOther,
    ]);
  });

  test('Sound off and Haptics off keep it quiet', () async {
    await settings.update((s) => s.copyWith(soundEnabled: false, hapticsEnabled: false));
    feedback.cue(RaceCue.lap);
    feedback.sound(SoundEffect.star);
    await Future<void>.delayed(Duration.zero);
    expect(audio.played, isEmpty);
    expect(haptics.played, isEmpty);
  });

  test('volumes follow the settings and a muted switch sends zero', () async {
    await settings.update((s) => s.copyWith(effectsVolume: 0.4, musicEnabled: false));
    expect(audio.volumes.last.effects, 0.4);
    expect(audio.volumes.last.music, 0);
  });

  test('turning music off stops it while racing', () async {
    feedback.startMusic();
    await settings.update((s) => s.copyWith(musicEnabled: false));
    expect(audio.musicStops, greaterThan(0));
  });

  test('with no audio or haptics it does nothing and does not throw', () {
    final FeedbackProvider quiet = FeedbackProvider(settings);
    quiet.cue(RaceCue.go);
    quiet.startMusic();
    quiet.pause();
  });
}
