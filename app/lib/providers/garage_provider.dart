import 'package:flutter/foundation.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/upgrade_rules.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/core/ports/file_store.dart';
import 'package:ruach/providers/progress_provider.dart';

/// Gifts, the six upgrades and the player's chosen vehicle.
final class GarageProvider extends ChangeNotifier {
  GarageProvider(this._progress, this._store) {
    _progress.addListener(notifyListeners);
  }

  static const String selectedKey = 'selectedVehicle';

  final ProgressProvider _progress;
  final KeyValueStore _store;
  String _selected = VehicleIds.lightChariot;

  Progress get _p => _progress.value;

  int get gifts => _p.gifts;

  UpgradeLevels get levels => _p.upgrades;

  int levelOf(UpgradeKind kind) => levels.levelOf(kind);

  /// Gifts the next level costs, or null at the top.
  int? nextCost(UpgradeKind kind) => UpgradeRules.costOfNext(levelOf(kind));

  bool canBuy(UpgradeKind kind) => UpgradeRules.canBuy(_p, kind);

  /// Spends Gifts on the next level. False if it cannot be bought.
  Future<bool> buy(UpgradeKind kind) async {
    final Progress? next = UpgradeRules.buy(_p, kind);
    if (next == null) return false;
    await _progress.change((Progress _) => next);
    return true;
  }

  /// What the upgrades do to the player's car.
  CarTuning get tuning => UpgradeRules.tuningFor(levels);

  /// The vehicles the player has unlocked.
  List<Vehicle> get owned => <Vehicle>[
        for (final Vehicle v in VehicleCatalog.all)
          if (Unlocks.vehicle(v.id, _p)) v,
      ];

  /// The chosen vehicle, or the first owned one if the choice is not unlocked.
  Vehicle get selected {
    final Vehicle? v = VehicleCatalog.byId(_selected);
    return v != null && Unlocks.vehicle(v.id, _p) ? v : owned.first;
  }

  /// Reads the saved choice. Never throws.
  Future<void> load() async {
    try {
      final String? id = await _store.getString(selectedKey);
      if (id != null && VehicleCatalog.byId(id) != null) {
        _selected = id;
        notifyListeners();
      }
    } on Object {
      // Keep the default.
    }
  }

  /// Chooses a vehicle. False if it is not unlocked.
  Future<bool> select(String vehicleId) async {
    if (VehicleCatalog.byId(vehicleId) == null || !Unlocks.vehicle(vehicleId, _p)) {
      return false;
    }
    _selected = vehicleId;
    notifyListeners();
    try {
      await _store.setString(selectedKey, vehicleId);
    } on Object {
      // The choice still holds for this session.
    }
    return true;
  }

  @override
  void dispose() {
    _progress.removeListener(notifyListeners);
    super.dispose();
  }
}
