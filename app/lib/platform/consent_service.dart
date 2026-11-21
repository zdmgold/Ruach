import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/ports/consent_port.dart';

/// Google's User Messaging Platform. Every ad request depends on the
/// `canRequestAds` value reported here (blueprint section 7). A failed or
/// offline refresh keeps what UMP stored last; it never resets consent.
final class ConsentService implements ConsentPort {
  ConsentService({this.onError});

  final void Function(String message)? onError;

  /// The state before anything has been read: no ads may be requested.
  static const ConsentSnapshot unread = ConsentSnapshot(
    status: ConsentStatus.unknown,
    canRequestAds: false,
    privacyOptionsRequired: false,
  );

  ConsentSnapshot _last = unread;

  static ConsentStatus mapStatus(gma.ConsentStatus status) => switch (status) {
        gma.ConsentStatus.notRequired => ConsentStatus.notRequired,
        gma.ConsentStatus.required => ConsentStatus.required,
        gma.ConsentStatus.obtained => ConsentStatus.obtained,
        gma.ConsentStatus.unknown => ConsentStatus.unknown,
      };

  @override
  Future<ConsentSnapshot> refresh() async {
    final Completer<void> done = Completer<void>();
    try {
      gma.ConsentInformation.instance.requestConsentInfoUpdate(
        gma.ConsentRequestParameters(),
        () {
          if (!done.isCompleted) done.complete();
        },
        (gma.FormError error) {
          onError?.call('consent refresh failed: ${error.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 10));
    } on Object catch (error) {
      onError?.call('consent refresh failed: $error');
    }
    return _read();
  }

  @override
  Future<ConsentSnapshot> showFormIfRequired() async {
    try {
      await gma.ConsentForm.loadAndShowConsentFormIfRequired((gma.FormError? error) {
        if (error != null) onError?.call('consent form failed: ${error.message}');
      });
    } on Object catch (error) {
      onError?.call('consent form failed: $error');
    }
    return _read();
  }

  @override
  Future<ConsentSnapshot> showPrivacyOptions() async {
    try {
      await gma.ConsentForm.showPrivacyOptionsForm((gma.FormError? error) {
        if (error != null) onError?.call('privacy options failed: ${error.message}');
      });
    } on Object catch (error) {
      onError?.call('privacy options failed: $error');
    }
    return _read();
  }

  Future<ConsentSnapshot> _read() async {
    final gma.ConsentInformation info = gma.ConsentInformation.instance;
    try {
      final ConsentStatus status = mapStatus(await info.getConsentStatus());
      final bool canRequest = await info.canRequestAds();
      final bool options = await info.getPrivacyOptionsRequirementStatus() ==
          gma.PrivacyOptionsRequirementStatus.required;
      _last = ConsentSnapshot(
        status: status,
        canRequestAds: canRequest,
        privacyOptionsRequired: options,
      );
    } on Object catch (error) {
      onError?.call('consent read failed: $error');
    }
    return _last;
  }
}
