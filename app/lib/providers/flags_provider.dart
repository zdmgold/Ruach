import 'package:flutter/foundation.dart';
import 'package:ruach/core/ports/flags_port.dart';

/// The remote kill switches. They start at the safe defaults and keep the
/// last good value when a fetch fails.
final class FlagsProvider extends ValueNotifier<RemoteFlags> {
  FlagsProvider(this._port) : super(RemoteFlags.defaults);

  final FlagsPort _port;

  Future<void> load() async {
    try {
      value = await _port.fetch();
    } on Object {
      // Keep the last known flags.
    }
  }
}
