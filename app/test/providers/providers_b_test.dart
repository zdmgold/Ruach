import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/daily_seed.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/verse_repository.dart';
import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/core/ports/ads_port.dart';
import 'package:ruach/core/ports/consent_port.dart';
import 'package:ruach/core/ports/flags_port.dart';
import 'package:ruach/core/ports/verse_source.dart';
import 'package:ruach/providers/ad_provider.dart';
import 'package:ruach/providers/consent_provider.dart';
import 'package:ruach/providers/daily_provider.dart';
import 'package:ruach/providers/entitlement_provider.dart';
import 'package:ruach/providers/flags_provider.dart';
import 'package:ruach/providers/locale_provider.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/providers/settings_provider.dart';
import 'package:ruach/providers/verse_provider.dart';

import '../support/fakes.dart';

const ConsentSnapshot _granted = ConsentSnapshot(
  status: ConsentStatus.obtained,
  canRequestAds: true,
  privacyOptionsRequired: true,
);

final class _Verses implements VerseDataSource {
  @override
  Future<Object?> load(String language) async => <String, Object?>{
        'verses': <Object?>[
          <String, Object?>{'ref': 'Ps.23.1', 'text': 'A', 'moments': <String>['win']},
          <String, Object?>{'ref': 'Ps.23.2', 'text': 'B', 'moments': <String>['win']},
        ],
      };
}

RaceConfig _config(RaceMode mode) => ModeRules.build(
      mode: mode,
      track: TrackCatalog.journey.first,
      vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey.first),
      roster: RivalCatalog.all,
      seed: 7,
    );

