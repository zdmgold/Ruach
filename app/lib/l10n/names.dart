import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/l10n/app_localizations.dart';

/// Maps stable ids and enums to their translated names. Every visible name in
/// the app comes through here, so a missing translation is a compile error
/// rather than a blank label.

/// The name of a track by id. A Now variant reads "Name (Now)".
String trackName(AppLocalizations l, String id) {
  final String base = TrackIds.baseOf(id);
  final String name = switch (base) {
    'nile_banks' => l.trackNileBanks,
    'red_sea_crossing' => l.trackRedSeaCrossing,
    'sinai_wilderness' => l.trackSinaiWilderness,
    'jordan_crossing' => l.trackJordanCrossing,
    'valley_of_elah' => l.trackValleyOfElah,
    'carmel_ridge' => l.trackCarmelRidge,
    'jerusalem_ascent' => l.trackJerusalemAscent,
    'babylon_gates' => l.trackBabylonGates,
    'galilee_shore' => l.trackGalileeShore,
    'damascus_road' => l.trackDamascusRoad,
    'antioch_way' => l.trackAntiochWay,
    'appian_way' => l.trackAppianWay,
    'desert_pass' => l.trackDesertPass,
    'lakeside_drive' => l.trackLakesideDrive,
    'coast_highway' => l.trackCoastHighway,
    'highland_switchbacks' => l.trackHighlandSwitchbacks,
    _ => base,
  };
  return TrackIds.isNowVariant(id) ? l.trackNowVariant(name) : name;
}

String vehicleName(AppLocalizations l, VehicleKind kind) => switch (kind) {
      VehicleKind.lightChariot => l.vehicleLightChariot,
      VehicleKind.heavyChariot => l.vehicleHeavyChariot,
      VehicleKind.roadCart => l.vehicleRoadCart,
      VehicleKind.hatch => l.vehicleHatch,
      VehicleKind.roadster => l.vehicleRoadster,
      VehicleKind.utility4x4 => l.vehicleUtility4x4,
    };

String upgradeName(AppLocalizations l, UpgradeKind kind) => switch (kind) {
      UpgradeKind.wisdom => l.upgradeWisdom,
      UpgradeKind.understanding => l.upgradeUnderstanding,
      UpgradeKind.counsel => l.upgradeCounsel,
      UpgradeKind.might => l.upgradeMight,
      UpgradeKind.knowledge => l.upgradeKnowledge,
      UpgradeKind.fearOfTheLord => l.upgradeFearOfTheLord,
    };

String upgradeEffect(AppLocalizations l, UpgradeKind kind) => switch (kind) {
      UpgradeKind.wisdom => l.upgradeWisdomEffect,
      UpgradeKind.understanding => l.upgradeUnderstandingEffect,
      UpgradeKind.counsel => l.upgradeCounselEffect,
      UpgradeKind.might => l.upgradeMightEffect,
      UpgradeKind.knowledge => l.upgradeKnowledgeEffect,
      UpgradeKind.fearOfTheLord => l.upgradeFearOfTheLordEffect,
    };

String eraName(AppLocalizations l, Era era) => switch (era) {
      Era.chariotAge => l.eraChariotAge,
      Era.kingdomAndExile => l.eraKingdomAndExile,
      Era.gospelRoads => l.eraGospelRoads,
      Era.today => l.eraToday,
    };

String modeName(AppLocalizations l, RaceMode mode) => switch (mode) {
      RaceMode.journey => l.modeJourney,
      RaceMode.quickRace => l.modeQuickRace,
      RaceMode.timeTrial => l.modeTimeTrial,
      RaceMode.dailyRun => l.modeDailyRun,
      RaceMode.weeklyCircuit => l.modeWeeklyCircuit,
      RaceMode.escapeRun => l.modeEscapeRun,
      RaceMode.elimination => l.modeElimination,
    };

String modeBlurb(AppLocalizations l, RaceMode mode) => switch (mode) {
      RaceMode.journey => l.modeJourneyBlurb,
      RaceMode.quickRace => l.modeQuickRaceBlurb,
      RaceMode.timeTrial => l.modeTimeTrialBlurb,
      RaceMode.dailyRun => l.modeDailyRunBlurb,
      RaceMode.weeklyCircuit => l.modeWeeklyCircuitBlurb,
      RaceMode.escapeRun => l.modeEscapeRunBlurb,
      RaceMode.elimination => l.modeEliminationBlurb,
    };

/// The name of a Bible book by OSIS id; an unknown id is shown as it is.
String bookName(AppLocalizations l, String osis) => switch (osis) {
      'Gen' => l.bookGen,
      'Exod' => l.bookExod,
      'Num' => l.bookNum,
      'Deut' => l.bookDeut,
      'Josh' => l.bookJosh,
      'Judg' => l.bookJudg,
      'Ruth' => l.bookRuth,
      '1Sam' => l.book1Sam,
      '2Sam' => l.book2Sam,
      '1Chr' => l.book1Chr,
      '2Chr' => l.book2Chr,
      'Ezra' => l.bookEzra,
      'Neh' => l.bookNeh,
      'Job' => l.bookJob,
      'Ps' => l.bookPs,
      'Prov' => l.bookProv,
      'Eccl' => l.bookEccl,
      'Isa' => l.bookIsa,
      'Jer' => l.bookJer,
      'Lam' => l.bookLam,
      'Hos' => l.bookHos,
      'Amos' => l.bookAmos,
      'Mic' => l.bookMic,
      'Hab' => l.bookHab,
      'Zeph' => l.bookZeph,
      'Zech' => l.bookZech,
      'Matt' => l.bookMatt,
      'Mark' => l.bookMark,
      'Luke' => l.bookLuke,
      'John' => l.bookJohn,
      'Acts' => l.bookActs,
      'Rom' => l.bookRom,
      '1Cor' => l.book1Cor,
      '2Cor' => l.book2Cor,
      'Gal' => l.bookGal,
      'Eph' => l.bookEph,
      'Phil' => l.bookPhil,
      'Col' => l.bookCol,
      '1Thess' => l.book1Thess,
      '2Thess' => l.book2Thess,
      '2Tim' => l.book2Tim,
      'Heb' => l.bookHeb,
      'Jas' => l.bookJas,
      '1Pet' => l.book1Pet,
      '2Pet' => l.book2Pet,
      '1John' => l.book1John,
      'Rev' => l.bookRev,
      _ => osis,
    };
