import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/app_error.dart';

String _treatment(AppError e) => switch (e) {
      UserActionError() => 'inline retry',
      SystemError() => 'auto retry then retry',
      ThirdPartyError() => 'collapse',
      SensorError() => 'fall back to buttons',
      StorageError() => 'banner',
      UnexpectedError() => 'full screen',
    };

void main() {
  test('every class has one treatment and only unexpected errors block', () {
    final List<AppError> all = <AppError>[
      const UserActionError('declined'),
      const SystemError('hash mismatch'),
      const ThirdPartyError('ads', 'init failed'),
      const SensorError('no accelerometer'),
      const StorageError('disk full'),
      const UnexpectedError('boom'),
    ];
    for (final AppError e in all) {
      expect(_treatment(e), isNotEmpty);
      expect(e.blocksScreen, e is UnexpectedError);
    }
  });

  test('retry is offered where the taxonomy says so', () {
    expect(const UserActionError('x').offersRetry, isTrue);
    expect(const SystemError('x').offersRetry, isTrue);
    expect(const StorageError('x').offersRetry, isTrue);
    expect(const UnexpectedError('x').offersRetry, isTrue);
    expect(const ThirdPartyError('ads', 'x').offersRetry, isFalse);
    expect(const SensorError('x').offersRetry, isFalse);
  });

  test('the log text names the class and the detail', () {
    expect(const ThirdPartyError('ads', 'init failed').toString(), contains('init failed'));
    expect(const ThirdPartyError('ads', 'init failed').source, 'ads');
  });
}
