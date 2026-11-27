import 'package:audioplayers/audioplayers.dart';
import 'package:ruach/core/ports/device_ports.dart';

/// Sound effects and music from the bundled, synthesised files in
/// `assets/audio/` (synthesised by tools/audio/synth.py). A missing or unplayable file is
/// skipped silently; sound is never required.
final class AudioService implements AudioPort {
  AudioService({this.onError});

  /// Called with a short description when a sound cannot be played, for the
  /// local log.
  final void Function(String message)? onError;

  static const int _effectPlayers = 4;

  /// The file for each effect, relative to `assets/`.
  static String assetFor(SoundEffect effect) => 'audio/${effect.name}.ogg';

  static const String musicAsset = 'audio/music.ogg';

  final List<AudioPlayer> _effects = <AudioPlayer>[];
  AudioPlayer? _music;
  int _next = 0;
  double _effectVolume = 1;
  double _musicVolume = 0.6;
  bool _musicWanted = false;

  AudioPlayer _effectPlayer() {
    if (_effects.length < _effectPlayers) {
      final AudioPlayer p = AudioPlayer();
      _effects.add(p);
      return p;
    }
    final AudioPlayer p = _effects[_next];
    _next = (_next + 1) % _effectPlayers;
    return p;
  }

  @override
  Future<void> play(SoundEffect effect) async {
    if (_effectVolume <= 0) return;
    try {
      final AudioPlayer p = _effectPlayer();
      await p.setVolume(_effectVolume);
      await p.play(AssetSource(assetFor(effect)));
    } on Object catch (error) {
      onError?.call('sound ${effect.name} failed: $error');
    }
  }

  @override
  Future<void> startMusic() async {
    _musicWanted = true;
    if (_musicVolume <= 0) return;
    try {
      final AudioPlayer p = _music ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(_musicVolume);
      await p.play(AssetSource(musicAsset));
    } on Object catch (error) {
      onError?.call('music failed: $error');
    }
  }

  @override
  Future<void> stopMusic() async {
    _musicWanted = false;
    try {
      await _music?.stop();
    } on Object catch (error) {
      onError?.call('music stop failed: $error');
    }
  }

  @override
  Future<void> setVolumes({required double effects, required double music}) async {
    _effectVolume = effects.clamp(0.0, 1.0).toDouble();
    _musicVolume = music.clamp(0.0, 1.0).toDouble();
    try {
      await _music?.setVolume(_musicVolume);
      if (_musicVolume <= 0) {
        await _music?.pause();
      } else if (_musicWanted && _music?.state != PlayerState.playing) {
        await startMusic();
      }
    } on Object catch (error) {
      onError?.call('volume change failed: $error');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _music?.pause();
    } on Object catch (error) {
      onError?.call('pause failed: $error');
    }
  }

  @override
  Future<void> resume() async {
    if (!_musicWanted || _musicVolume <= 0) return;
    try {
      await _music?.resume();
    } on Object catch (error) {
      onError?.call('resume failed: $error');
    }
  }

  Future<void> dispose() async {
    for (final AudioPlayer p in _effects) {
      await p.dispose();
    }
    await _music?.dispose();
  }
}
