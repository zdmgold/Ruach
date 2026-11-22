import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/models/app_error.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/ports/billing_port.dart';
import 'package:ruach/providers/entitlement_provider.dart';
import 'package:ruach/providers/garage_provider.dart';
import 'package:ruach/providers/locale_provider.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/settings_provider.dart';
import 'package:ruach/providers/theme_provider.dart';

import '../support/fakes.dart';

void main() {
  group('SettingsProvider', () {
    test('changes are saved and loaded again', () async {
      final FakeKeyValueStore store = FakeKeyValueStore();
      final SettingsProvider a = SettingsProvider(store);
      await a.update((Settings s) => s.copyWith(controlScheme: ControlScheme.tilt, soundEnabled: false));
      final SettingsProvider b = SettingsProvider(store);
      await b.load();
      expect(b.value.controlScheme, ControlScheme.tilt);
      expect(b.value.soundEnabled, isFalse);
    });

    test('damaged saved text leaves the defaults and is logged', () async {
      final FakeKeyValueStore store = FakeKeyValueStore()..values[SettingsProvider.storageKey] = '{broken';
      final List<String> errors = <String>[];
      final SettingsProvider p = SettingsProvider(store, onError: errors.add);
      await p.load();
      expect(p.value, const Settings());
      expect(errors, hasLength(1));
    });

    test('listeners hear about a change', () async {
      final SettingsProvider p = SettingsProvider(FakeKeyValueStore());
      int heard = 0;
      p.addListener(() => heard++);
      await p.update((Settings s) => s.copyWith(hapticsEnabled: false));
      expect(heard, 1);
    });
  });

  group('ThemeProvider', () {
    test('follows the settings and resolves dark', () async {
      final SettingsProvider s = SettingsProvider(FakeKeyValueStore());
      final ThemeProvider t = ThemeProvider(s);
      expect(t.choice, ThemeChoice.system);
      expect(t.isDark(deviceIsDark: true), isTrue);
      int heard = 0;
      t.addListener(() => heard++);
      await t.setChoice(ThemeChoice.light);
      expect(heard, 1);
      expect(t.isDark(deviceIsDark: true), isFalse);
      await t.setChoice(ThemeChoice.dark);
      expect(t.isDark(deviceIsDark: false), isTrue);
    });
  });

  group('LocaleProvider', () {
    test('follows the device until the player picks a language', () async {
      final SettingsProvider s = SettingsProvider(FakeKeyValueStore());
      String device = 'fr-FR';
      final LocaleProvider l = LocaleProvider(s, deviceTag: () => device);
      expect(l.code, 'fr');
      expect(l.isOverridden, isFalse);
      await l.setLanguage('ar');
      expect(l.code, 'ar');
      expect(l.isRtl, isTrue);
      expect(l.isOverridden, isTrue);
      await l.setLanguage(null);
      expect(l.code, 'fr');
      device = 'ja';
      l.deviceChanged();
      expect(l.code, 'ja');
    });

    test('locales carry region and script where needed', () async {
      final SettingsProvider s = SettingsProvider(FakeKeyValueStore());
      final LocaleProvider l = LocaleProvider(s, deviceTag: () => 'en');
      await l.setLanguage('pt_BR');
      expect(l.locale.countryCode, 'BR');
      await l.setLanguage('zh_Hans');
      expect(l.locale.scriptCode, 'Hans');
      await l.setLanguage('de');
      expect(l.locale.languageCode, 'de');
    });
  });

  group('ProgressProvider', () {
    test('awarding stars saves and reports only the improvement', () async {
      final FakeFileStore files = FakeFileStore();
      final ProgressProvider p = ProgressProvider(ProgressRepository(files));
      await p.load();
      expect(await p.awardStars('nile_banks', 2), 2);
      expect(await p.awardStars('nile_banks', 1), 0);
      expect(await p.awardStars('nile_banks', 3), 1);
      await p.flush();
      final ProgressProvider again = ProgressProvider(ProgressRepository(files));
      await again.load();
      expect(again.value.starsOn('nile_banks'), 3);
      expect(again.value.giftsEarned, 3);
    });

    test('a failed save is reported and the next change retries', () async {
      final FakeFileStore files = FakeFileStore();
      final ProgressProvider p = ProgressProvider(ProgressRepository(files));
      await p.load();
      files.failWrites = true;
      await p.awardStars('a', 1);
      expect(p.saveError.value, isA<StorageError>());
      expect(p.value.starsOn('a'), 1);
      files.failWrites = false;
      await p.awardStars('b', 1);
      expect(p.saveError.value, isNull);
      expect(ProgressCodec.decode(files.files[ProgressRepository.fileName]!).progress!.totalStars, 2);
    });

    test('a damaged file gives a one-time notice', () async {
      final FakeFileStore files = FakeFileStore()
        ..files[ProgressRepository.fileName] = 'x'
        ..files[ProgressRepository.backupName] = 'y';
      final ProgressProvider p = ProgressProvider(ProgressRepository(files));
      await p.load();
      expect(p.origin, ProgressOrigin.startedClean);
      expect(p.hasNotice, isTrue);
      p.dismissNotice();
      expect(p.hasNotice, isFalse);
    });

    test('a newer schema is read-only: changes show but are not written', () async {
      final FakeFileStore files = FakeFileStore()
        ..files[ProgressRepository.fileName] = '{"schemaVersion":99,"giftsEarned":4}';
      final ProgressProvider p = ProgressProvider(ProgressRepository(files));
      await p.load();
      expect(p.readOnly, isTrue);
      await p.awardStars('a', 1);
      expect(p.saveError.value, isA<StorageError>());
      expect(files.files[ProgressRepository.fileName], '{"schemaVersion":99,"giftsEarned":4}');
    });

    test('rapid changes all end up saved', () async {
      final FakeFileStore files = FakeFileStore();
      final ProgressProvider p = ProgressProvider(ProgressRepository(files));
      await p.load();
      for (int i = 0; i < 5; i++) {
        p.change((Progress x) => x.copyWith(giftsEarned: x.giftsEarned + 1));
      }
      await p.flush();
      expect(ProgressCodec.decode(files.files[ProgressRepository.fileName]!).progress!.giftsEarned, 5);
    });
  });

  group('GarageProvider', () {
    Future<(ProgressProvider, GarageProvider, FakeKeyValueStore)> make(Progress start) async {
      final FakeFileStore files = FakeFileStore();
      final ProgressProvider p = ProgressProvider(ProgressRepository(files));
      await p.load();
      await p.change((Progress _) => start);
      final FakeKeyValueStore kv = FakeKeyValueStore();
      return (p, GarageProvider(p, kv), kv);
    }

    test('buying spends Gifts and raises the level', () async {
      final (ProgressProvider p, GarageProvider g, _) = await make(Progress(giftsEarned: 4));
      expect(g.gifts, 4);
      expect(g.nextCost(UpgradeKind.might), 1);
      expect(await g.buy(UpgradeKind.might), isTrue);
      expect(g.levelOf(UpgradeKind.might), 1);
      expect(g.gifts, 3);
      expect(g.tuning.topSpeedMultiplier, greaterThan(1));
      expect(await g.buy(UpgradeKind.might), isTrue);
      expect(g.gifts, 1);
      expect(await g.buy(UpgradeKind.might), isFalse);
      expect(g.canBuy(UpgradeKind.wisdom), isTrue);
      await p.flush();
    });

    test('listeners hear about a purchase', () async {
      final (_, GarageProvider g, _) = await make(Progress(giftsEarned: 2));
      int heard = 0;
      g.addListener(() => heard++);
      await g.buy(UpgradeKind.wisdom);
      expect(heard, greaterThan(0));
    });

    test('only unlocked vehicles can be chosen, and the choice is saved', () async {
      final (_, GarageProvider g, FakeKeyValueStore kv) = await make(Progress());
      expect(g.owned.map((v) => v.id).toList(), <String>[VehicleIds.lightChariot, VehicleIds.heavyChariot]);
      expect(await g.select(VehicleIds.hatch), isFalse);
      expect(await g.select('nonsense'), isFalse);
      expect(await g.select(VehicleIds.heavyChariot), isTrue);
      expect(g.selected.id, VehicleIds.heavyChariot);
      expect(kv.values[GarageProvider.selectedKey], VehicleIds.heavyChariot);
    });

    test('a saved choice loads; one that is no longer unlocked falls back', () async {
      final (_, GarageProvider g, FakeKeyValueStore kv) = await make(Progress());
      kv.values[GarageProvider.selectedKey] = VehicleIds.hatch;
      await g.load();
      expect(g.selected.id, VehicleIds.lightChariot);
    });
  });

  group('EntitlementProvider', () {
    test('reads ownership and survives a failed read', () async {
      final FakeBilling billing = FakeBilling()..owns = true;
      final EntitlementProvider e = EntitlementProvider(billing);
      expect(e.adsRemoved, isFalse);
      await e.refresh();
      expect(e.adsRemoved, isTrue);
      billing.failWith = StateError('store down');
      await e.refresh();
      expect(e.adsRemoved, isTrue);
    });

    test('a purchase turns ads off; cancelled or failed does not', () async {
      final FakeBilling billing = FakeBilling()..purchaseResult = PurchaseResult.cancelled;
      final EntitlementProvider e = EntitlementProvider(billing);
      expect(await e.buy(), PurchaseResult.cancelled);
      expect(e.adsRemoved, isFalse);
      billing.purchaseResult = PurchaseResult.failed;
      await e.buy();
      expect(e.adsRemoved, isFalse);
      billing.purchaseResult = PurchaseResult.purchased;
      await e.buy();
      expect(e.adsRemoved, isTrue);
    });

    test('restore finds the purchase', () async {
      final FakeBilling billing = FakeBilling();
      final EntitlementProvider e = EntitlementProvider(billing);
      expect(await e.restore(), isFalse);
      expect(e.adsRemoved, isFalse);
      billing.restoreFinds = true;
      expect(await e.restore(), isTrue);
      expect(e.adsRemoved, isTrue);
      expect(await e.priceText(), isNotNull);
    });
  });
}
