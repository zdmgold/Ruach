import 'package:flutter/services.dart';
import 'package:ruach/core/ports/device_ports.dart';

/// Vibration feedback through the system haptics. Switched off in Settings.
final class HapticsService implements HapticsPort {
  HapticsService({this.enabled = true});

  bool enabled;

  @override
  Future<void> play(HapticKind kind) async {
    if (!enabled) return;
    try {
      switch (kind) {
        case HapticKind.light:
          await HapticFeedback.lightImpact();
        case HapticKind.medium:
          await HapticFeedback.mediumImpact();
        case HapticKind.heavy:
          await HapticFeedback.heavyImpact();
        case HapticKind.selection:
          await HapticFeedback.selectionClick();
      }
    } on Object {
      // No vibration is not an error.
    }
  }
}
