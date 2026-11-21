/// The one product: Remove Ads (com.zdmgold.ruach.removeads).
const String removeAdsProductId = 'com.zdmgold.ruach.removeads';

enum PurchaseResult {
  purchased,
  alreadyOwned,
  cancelled,
  pending,
  failed,
}

/// Native billing. With no backend, ownership is read from the store each
/// launch.
abstract interface class BillingPort {
  /// True if the player owns Remove Ads according to the store.
  Future<bool> ownsRemoveAds();

  Future<PurchaseResult> buyRemoveAds();

  /// Restores earlier purchases; true if Remove Ads was found.
  Future<bool> restore();

  /// Localized price text for the product, or null when unavailable.
  Future<String?> priceText();
}
