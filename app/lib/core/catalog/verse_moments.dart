import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/verse.dart';

/// Which verse belongs to which place. The references must exist in every
/// language's curated bundle with the right moment tag; `catalog_test.dart`
/// checks all 11.
abstract final class VerseMoments {
  static const Map<String, String> _trackIntro = <String, String>{
    'nile_banks': 'Exod.2.3',
    'red_sea_crossing': 'Exod.14.21',
    'sinai_wilderness': 'Exod.19.20',
    'jordan_crossing': 'Josh.3.17',
    'valley_of_elah': '1Sam.17.2',
    'carmel_ridge': 'Amos.1.2',
    'jerusalem_ascent': 'Ps.122.2',
    'babylon_gates': 'Ps.137.1',
    'galilee_shore': 'Matt.4.18',
    'damascus_road': 'Acts.9.3',
    'antioch_way': 'Acts.11.19',
    'appian_way': 'Acts.28.15',
    'desert_pass': 'Isa.43.19',
    'lakeside_drive': 'Ps.23.2',
    'coast_highway': 'Ps.107.30',
    'highland_switchbacks': 'Ps.121.2',
  };

  static const Map<UpgradeKind, String> _upgrade = <UpgradeKind, String>{
    UpgradeKind.wisdom: 'Jas.1.5',
    UpgradeKind.understanding: 'Prov.4.7',
    UpgradeKind.counsel: 'Ps.32.8',
    UpgradeKind.might: 'Zech.4.6',
    UpgradeKind.knowledge: '2Pet.3.18',
    UpgradeKind.fearOfTheLord: 'Prov.1.7',
  };

  /// The intro verse for a track id. A Now variant uses its Then track's
  /// verse. Null for an unknown id.
  static VerseRef? trackIntro(String trackId) =>
      VerseRef.tryParse(_trackIntro[TrackIds.baseOf(trackId)] ?? '');

  /// The verse that explains an upgrade's name.
  static VerseRef upgrade(UpgradeKind kind) => VerseRef.tryParse(_upgrade[kind]!)!;

  /// Every reference this file points at, for the data test.
  static List<VerseRef> get allTrackIntro => <VerseRef>[
        for (final String id in TrackIds.journey) trackIntro(id)!,
      ];

  static List<VerseRef> get allUpgrade => <VerseRef>[
        for (final UpgradeKind k in UpgradeKind.values) upgrade(k),
      ];
}
