import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('every Journey track has a name, and a Now variant adds a suffix', () {
    for (final String id in TrackIds.journey) {
      final String name = trackName(l, id);
      expect(name, isNot(id), reason: id);
      expect(name, isNotEmpty);
      if (TrackIds.hasNowVariant(id)) {
        expect(trackName(l, TrackIds.nowVariantOf(id)), '$name (Now)');
      }
    }
  });

  test('every vehicle, upgrade, era and mode has a name', () {
    for (final VehicleKind k in VehicleKind.values) {
      expect(vehicleName(l, k), isNotEmpty);
    }
    for (final UpgradeKind k in UpgradeKind.values) {
      expect(upgradeName(l, k), isNotEmpty);
      expect(upgradeEffect(l, k), isNotEmpty);
    }
    for (final Era e in Era.values) {
      expect(eraName(l, e), isNotEmpty);
    }
    for (final RaceMode m in RaceMode.values) {
      expect(modeName(l, m), isNotEmpty);
      expect(modeBlurb(l, m), isNotEmpty);
    }
  });

  test('every Bible book used by a verse has a name', () {
    final String json = utf8.decode(
      gzip.decode(File('assets/verses/en.json.gz').readAsBytesSync()),
    );
    final Set<String> books = RegExp(r'"([1-3]?[A-Za-z]+)\.\d+\.\d+')
        .allMatches(json)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();
    expect(books, isNotEmpty);
    final Map<String, Object?> arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    for (final String b in books) {
      expect(arb.containsKey('book$b'), isTrue, reason: b);
      expect(bookName(l, b), isNotEmpty, reason: b);
    }
    expect(bookName(l, '1Sam'), '1 Samuel');
    expect(bookName(l, 'Ps'), 'Psalm');
  });

  test('plurals read naturally', () {
    expect(l.giftCount(1), '1 Gift');
    expect(l.giftCount(12), '12 Gifts');
    expect(l.streakDays(0), 'No streak yet');
    expect(l.streakDays(3), '3 day streak');
  });
}
