import 'package:flutter/widgets.dart';

/// The one place that names icon symbols. The rest of the app asks for a
/// meaning (`AppIcons.settings`), never a symbol, so the icon set can change
/// by editing this file only. Each symbol appears here once.
///
/// The symbols are the Bold weight of Phosphor Icons (MIT), bundled as the
/// font family `PhosphorBold` (see pubspec.yaml and decision D-021). Bold has
/// a stroke of about 2.25 px at 24 px, matching the 2.0 to 2.25 rule in the
/// design system. The comment after each symbol is its Phosphor name.
///
/// Icons that point in a direction (back, forward) set `matchTextDirection`,
/// so they mirror in right-to-left languages. All other icons keep their
/// shape in every language.
abstract final class AppIcons {
  static const String _family = 'PhosphorBold';

  // Navigation and chrome
  static const IconData home = IconData(0xe2c2, fontFamily: _family); // house
  static const IconData settings = IconData(0xe270, fontFamily: _family); // gear
  static const IconData back = IconData(0xe138, fontFamily: _family, matchTextDirection: true); // caretLeft
  static const IconData forward = IconData(0xe13a, fontFamily: _family, matchTextDirection: true); // caretRight
  static const IconData close = IconData(0xe4f6, fontFamily: _family); // x
  static const IconData check = IconData(0xe182, fontFamily: _family); // check
  static const IconData info = IconData(0xe2ce, fontFamily: _family); // info
  static const IconData warning = IconData(0xe4e0, fontFamily: _family); // warning

  // Race and progress
  static const IconData play = IconData(0xe3d0, fontFamily: _family); // play
  static const IconData pause = IconData(0xe39e, fontFamily: _family); // pause
  static const IconData restart = IconData(0xe038, fontFamily: _family); // arrowCounterClockwise
  static const IconData boost = IconData(0xe2de, fontFamily: _family); // lightning
  static const IconData speed = IconData(0xee74, fontFamily: _family); // speedometer
  static const IconData trophy = IconData(0xe67e, fontFamily: _family); // trophy
  static const IconData finishFlag = IconData(0xea38, fontFamily: _family); // flagCheckered
  static const IconData vehicle = IconData(0xe112, fontFamily: _family); // car
  static const IconData garage = IconData(0xe5d4, fontFamily: _family); // wrench
  static const IconData star = IconData(0xe46a, fontFamily: _family); // star
  static const IconData gift = IconData(0xe276, fontFamily: _family); // gift
  static const IconData locked = IconData(0xe2fa, fontFamily: _family); // lock

  // Modes
  static const IconData journey = IconData(0xe31a, fontFamily: _family); // mapTrifold
  static const IconData timeTrial = IconData(0xe492, fontFamily: _family); // timer
  static const IconData dailyRun = IconData(0xe712, fontFamily: _family); // calendarCheck
  static const IconData weeklyCircuit = IconData(0xe7b4, fontFamily: _family); // calendarDots
  static const IconData escapeRun = IconData(0xe5d2, fontFamily: _family); // wind
  static const IconData elimination = IconData(0xe47c, fontFamily: _family); // target

  // Scripture
  static const IconData verse = IconData(0xe8f2, fontFamily: _family); // bookOpenText
  static const IconData share = IconData(0xe408, fontFamily: _family); // shareNetwork

  // Settings
  static const IconData reminderOn = IconData(0xe0ce, fontFamily: _family); // bell
  static const IconData reminderOff = IconData(0xe0d4, fontFamily: _family); // bellSlash
  static const IconData soundOn = IconData(0xe44a, fontFamily: _family); // speakerHigh
  static const IconData soundOff = IconData(0xe45c, fontFamily: _family); // speakerX
  static const IconData haptics = IconData(0xe4d8, fontFamily: _family); // vibrate
  static const IconData tilt = IconData(0xe1e0, fontFamily: _family); // deviceMobile
  static const IconData language = IconData(0xe4a2, fontFamily: _family); // translate
  static const IconData themeDark = IconData(0xe330, fontFamily: _family); // moon
  static const IconData themeLight = IconData(0xe472, fontFamily: _family); // sun
  static const IconData privacy = IconData(0xe40c, fontFamily: _family); // shieldCheck
  static const IconData licenses = IconData(0xeb7a, fontFamily: _family); // scroll
  static const IconData support = IconData(0xe63a, fontFamily: _family); // lifebuoy
  static const IconData restorePurchase = IconData(0xe1a0, fontFamily: _family); // clockCounterClockwise
  static const IconData removeAds = IconData(0xe3de, fontFamily: _family); // prohibit
}
