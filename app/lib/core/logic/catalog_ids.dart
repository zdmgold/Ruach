import 'package:ruach/core/models/vehicle.dart';

/// Stable ids of the 16 tracks, in Journey order (blueprint section 2). The
/// catalog (batch p2g) defines the geometry for each; rules that only need to
/// know which track is which use these ids.
abstract final class TrackIds {
  static const List<String> journey = <String>[
    'nile_banks',
    'red_sea_crossing',
    'sinai_wilderness',
    'jordan_crossing',
    'valley_of_elah',
    'carmel_ridge',
    'jerusalem_ascent',
    'babylon_gates',
    'galilee_shore',
    'damascus_road',
    'antioch_way',
    'appian_way',
    'desert_pass',
    'lakeside_drive',
    'coast_highway',
    'highland_switchbacks',
  ];

  /// Suffix of a Now variant's id.
  static const String nowSuffix = '_now';

  /// The Now variant of one of tracks 1 to 12.
  static String nowVariantOf(String id) => '$id$nowSuffix';

  static bool isNowVariant(String id) => id.endsWith(nowSuffix);

  /// The Then (or only) track a Now variant belongs to.
  static String baseOf(String id) =>
      isNowVariant(id) ? id.substring(0, id.length - nowSuffix.length) : id;

  /// Track number 1 to 16, or 0 for an unknown id.
  static int numberOf(String id) => journey.indexOf(baseOf(id)) + 1;

  /// Tracks 1 to 12 have a Now variant.
  static bool hasNowVariant(String id) {
    final int n = numberOf(id);
    return n >= 1 && n <= 12 && !isNowVariant(id);
  }

  /// All 28 raceable ids: 16 tracks and 12 Now variants.
  static List<String> get all => <String>[
        ...journey,
        for (final String id in journey.take(12)) nowVariantOf(id),
      ];
}

/// Stable ids of the six vehicles.
abstract final class VehicleIds {
  static const String lightChariot = 'light_chariot';
  static const String heavyChariot = 'heavy_chariot';
  static const String roadCart = 'road_cart';
  static const String hatch = 'hatch';
  static const String roadster = 'roadster';
  static const String utility4x4 = 'utility_4x4';

  static const List<String> all = <String>[
    lightChariot,
    heavyChariot,
    roadCart,
    hatch,
    roadster,
    utility4x4,
  ];

  static String forKind(VehicleKind kind) => switch (kind) {
        VehicleKind.lightChariot => lightChariot,
        VehicleKind.heavyChariot => heavyChariot,
        VehicleKind.roadCart => roadCart,
        VehicleKind.hatch => hatch,
        VehicleKind.roadster => roadster,
        VehicleKind.utility4x4 => utility4x4,
      };
}
