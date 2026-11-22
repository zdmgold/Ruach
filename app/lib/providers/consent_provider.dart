import 'package:flutter/foundation.dart';
import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/ports/consent_port.dart';
import 'package:ruach/providers/entitlement_provider.dart';

/// What the game may ask the ad network for: the consent answer joined with
/// the Remove Ads purchase. Until consent says ads may be requested, nothing
/// asks for one.
final class ConsentProvider extends ValueNotifier<AdState> {
  ConsentProvider(this._port, this._entitlement)
      : super(AdState.initial.copyWith(adsRemoved: _entitlement.adsRemoved)) {
    _entitlement.addListener(_onEntitlement);
  }

  final ConsentPort _port;
  final EntitlementProvider _entitlement;

  void _onEntitlement() {
    value = value.copyWith(adsRemoved: _entitlement.adsRemoved);
  }

  void _apply(ConsentSnapshot s) {
    value = value.copyWith(
      consentStatus: s.status,
      canRequestAds: s.canRequestAds,
      privacyOptionsRequired: s.privacyOptionsRequired,
      adsRemoved: _entitlement.adsRemoved,
    );
  }

  /// Reads the stored consent answer. A failure leaves ads off.
  Future<void> refresh() => _run(_port.refresh);

  /// Shows the consent form when the law needs one, at the start of a session.
  Future<void> showFormIfRequired() => _run(_port.showFormIfRequired);

  /// Opens the privacy options (Settings, when the region requires them).
  Future<void> showPrivacyOptions() => _run(_port.showPrivacyOptions);

  Future<void> _run(Future<ConsentSnapshot> Function() call) async {
    try {
      _apply(await call());
    } on Object {
      value = value.copyWith(canRequestAds: false);
    }
  }

  @override
  void dispose() {
    _entitlement.removeListener(_onEntitlement);
    super.dispose();
  }
}
