import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/ports/billing_port.dart';
import 'package:ruach/platform/billing_service.dart';
import 'package:ruach/platform/consent_service.dart';

PurchaseDetails _purchase(String id, PurchaseStatus status) => PurchaseDetails(
      productID: id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    );

void main() {
  test('only a purchased or restored Remove Ads grants the entitlement', () {
    expect(BillingService.grantsRemoveAds(_purchase(removeAdsProductId, PurchaseStatus.purchased)), isTrue);
    expect(BillingService.grantsRemoveAds(_purchase(removeAdsProductId, PurchaseStatus.restored)), isTrue);
    expect(BillingService.grantsRemoveAds(_purchase(removeAdsProductId, PurchaseStatus.pending)), isFalse);
    expect(BillingService.grantsRemoveAds(_purchase(removeAdsProductId, PurchaseStatus.canceled)), isFalse);
    expect(BillingService.grantsRemoveAds(_purchase(removeAdsProductId, PurchaseStatus.error)), isFalse);
    expect(BillingService.grantsRemoveAds(_purchase('other', PurchaseStatus.purchased)), isFalse);
  });

  test('consent statuses map one to one and the unread state allows no ads', () {
    expect(ConsentService.mapStatus(gma.ConsentStatus.required), ConsentStatus.required);
    expect(ConsentService.mapStatus(gma.ConsentStatus.obtained), ConsentStatus.obtained);
    expect(ConsentService.mapStatus(gma.ConsentStatus.notRequired), ConsentStatus.notRequired);
    expect(ConsentService.mapStatus(gma.ConsentStatus.unknown), ConsentStatus.unknown);
    expect(ConsentService.unread.canRequestAds, isFalse);
  });
}
