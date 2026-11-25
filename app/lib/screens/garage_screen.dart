import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/providers/garage_provider.dart';
import 'package:ruach/screens/milestone_block.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/gift_badge.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';
import 'package:ruach/widgets/upgrade_tile.dart';

/// Vehicles and the six Gifts of the Spirit. Gifts are earned by racing and
/// spent here; nothing in this screen is for sale (blueprint section 2).
class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key, this.banner, this.onShare});

  final Widget? banner;
  final ShareText? onShare;

  /// The six upgrades are named for Isaiah 11:2.
  static const String _upgradeBook = 'Isa';
  static const int _upgradeChapter = 11;
  static const int _upgradeVerse = 2;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  Map<UpgradeKind, Future<Verse?>>? _verses;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppScope scope = AppScope.of(context);
    _verses ??= <UpgradeKind, Future<Verse?>>{
      for (final UpgradeKind kind in UpgradeKind.values) kind: scope.verses.upgradeVerse(kind),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[scope.garage, scope.ads]),
      builder: (BuildContext context, Widget? _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final AppLocalizations l = AppLocalizations.of(context);
    final GarageProvider garage = scope.garage;
    final String reference = l.verseRef(
      bookName(l, GarageScreen._upgradeBook),
      GarageScreen._upgradeChapter,
      GarageScreen._upgradeVerse,
    );
    final bool bannerOn = scope.ads.bannersAllowed;
    return ScreenFrame(
      bannerHeight: bannerOn ? 50 : 0,
      banner: bannerOn ? widget.banner : null,
      navBar: NavBar(
        title: l.garageTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l.commonBack,
        actions: <Widget>[
          GiftBadge(count: garage.gifts, semanticLabel: l.giftCountSemantic(garage.gifts)),
        ],
      ),
      children: <Widget>[
        MilestoneSlot(onShare: widget.onShare),
        SectionHeader(l.garageVehiclesHeader),
        for (final Vehicle v in VehicleCatalog.all)
          _vehicleRow(l, garage, v),
        SectionHeader(l.garageUpgradesHeader),
        for (final UpgradeKind kind in UpgradeKind.values)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              0,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: _upgradeTile(l, garage, kind, reference),
          ),
      ],
    );
  }

  Widget _vehicleRow(AppLocalizations l, GarageProvider garage, Vehicle v) {
    final bool owned = garage.owned.any((Vehicle o) => o.id == v.id);
    final bool inUse = garage.selected.id == v.id;
    final String name = vehicleName(l, v.kind);
    if (!owned) {
      return AppRow(
        icon: AppIcons.locked,
        label: name,
        subtitle: l.garageUnlockedAt(Unlocks.vehicleTrackNumber),
      );
    }
    return AppRow(
      icon: AppIcons.vehicle,
      label: name,
      subtitle: eraName(l, v.era),
      onTap: inUse ? null : () => unawaited(garage.select(v.id)),
      semanticLabel: inUse ? l.garageVehicleInUse(name) : l.garageVehicleUse(name),
      trailing: inUse
          ? AppChip(label: l.garageInUse, tone: ChipTone.accent)
          : AppChip(label: l.garageUse),
    );
  }

  Widget _upgradeTile(
    AppLocalizations l,
    GarageProvider garage,
    UpgradeKind kind,
    String reference,
  ) {
    final int level = garage.levelOf(kind);
    final int? cost = garage.nextCost(kind);
    final bool canBuy = garage.canBuy(kind);
    final String name = upgradeName(l, kind);
    final String buyLabel = cost == null
        ? l.garageMaxed
        : (canBuy ? l.garageUpgradeFor(cost) : l.garageNeeds(cost));
    return FutureBuilder<Verse?>(
      future: _verses?[kind],
      builder: (BuildContext context, AsyncSnapshot<Verse?> snapshot) {
        final Verse? verse = snapshot.data;
        return _tile(l, garage, kind, name, level, canBuy, buyLabel,
            verse == null ? reference : VerseText.reference(l, verse.ref), verse?.text);
      },
    );
  }

  Widget _tile(
    AppLocalizations l,
    GarageProvider garage,
    UpgradeKind kind,
    String name,
    int level,
    bool canBuy,
    String buyLabel,
    String reference,
    String? verseText,
  ) {
    return UpgradeTile(
      name: name,
      effectLine: upgradeEffect(l, kind),
      verseReference: reference,
      verseText: verseText,
      level: level,
      maxLevel: UpgradeLevels.maxLevel,
      levelLabel: l.upgradeLevel(level, UpgradeLevels.maxLevel),
      buyLabel: buyLabel,
      onBuy: canBuy ? () => unawaited(garage.buy(kind)) : null,
      buySemanticLabel: l.garageBuySemantic(name, buyLabel),
    );
  }
}
