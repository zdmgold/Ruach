import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/ports/ports.dart';

void main() {
  test('flags default to on when missing or malformed', () {
    expect(RemoteFlags.fromJson(null), RemoteFlags.defaults);
    expect(RemoteFlags.fromJson('x'), RemoteFlags.defaults);
    expect(RemoteFlags.fromJson(<String, Object?>{'adsEnabled': 'no'}), RemoteFlags.defaults);
  });

  test('flags read booleans and ignore unknown keys', () {
    final RemoteFlags f = RemoteFlags.fromJson(<String, Object?>{
      'adsEnabled': false,
      'readerDownloadEnabled': true,
      'other': 1,
    });
    expect(f.adsEnabled, isFalse);
    expect(f.readerDownloadEnabled, isTrue);
  });

  test('the product id is the locked one', () {
    expect(removeAdsProductId, 'com.zdmgold.ruach.removeads');
  });
}
