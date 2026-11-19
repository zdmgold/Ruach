/// What the consent platform (UMP) reports about the player's region
/// (blueprint section 7).
enum ConsentStatus {
  /// Not asked yet this launch; no ad request may be made.
  unknown,

  /// The player's region needs no consent form.
  notRequired,

  /// A form is needed and the player has not answered.
  required,

  /// The player has answered, either way.
  obtained,
}

/// Everything the ad gate needs to decide whether an ad may be requested.
/// Immutable.
///
/// `canRequestAds` is the value UMP reports and is the only source for it: the
/// app never infers it from [consentStatus]. A failed or offline refresh keeps
/// the last stored value rather than resetting it.
final class AdState {
  const AdState({
    this.consentStatus = ConsentStatus.unknown,
    this.canRequestAds = false,
    this.privacyOptionsRequired = false,
    this.adsRemoved = false,
  });

  /// Before anything has been read: no ads, no entitlement.
  static const AdState initial = AdState();

  final ConsentStatus consentStatus;

  /// UMP's answer to whether an ad request may be made.
  final bool canRequestAds;

  /// True when Settings must show the Privacy choices row.
  final bool privacyOptionsRequired;

  /// True when the player owns the Remove Ads purchase.
  final bool adsRemoved;

  /// Banners and interstitials need consent and no Remove Ads purchase.
  bool get canShowBanner => canRequestAds && !adsRemoved;

  bool get canShowInterstitial => canRequestAds && !adsRemoved;

  /// Rewarded ads stay available after Remove Ads, because the player opts in.
  bool get canShowRewarded => canRequestAds;

  AdState copyWith({
    ConsentStatus? consentStatus,
    bool? canRequestAds,
    bool? privacyOptionsRequired,
    bool? adsRemoved,
  }) =>
      AdState(
        consentStatus: consentStatus ?? this.consentStatus,
        canRequestAds: canRequestAds ?? this.canRequestAds,
        privacyOptionsRequired:
            privacyOptionsRequired ?? this.privacyOptionsRequired,
        adsRemoved: adsRemoved ?? this.adsRemoved,
      );

  @override
  bool operator ==(Object other) =>
      other is AdState &&
      other.consentStatus == consentStatus &&
      other.canRequestAds == canRequestAds &&
      other.privacyOptionsRequired == privacyOptionsRequired &&
      other.adsRemoved == adsRemoved;

  @override
  int get hashCode => Object.hash(
        consentStatus,
        canRequestAds,
        privacyOptionsRequired,
        adsRemoved,
      );

  @override
  String toString() =>
      'AdState($consentStatus, canRequestAds: $canRequestAds, privacyOptionsRequired: $privacyOptionsRequired, adsRemoved: $adsRemoved)';
}
