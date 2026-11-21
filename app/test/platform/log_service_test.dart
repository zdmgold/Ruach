import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/platform/log_service.dart';

import '../support/fakes.dart';

void main() {
  final DateTime fixed = DateTime.utc(2026, 11, 21, 12);

  test('lines are stamped, trimmed to the newest, and written on flush', () async {
    final FakeFileStore store = FakeFileStore();
    final LogService log = LogService(store, maxLines: 3, now: () => fixed);
    for (int i = 1; i <= 5; i++) {
      log.log('line $i');
    }
    await log.flush();
    final String text = store.files[LogService.fileName]!;
    expect(text.trim().split('\n').length, 3);
    expect(text, contains('line 5'));
    expect(text, isNot(contains('line 1')));
    expect(text, startsWith('2026-11-21T12:00:00.000Z '));
  });

  test('multi-line messages become several lines and blanks are dropped', () async {
    final LogService log = LogService(FakeFileStore(), now: () => fixed);
    log.log('a\n\nb');
    expect((await log.readAll()).split('\n').length, 2);
  });

  test('earlier lines are loaded and kept', () async {
    final FakeFileStore store = FakeFileStore()..files[LogService.fileName] = 'old 1\nold 2\n';
    final LogService log = LogService(store, now: () => fixed);
    log.log('new');
    final String all = await log.readAll();
    expect(all.split('\n').first, 'old 1');
    expect(all, contains('new'));
  });

  test('clear empties memory and file; storage failures never throw', () async {
    final FakeFileStore store = FakeFileStore();
    final LogService log = LogService(store, now: () => fixed);
    log.log('x');
    await log.clear();
    expect(await log.readAll(), '');
    expect(store.files[LogService.fileName], '');
    store.failWrites = true;
    log.log('y');
    await log.flush();
  });
}
