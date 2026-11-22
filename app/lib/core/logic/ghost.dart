import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/models/vec2.dart';

/// One recorded lap: the player's position and heading every tenth of a
/// second. A ghost car replays it by interpolating between samples. (The
/// blueprint names an input log; a position log replays exactly without
/// re-running the physics, and a lap fits in about 3 KB. See D-037.)
final class GhostLap {
  GhostLap({required this.lapSeconds, required List<Vec2> positions, required List<double> headings})
      : positions = List<Vec2>.unmodifiable(positions),
        headings = List<double>.unmodifiable(headings),
        assert(positions.length == headings.length, 'one heading per position');

  /// Seconds between samples.
  static const double interval = 0.1;

  /// Simulation ticks between samples (60 Hz).
  static const int tickInterval = 6;

  final double lapSeconds;
  final List<Vec2> positions;
  final List<double> headings;

  int get length => positions.length;

  /// Where the ghost is [t] seconds into its lap; time wraps, so a ghost
  /// keeps lapping.
  Vec2 positionAt(double t) {
    final (int i, int j, double f) = _locate(t);
    return positions[i].lerp(positions[j], f);
  }

  /// The ghost's heading at [t], turning by the short way round.
  double headingAt(double t) {
    final (int i, int j, double f) = _locate(t);
    return wrapAngle(headings[i] + wrapAngle(headings[j] - headings[i]) * f);
  }

  (int, int, double) _locate(double t) {
    final double wrapped = lapSeconds <= 0 ? 0 : (t % lapSeconds + lapSeconds) % lapSeconds;
    final double exact = wrapped / interval;
    final int i = math.min(exact.floor(), length - 1);
    final int j = (i + 1) % length;
    return (i, j, exact - i);
  }
}

/// Collects samples while a lap is driven.
final class GhostRecorder {
  final List<Vec2> _positions = <Vec2>[];
  final List<double> _headings = <double>[];

  int get sampleCount => _positions.length;

  /// Forgets the lap in progress.
  void startLap() {
    _positions.clear();
    _headings.clear();
  }

  /// Call every simulation tick with the tick number within the lap (0 on
  /// the first tick). Every sixth tick is kept.
  void sample(int tickInLap, Vec2 position, double heading) {
    if (tickInLap < 0 || tickInLap % GhostLap.tickInterval != 0) return;
    _positions.add(position);
    _headings.add(heading);
  }

  /// The finished lap, or null if too few samples were taken.
  GhostLap? finish(double lapSeconds) {
    if (_positions.length < 2 || !(lapSeconds > 0)) return null;
    return GhostLap(lapSeconds: lapSeconds, positions: _positions, headings: _headings);
  }
}

/// Text form of a [GhostLap] for the saved game: base64 of a small binary
/// record. Version 1: version byte, lap time in milliseconds (uint32), sample
/// count (uint16), then per sample a position in decimetres (the first
/// absolute as int32, the rest as int16 steps) and the heading as one byte.
abstract final class GhostCodec {
  static const int version = 1;
  static const int maxSamples = 6000;

  static String encode(GhostLap lap) {
    final int n = math.min(lap.length, maxSamples);
    final ByteData data = ByteData(7 + 9 + (n - 1) * 5);
    data.setUint8(0, version);
    data.setUint32(1, (lap.lapSeconds * 1000).round());
    data.setUint16(5, n);
    int offset = 7;
    int px = 0;
    int py = 0;
    for (int k = 0; k < n; k++) {
      final int x = (lap.positions[k].x * 10).round();
      final int y = (lap.positions[k].y * 10).round();
      if (k == 0) {
        data.setInt32(offset, x);
        data.setInt32(offset + 4, y);
        offset += 8;
      } else {
        data.setInt16(offset, (x - px).clamp(-32768, 32767));
        data.setInt16(offset + 2, (y - py).clamp(-32768, 32767));
        offset += 4;
      }
      px = x;
      py = y;
      final double h = (lap.headings[k] % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
      data.setUint8(offset, (h / (2 * math.pi) * 256).round() % 256);
      offset += 1;
    }
    return base64Encode(Uint8List.sublistView(data, 0, offset));
  }

  /// The lap, or null when the text is not a valid version 1 record.
  static GhostLap? decode(String text) {
    try {
      final Uint8List bytes = base64Decode(text);
      if (bytes.length < 7 + 9) return null;
      final ByteData data = ByteData.sublistView(bytes);
      if (data.getUint8(0) != version) return null;
      final int millis = data.getUint32(1);
      final int n = data.getUint16(5);
      if (millis <= 0 || n < 2 || n > maxSamples) return null;
      if (bytes.length != 7 + 9 + (n - 1) * 5) return null;
      final List<Vec2> positions = <Vec2>[];
      final List<double> headings = <double>[];
      int offset = 7;
      int x = 0;
      int y = 0;
      for (int k = 0; k < n; k++) {
        if (k == 0) {
          x = data.getInt32(offset);
          y = data.getInt32(offset + 4);
          offset += 8;
        } else {
          x += data.getInt16(offset);
          y += data.getInt16(offset + 2);
          offset += 4;
        }
        positions.add(Vec2(x / 10, y / 10));
        headings.add(wrapAngle(data.getUint8(offset) / 256 * 2 * math.pi));
        offset += 1;
      }
      return GhostLap(lapSeconds: millis / 1000, positions: positions, headings: headings);
    } on Object {
      return null;
    }
  }
}
