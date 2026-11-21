import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/ports/flags_port.dart';
import 'package:ruach/platform/flags_service.dart';

void main() {
  test('no site address means defaults and no request', () async {
    int calls = 0;
    final FlagsService s = FlagsService(url: '', fetcher: (Uri u) async {
      calls++;
      return '{}';
    });
    expect(await s.fetch(), RemoteFlags.defaults);
    expect(calls, 0);
  });

  test('flags are read from the fetched JSON', () async {
    final FlagsService s = FlagsService(
      url: 'https://example.test/flags.json',
      fetcher: (Uri u) async => '{"adsEnabled": false}',
    );
    final RemoteFlags f = await s.fetch();
    expect(f.adsEnabled, isFalse);
    expect(f.readerDownloadEnabled, isTrue);
  });

  test('network errors, bad JSON, bad URLs and timeouts all give defaults', () async {
    Future<RemoteFlags> run(String url, Future<String> Function(Uri) fetcher) =>
        FlagsService(url: url, fetcher: fetcher, timeout: const Duration(milliseconds: 50)).fetch();
    expect(await run('https://x.test/f', (Uri u) async => throw StateError('offline')), RemoteFlags.defaults);
    expect(await run('https://x.test/f', (Uri u) async => 'not json'), RemoteFlags.defaults);
    expect(await run('not a url', (Uri u) async => '{"adsEnabled": false}'), RemoteFlags.defaults);
    expect(
      await run('https://x.test/f', (Uri u) => Future<String>.delayed(const Duration(seconds: 1), () => '{"adsEnabled": false}')),
      RemoteFlags.defaults,
    );
  });
}
