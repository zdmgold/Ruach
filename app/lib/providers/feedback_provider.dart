import 'dart:async';

import 'package:ruach/core/logic/race_cues.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/providers/settings_provider.dart';

/// Plays sounds and haptics, honouring the Sound, Music, Volume and Haptics
/// settings. With no audio files or no vibration motor it stays silent.
final class FeedbackProvider {
  FeedbackProvider(this._settings, {this._audio, this._haptics}) {
    _settings.addListener(_apply);
    _apply();
  }

  final SettingsProvider _settings;
  final AudioPort? _audio;
  final HapticsPort? _haptics;
  bool _musicOn = false;

  Settings get _s => _settings.value;

  void _apply() {
    final AudioPort? audio = _audio;
    if (audio == null) return;
    unawaited(audio.setVolumes(
      effects: _s.soundEnabled ? _s.effectsVolume : 0,
      music: _s.musicEnabled ? _s.musicVolume : 0,
    ));
    if (_musicOn && !_s.musicEnabled) unawaited(audio.stopMusic());
    if (_musicOn && _s.musicEnabled) unawaited(audio.startMusic());
  }

  void sound(SoundEffect effect) {
    if (_s.soundEnabled) unawaited(_audio?.play(effect));
  }

  void haptic(HapticKind kind) {
    if (_s.hapticsEnabled) unawaited(_haptics?.play(kind));
  }

  /// Race music: on while racing, off after.
  void startMusic() {
    _musicOn = true;
    if (_s.musicEnabled) unawaited(_audio?.startMusic());
  }

  void stopMusic() {
    _musicOn = false;
    unawaited(_audio?.stopMusic());
  }

  void pause() => unawaited(_audio?.pause());

  void resume() => unawaited(_audio?.resume());

  /// Sound and touch for one race cue.
  void cue(RaceCue cue) {
    switch (cue) {
      case RaceCue.countdownTick:
        sound(SoundEffect.countdownTick);
        haptic(HapticKind.selection);
      case RaceCue.go:
        sound(SoundEffect.go);
        haptic(HapticKind.medium);
      case RaceCue.boost:
        sound(SoundEffect.boost);
        haptic(HapticKind.light);
      case RaceCue.contact:
        sound(SoundEffect.collision);
        haptic(HapticKind.heavy);
      case RaceCue.lap:
        sound(SoundEffect.lap);
        haptic(HapticKind.light);
      case RaceCue.finishWin:
        sound(SoundEffect.finishWin);
        haptic(HapticKind.heavy);
      case RaceCue.finishPodium:
        sound(SoundEffect.finishPodium);
        haptic(HapticKind.medium);
      case RaceCue.finishOther:
        sound(SoundEffect.finishOther);
        haptic(HapticKind.light);
    }
  }

  void dispose() => _settings.removeListener(_apply);
}
