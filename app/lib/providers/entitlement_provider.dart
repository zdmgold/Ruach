import 'package:flutter/foundation.dart';
import 'package:ruach/core/ports/billing_port.dart';

/// Whether the player owns Remove Ads. The value comes from the store through
/// the billing port; nothing infers it at the point of use.
final class EntitlementProvider extends ValueNotifier<bool> {
  EntitlementProvider(this._billing) : super(false);

  final BillingPort _billing;

  bool get adsRemoved => value;

  /// Reads the purchase state from the store. A failure keeps the last value.
  Future<void> refresh() async {
    try {
      value = await _billing.ownsRemoveAds();
    } on Object {
      // Keep the last known value.
    }
  }

  /// Starts the purchase. The result tells the screen what to say.
  Future<PurchaseResult> buy() async {
    final PurchaseResult result = await _billing.buyRemoveAds();
    if (result == PurchaseResult.purchased || result == PurchaseResult.alreadyOwned) {
      value = true;
    }
    return result;
  }

  /// Restores earlier purchases. True if Remove Ads was found.
  Future<bool> restore() async {
    final bool found = await _billing.restore();
    if (found) value = true;
    return found;
  }

  Future<String?> priceText() => _billing.priceText();
}