void main() {
  group('RaceProvider', () {
    late ProgressProvider progress;
    late RaceProvider race;

    setUp(() {
      progress = ProgressProvider(ProgressRepository(FakeFileStore()));
      race = RaceProvider(progress);
    });

    test('runs the countdown, then racing, at a fixed step', () {
      race.start(_config(RaceMode.quickRace));
      expect(race.stage, RaceStage.running);
      race.advance(1 / 60 * 4, DriveInput.idle);
      expect(race.simulation!.phase, RacePhase.countdown);
      race.advance(4, DriveInput.idle);
      race.advance(4, DriveInput.idle);
      expect(race.simulation!.phase, RacePhase.racing);
    });

    test('a long gap between frames is capped', () {
      race.start(_config(RaceMode.quickRace));
      race.advance(100, DriveInput.idle);
      expect(race.simulation!.countdownSeconds, greaterThan(2.8 - RaceProvider.maxStepsPerAdvance / 60));
    });

    test('pause stops time and resume restarts it', () {
      race.start(_config(RaceMode.quickRace));
      race.advance(0.2, DriveInput.idle);
      final double before = race.simulation!.countdownSeconds;
      race.pause();
      race.advance(0.2, DriveInput.idle);
      expect(race.simulation!.countdownSeconds, before);
      race.resume();
      race.advance(0.1, DriveInput.idle);
      expect(race.simulation!.countdownSeconds, lessThan(before));
    });

    test('abandon returns to idle with no result', () {
      race.start(_config(RaceMode.quickRace));
      race.abandon();
      expect(race.stage, RaceStage.idle);
      expect(race.result, isNull);
    });

    test('a win gives three stars and Gifts once, however often it is committed', () async {
      race.start(_config(RaceMode.quickRace));
      final RaceSimulation sim = race.simulation!;
      for (int i = 0; i < 200; i++) {
        sim.step(DriveInput.idle);
      }
      sim.player.tracker.forceFinish(sim.elapsedSeconds);
      sim.endRace();
      race.advance(0.02, DriveInput.idle);
      expect(race.stage, RaceStage.finished);
      expect(race.result!.stars, 3);
      expect(await race.commit(), 3);
      expect(await race.commit(), 3);
      expect(progress.value.giftsEarned, 3);
      expect(progress.value.starsOn(TrackCatalog.journey.first.id), 3);
    });

    test('a race that is ended without finishing earns nothing', () async {
      race.start(_config(RaceMode.quickRace));
      final RaceSimulation sim = race.simulation!;
      for (int i = 0; i < 200; i++) {
        sim.step(DriveInput.idle);
      }
      sim.endRace();
      race.advance(0.02, DriveInput.idle);
      expect(race.result!.stars, 0);
      await race.commit();
      expect(progress.value.giftsEarned, 0);
    });

    test('an Escape Run ends when the wall catches a car that does not move', () {
      race.start(_config(RaceMode.escapeRun));
      for (int i = 0; i < 400; i++) {
        race.advance(0.5, DriveInput.idle);
        if (race.stage == RaceStage.finished) break;
      }
      expect(race.stage, RaceStage.finished);
      expect(race.escape!.caught, isTrue);
    });
  });

  group('ConsentProvider and AdProvider', () {
    late FakeConsent consentPort;
    late FakeAds adsPort;
    late FakeFlags flagsPort;
    late FakeBilling billing;
    late EntitlementProvider entitlement;
    late ConsentProvider consent;
    late FlagsProvider flags;
    late DateTime now;

    AdProvider makeAds({bool firstSession = false}) =>
        AdProvider(adsPort, consent, flags, firstSession: firstSession, clock: () => now);

    setUp(() {
      consentPort = FakeConsent();
      adsPort = FakeAds();
      flagsPort = FakeFlags();
      billing = FakeBilling();
      entitlement = EntitlementProvider(billing);
      consent = ConsentProvider(consentPort, entitlement);
      flags = FlagsProvider(flagsPort);
      now = DateTime(2026, 11, 22, 12);
    });

    test('nothing is allowed before consent says so', () async {
      final AdProvider ads = makeAds();
      await ads.initialize();
      expect(ads.bannersAllowed, isFalse);
      expect(ads.rewardedAllowed, isFalse);
      expect(adsPort.initCalls, 0);
      expect(await ads.maybeShowInterstitial(), isFalse);
    });

    test('ads start when consent arrives', () async {
      final AdProvider ads = makeAds();
      consentPort.next = _granted;
      await consent.refresh();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(adsPort.initCalls, 1);
      expect(ads.bannersAllowed, isTrue);
    });

    test('a failing consent service leaves ads off', () async {
      consentPort.throws = true;
      await consent.refresh();
      expect(consent.value.canRequestAds, isFalse);
    });

    test('Remove Ads switches banners and interstitials off but not rewarded ads', () async {
      final AdProvider ads = makeAds();
      consentPort.next = _granted;
      await consent.refresh();
      await ads.initialize();
      billing.owns = true;
      await entitlement.refresh();
      expect(ads.bannersAllowed, isFalse);
      expect(await ads.maybeShowInterstitial(), isFalse);
      expect(ads.rewardedAllowed, isTrue);
    });

    test('the remote switch turns every ad off', () async {
      final AdProvider ads = makeAds();
      consentPort.next = _granted;
      await consent.refresh();
      await ads.initialize();
      flagsPort.flags = const RemoteFlags(adsEnabled: false);
      await flags.load();
      expect(ads.bannersAllowed, isFalse);
      expect(ads.rewardedAllowed, isFalse);
      expect(await ads.maybeShowInterstitial(), isFalse);
    });

    test('flags keep the last good value when the fetch fails', () async {
      flagsPort.flags = const RemoteFlags(adsEnabled: false);
      await flags.load();
      flagsPort.throws = true;
      await flags.load();
      expect(flags.value.adsEnabled, isFalse);
    });

    test('no interstitial in the first session', () async {
      final AdProvider ads = makeAds(firstSession: true);
      consentPort.next = _granted;
      await consent.refresh();
      await ads.initialize();
      expect(await ads.maybeShowInterstitial(), isFalse);
      expect(adsPort.shown, isEmpty);
    });

    test('at most one interstitial in three minutes', () async {
      final AdProvider ads = makeAds();
      consentPort.next = _granted;
      await consent.refresh();
      await ads.initialize();
      expect(await ads.maybeShowInterstitial(), isTrue);
      now = now.add(const Duration(minutes: 2));
      expect(await ads.maybeShowInterstitial(), isFalse);
      now = now.add(const Duration(minutes: 2));
      expect(await ads.maybeShowInterstitial(), isTrue);
      expect(adsPort.shown, hasLength(2));
    });

    test('no interstitial after the first Daily attempt', () async {
      final AdProvider ads = makeAds();
      consentPort.next = _granted;
      await consent.refresh();
      await ads.initialize();
      expect(await ads.maybeShowInterstitial(afterFirstDailyAttempt: true), isFalse);
    });

    test('a rewarded ad pays only when the reward was earned', () async {
      final AdProvider ads = makeAds();
      consentPort.next = _granted;
      await consent.refresh();
      await ads.initialize();
      adsPort.result = AdShowResult.shown;
      expect(await ads.showRewarded(), isFalse);
      adsPort.result = AdShowResult.rewardEarned;
      expect(await ads.showRewarded(), isTrue);
    });
  });

  group('DailyProvider', () {
    late ProgressProvider progress;
    late SettingsProvider settings;
    late FakeNotifications notifications;
    late DateTime now;
    late DailyProvider daily;

    setUp(() {
      progress = ProgressProvider(ProgressRepository(FakeFileStore()));
      settings = SettingsProvider(FakeKeyValueStore());
      notifications = FakeNotifications();
      now = DateTime(2026, 11, 22, 9);
      daily = DailyProvider(progress, settings, notifications, clock: () => now);
    });

    test('the challenge is the same for the same date', () {
      expect(daily.challenge.trackId, DailySeed.forDate(const CivilDate(2026, 11, 22)).trackId);
    });

    test('the first attempt is free and later ones are extra', () async {
      expect(daily.nextAttemptIsExtra, isFalse);
      await daily.startAttempt();
      expect(daily.attemptsToday, 1);
      expect(daily.nextAttemptIsExtra, isTrue);
    });

    test('finishing counts the streak once a day and keeps the best position', () async {
      await daily.startAttempt();
      final StreakUpdate a = await daily.complete(3);
      expect(a.current, 1);
      final StreakUpdate b = await daily.complete(1);
      expect(b.counted, isFalse);
      expect(daily.streak, 1);
      expect(daily.record.bestPosition, 1);
      expect(daily.completedToday, isTrue);
    });

    test('the streak grows on consecutive days and resets after a gap', () async {
      await daily.complete(2);
      now = DateTime(2026, 11, 23, 9);
      await daily.complete(2);
      expect(daily.streak, 2);
      now = DateTime(2026, 11, 27, 9);
      expect(daily.streak, 0);
      expect(daily.welcomeBackDue, isTrue);
      await daily.complete(2);
      expect(daily.streak, 1);
      expect(daily.bestStreak, 2);
    });

    test('the reminder needs permission and schedules at the saved time', () async {
      notifications.permitted = false;
      expect(await daily.setReminder(enabled: true, title: 't', body: 'b'), isFalse);
      expect(settings.value.remindersEnabled, isFalse);
      notifications.permitted = true;
      expect(await daily.setReminder(enabled: true, title: 't', body: 'b'), isTrue);
      expect(settings.value.remindersEnabled, isTrue);
      expect(notifications.calls, <String>['schedule 18:0']);
      await daily.setReminder(enabled: false, title: 't', body: 'b');
      expect(settings.value.remindersEnabled, isFalse);
      expect(notifications.calls.last, 'cancel');
    });
  });

  group('VerseProvider', () {
    test('picks a verse, records it, and prefers unseen ones next time', () async {
      final ProgressProvider progress = ProgressProvider(ProgressRepository(FakeFileStore()));
      final LocaleProvider locale = LocaleProvider(SettingsProvider(FakeKeyValueStore()), deviceTag: () => 'en');
      final VerseProvider verses = VerseProvider(VerseRepository(_Verses()), progress, locale);
      final Verse? first = await verses.pick(VerseMoment.win, seed: 1);
      expect(first, isNotNull);
      expect(progress.value.seenVerseIds, contains(first!.id));
      final Verse? second = await verses.pick(VerseMoment.win, seed: 1);
      expect(second!.ref, isNot(first.ref));
      expect((await verses.library()).length, 2);
    });
  });
}
