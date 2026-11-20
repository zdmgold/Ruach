import 'dart:math' as math;

import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';

/// Where a point is relative to the road.
final class TrackProjection {
  const TrackProjection({
    required this.distance,
    required this.lateral,
    required this.halfWidth,
    required this.tangent,
    required this.index,
  });

  /// Metres along the centreline from the start line, 0 up to the lap length.
  final double distance;

  /// Signed sideways offset from the centreline in metres. Positive is to the
  /// right of the direction of travel.
  final double lateral;

  /// Half the road width at this point.
  final double halfWidth;

  /// Unit vector along the road.
  final Vec2 tangent;

  /// Index of the centreline segment the point is nearest to.
  final int index;

  bool get onTrack => lateral.abs() <= halfWidth;
}

/// A track's centreline as a dense closed polyline with lengths and widths,
/// built from the control points as a Catmull-Rom spline. Pure geometry: it
/// answers "where along the road is this point" and "where is this distance".
final class TrackGeometry {
  TrackGeometry._(
    this.track,
    this._points,
    this._cumulative,
    this._segmentLength,
    this._widths,
    this.length,
  );

  /// Builds the geometry. [samplesPerSegment] is how many polyline points are
  /// made between two control points.
  factory TrackGeometry.of(Track track, {int samplesPerSegment = 16}) {
    final List<Vec2> c = track.centerline;
    final int n = c.length;
    final List<Vec2> points = <Vec2>[];
    final List<double> widths = <double>[];
    for (int i = 0; i < n; i++) {
      final Vec2 p0 = c[(i - 1 + n) % n];
      final Vec2 p1 = c[i];
      final Vec2 p2 = c[(i + 1) % n];
      final Vec2 p3 = c[(i + 2) % n];
      for (int s = 0; s < samplesPerSegment; s++) {
        final double t = s / samplesPerSegment;
        points.add(_catmullRom(p0, p1, p2, p3, t));
        widths.add(track.widths[i] + (track.widths[(i + 1) % n] - track.widths[i]) * t);
      }
    }
    final int m = points.length;
    final List<double> cumulative = List<double>.filled(m, 0);
    final List<double> segment = List<double>.filled(m, 0);
    double total = 0;
    for (int k = 0; k < m; k++) {
      cumulative[k] = total;
      segment[k] = points[k].distanceTo(points[(k + 1) % m]);
      total += segment[k];
    }
    return TrackGeometry._(track, points, cumulative, segment, widths, total);
  }

  final Track track;
  final List<Vec2> _points;
  final List<double> _cumulative;
  final List<double> _segmentLength;
  final List<double> _widths;

  /// Length of one lap in metres.
  final double length;

  int get sampleCount => _points.length;

  static Vec2 _catmullRom(Vec2 p0, Vec2 p1, Vec2 p2, Vec2 p3, double t) {
    final double t2 = t * t;
    final double t3 = t2 * t;
    final double x = 0.5 *
        ((2 * p1.x) +
            (-p0.x + p2.x) * t +
            (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
            (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3);
    final double y = 0.5 *
        ((2 * p1.y) +
            (-p0.y + p2.y) * t +
            (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
            (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);
    return Vec2(x, y);
  }

  Vec2 _tangentOfSegment(int k) {
    final int m = _points.length;
    return (_points[(k + 1) % m] - _points[k]).normalized();
  }

  /// Where [position] is relative to the road. With a [hint] (the segment
  /// index of the last projection) only nearby segments are searched, which is
  /// much faster; a far-off result falls back to a full search.
  TrackProjection project(Vec2 position, {int? hint}) {
    final int m = _points.length;
    if (hint != null) {
      const int window = 12;
      final TrackProjection near = _search(position, hint - window, 2 * window + 1);
      if (near.lateral.abs() <= near.halfWidth + 20) return near;
    }
    return _search(position, 0, m);
  }

  TrackProjection _search(Vec2 position, int start, int count) {
    final int m = _points.length;
    double bestDistanceSquared = double.infinity;
    int bestIndex = 0;
    double bestT = 0;
    for (int j = 0; j < count; j++) {
      final int k = ((start + j) % m + m) % m;
      final Vec2 a = _points[k];
      final Vec2 ab = _points[(k + 1) % m] - a;
      final double lenSq = ab.lengthSquared;
      double t = lenSq == 0 ? 0 : (position - a).dot(ab) / lenSq;
      t = t < 0 ? 0 : (t > 1 ? 1 : t);
      final Vec2 closest = a + ab * t;
      final double d2 = (position - closest).lengthSquared;
      if (d2 < bestDistanceSquared) {
        bestDistanceSquared = d2;
        bestIndex = k;
        bestT = t;
      }
    }
    final Vec2 tangent = _tangentOfSegment(bestIndex);
    final Vec2 closest = _points[bestIndex] +
        (_points[(bestIndex + 1) % m] - _points[bestIndex]) * bestT;
    final double lateral = (position - closest).dot(tangent.perpendicular);
    final double w0 = _widths[bestIndex];
    final double w1 = _widths[(bestIndex + 1) % m];
    return TrackProjection(
      distance: _cumulative[bestIndex] + _segmentLength[bestIndex] * bestT,
      lateral: lateral,
      halfWidth: (w0 + (w1 - w0) * bestT) / 2,
      tangent: tangent,
      index: bestIndex,
    );
  }

  /// The segment index for a distance along the lap (wrapped).
  int _indexAt(double distance) {
    final double d = distance % length;
    int lo = 0;
    int hi = _points.length - 1;
    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (_cumulative[mid] <= d) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// The centreline point [distance] metres from the start line. Distances
  /// wrap around the lap.
  Vec2 positionAt(double distance) {
    final double d = distance % length;
    final int k = _indexAt(d);
    final double t = _segmentLength[k] == 0 ? 0 : (d - _cumulative[k]) / _segmentLength[k];
    return _points[k].lerp(_points[(k + 1) % _points.length], t);
  }

  /// Unit vector along the road [distance] metres from the start line.
  Vec2 tangentAt(double distance) => _tangentOfSegment(_indexAt(distance));

  /// Road width in metres [distance] metres from the start line.
  double widthAt(double distance) {
    final double d = distance % length;
    final int k = _indexAt(d);
    final double t = _segmentLength[k] == 0 ? 0 : (d - _cumulative[k]) / _segmentLength[k];
    final double w0 = _widths[k];
    final double w1 = _widths[(k + 1) % _points.length];
    return w0 + (w1 - w0) * t;
  }

  /// The signed turn in radians over [span] metres starting at [distance]:
  /// positive turns right. Used by the rival AI to look ahead for corners.
  double curvatureAhead(double distance, double span) {
    final Vec2 a = tangentAt(distance);
    final Vec2 b = tangentAt(distance + span);
    return math.atan2(a.cross(b), a.dot(b));
  }

  /// The surface at a lap fraction (0 to 1).
  SurfaceType surfaceAt(double fraction) {
    for (final SurfaceZone zone in track.surfaceZones) {
      if (fraction >= zone.startFraction && fraction < zone.endFraction) {
        return zone.surface;
      }
    }
    return track.baseSurface;
  }
}
