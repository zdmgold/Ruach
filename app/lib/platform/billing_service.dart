import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ruach/core/ports/billing_port.dart';
import 'package:ruach/core/ports/file_store.dart';

/// Remove Ads through the store's native billing. With no backend, ownership
/// is read from the store each launch; the last known answer is kept in
/// preferences only so an offline launch still honours a purchase.
final class BillingService implements BillingPort {
  BillingService(this._cache, {InAppPurchase? iap, this.onError})
      : _iap = iap ?? InAppPurchase.instance;

  static const String cacheKey = 'adsRemoved';

  final KeyValueStore _cache;
  final InAppPurchase _iap;
  final void Function(String message)? onError;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<PurchaseResult>? _purchase;
  Completer<bool>? _restore;
  bool _ownsThisSession = false;

  /// True when [purchase] grants Remove Ads.
  static bool grantsRemoveAds(PurchaseDetails purchase) =>
      purchase.productID == removeAdsProductId &&
      (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored);

  /// Starts listening for purchase updates. Call once at launch.
  void start() {
    _subscription ??= _iap.purchaseStream.listen(
      (List<PurchaseDetails> updates) => unawaited(_onUpdates(updates)),
      onError: (Object error) => onError?.call('purchase stream failed: $error'),
    );
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    for (final PurchaseDetails purchase in updates) {
      if (purchase.productID != removeAdsProductId) {
        if (purchase.pendingCompletePurchase) await _complete(purchase);
        continue;
      }
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _ownsThisSession = true;
          await _cache.setString(cacheKey, 'true');
          if (purchase.pendingCompletePurchase) await _complete(purchase);
          if (purchase.status == PurchaseStatus.purchased) {
            _purchase?.complete(PurchaseResult.purchased);
          }
          if (purchase.status == PurchaseStatus.restored) {
            final Completer<bool>? restore = _restore;
            if (restore != null && !restore.isCompleted) restore.complete(true);
          }
        case PurchaseStatus.pending:
          _purchase?.complete(PurchaseResult.pending);
        case PurchaseStatus.canceled:
          _purchase?.complete(PurchaseResult.cancelled);
          if (purchase.pendingCompletePurchase) await _complete(purchase);
        case PurchaseStatus.error:
          onError?.call('purchase error: ${purchase.error?.message}');
          _purchase?.complete(PurchaseResult.failed);
          if (purchase.pendingCompletePurchase) await _complete(purchase);
      }
    }
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    try {
      await _iap.completePurchase(purchase);
    } on Object catch (error) {
      onError?.call('completing a purchase failed: $error');
    }
  }

  @override
  Future<bool> ownsRemoveAds() async {
    start();
    try {
      if (!await _iap.isAvailable()) return await _cached();
      final bool found = await _restoreAndWait(const Duration(seconds: 4));
      if (found) return true;
      // The store answered and found nothing: a refund or no purchase.
      await _cache.setString(cacheKey, 'false');
      return false;
    } on Object catch (error) {
      onError?.call('reading the purchase state failed: $error');
      return _cached();
    }
  }

  Future<bool> _cached() async => await _cache.getString(cacheKey) == 'true';

  Future<bool> _restoreAndWait(Duration timeout) async {
    _ownsThisSession = false;
    final Completer<bool> restore = Completer<bool>();
    _restore = restore;
    await _iap.restorePurchases();
    final bool found = await restore.future.timeout(timeout, onTimeout: () => _ownsThisSession);
    _restore = null;
    return found || _ownsThisSession;
  }

  @override
  Future<PurchaseResult> buyRemoveAds() async {
    start();
    try {
      if (!await _iap.isAvailable()) return PurchaseResult.failed;
      if (await _cached()) return PurchaseResult.alreadyOwned;
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(<String>{removeAdsProductId});
      if (response.productDetails.isEmpty) {
        onError?.call('Remove Ads product not found in the store');
        return PurchaseResult.failed;
      }
      final Completer<PurchaseResult> result = Completer<PurchaseResult>();
      _purchase = result;
      final bool started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
      );
      if (!started) {
        _purchase = null;
        return PurchaseResult.failed;
      }
      final PurchaseResult outcome =
          await result.future.timeout(const Duration(minutes: 5), onTimeout: () => PurchaseResult.pending);
      _purchase = null;
      return outcome;
    } on Object catch (error) {
      onError?.call('purchase failed: $error');
      _purchase = null;
      return PurchaseResult.failed;
    }
  }

  @override
  Future<bool> restore() async {
    start();
    try {
      if (!await _iap.isAvailable()) return false;
      final bool found = await _restoreAndWait(const Duration(seconds: 6));
      await _cache.setString(cacheKey, found ? 'true' : 'false');
      return found;
    } on Object catch (error) {
      onError?.call('restore failed: $error');
      return false;
    }
  }

  @override
  Future<String?> priceText() async {
    try {
      if (!await _iap.isAvailable()) return null;
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(<String>{removeAdsProductId});
      return response.productDetails.isEmpty ? null : response.productDetails.first.price;
    } on Object {
      return null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
