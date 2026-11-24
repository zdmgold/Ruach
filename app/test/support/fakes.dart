import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/ports/ads_port.dart';
import 'package:ruach/core/ports/billing_port.dart';
import 'package:ruach/core/ports/consent_port.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/core/ports/file_store.dart';
import 'package:ruach/core/ports/flags_port.dart';

/// An in-memory [FileStore]. Set [failWrites] or [failRenames] to simulate
/// storage errors, or edit [files] to simulate damage.
final class FakeFileStore implements FileStore {
  final Map<String, String> files = <String, String>{};
  bool failWrites = false;
  bool failRenames = false;
  final List<String> calls = <String>[];

  @override
  Future<String?> read(String name) async => files[name];

  @override
  Future<void> write(String name, String content) async {
    calls.add('write $name');
    if (failWrites) throw StateError('disk full');
    files[name] = content;
  }

  @override
  Future<void> rename(String from, String to) async {
    calls.add('rename $from $to');
    if (failRenames) throw StateError('rename failed');
    final String? text = files.remove(from);
    if (text == null) throw StateError('missing $from');
    files[to] = text;
  }

  @override
  Future<void> delete(String name) async {
    calls.add('delete $name');
    files.remove(name);
  }

  @override
  Future<bool> exists(String name) async => files.containsKey(name);
}

/// An in-memory [KeyValueStore].
final class FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// A [BillingPort] you can steer from a test.
final class FakeBilling implements BillingPort {
  bool owns = false;
  bool restoreFinds = false;
  PurchaseResult purchaseResult = PurchaseResult.purchased;
  Object? failWith;
  int reads = 0;

  @override
  Future<bool> ownsRemoveAds() async {
    reads++;
    if (failWith != null) throw failWith!;
    return owns;
  }

  @override
  Future<PurchaseResult> buyRemoveAds() async => purchaseResult;

  @override
  Future<bool> restore() async => restoreFinds;

  @override
  Future<String?> priceText() async => r'$2.99';
}

/// A consent port that answers with whatever [next] holds.
final class FakeConsent implements ConsentPort {
  ConsentSnapshot next = const ConsentSnapshot(
    status: ConsentStatus.unknown,
    canRequestAds: false,
    privacyOptionsRequired: false,
  );
  bool throws = false;

  Future<ConsentSnapshot> _answer() async {
    if (throws) throw StateError('no consent service');
    return next;
  }

  @override
  Future<ConsentSnapshot> refresh() => _answer();

  @override
  Future<ConsentSnapshot> showFormIfRequired() => _answer();

  @override
  Future<ConsentSnapshot> showPrivacyOptions() => _answer();
}

final class FakeAds implements AdsPort {
  final Set<AdFormat> ready = <AdFormat>{};
  final List<AdFormat> shown = <AdFormat>[];
  int initCalls = 0;
  AdShowResult result = AdShowResult.shown;

  @override
  Future<void> initialize() async => initCalls++;

  @override
  Future<bool> load(AdFormat format) async {
    ready.add(format);
    return true;
  }

  @override
  bool isReady(AdFormat format) => ready.contains(format);

  @override
  Future<AdShowResult> show(AdFormat format) async {
    shown.add(format);
    ready.remove(format);
    return result;
  }

  @override
  Future<double> bannerHeight(double width) async => 50;
}

final class FakeFlags implements FlagsPort {
  RemoteFlags flags = RemoteFlags.defaults;
  bool throws = false;

  @override
  Future<RemoteFlags> fetch() async {
    if (throws) throw StateError('offline');
    return flags;
  }
}

final class FakeNotifications implements NotificationPort {
  bool permitted = true;
  final List<String> calls = <String>[];

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async =>
      calls.add('schedule $hour:$minute');

  @override
  Future<void> cancelDaily() async => calls.add('cancel');
}

final class FakeShare implements SharePort {
  final List<String> shared = <String>[];

  @override
  Future<bool> shareText(String text) async {
    shared.add(text);
    return true;
  }
}

final class FakeUrl implements UrlPort {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

final class FakeTilt implements TiltPort {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<double> get roll => const Stream<double>.empty();
}

final class FakeLog implements LogPort {
  final List<String> lines = <String>[];

  @override
  void log(String message) => lines.add(message);

  @override
  Future<String> readAll() async => lines.join('\n');

  @override
  Future<void> clear() async => lines.clear();
}
