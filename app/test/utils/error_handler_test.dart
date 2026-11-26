import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/utils/error_handler.dart';

void main() {
  late List<String> seen;
  late AppErrorHandler handler;

  setUp(() {
    seen = <String>[];
    handler = AppErrorHandler(
      (Object error, StackTrace? stack, {required bool fatal}) {
        seen.add('${fatal ? 'fatal' : 'recoverable'}: $error');
      },
    );
  });

  test('a recoverable error is reported and does not set the fatal state', () {
    handler.report('disk full', null);
    expect(seen, <String>['recoverable: disk full']);
    expect(handler.fatal.value, isNull);
  });

  test('a fatal error is reported and published', () {
    handler.report('boom', StackTrace.empty, fatal: true);
    expect(seen, <String>['fatal: boom']);
    expect(handler.fatal.value, isNotNull);
    expect(handler.fatal.value!.error, 'boom');
  });

  test('clear returns the app to normal', () {
    handler.report('boom', null, fatal: true);
    handler.clear();
    expect(handler.fatal.value, isNull);
  });

  test('a reporter that throws does not hide the error state', () {
    final AppErrorHandler throwing = AppErrorHandler(
      (Object error, StackTrace? stack, {required bool fatal}) {
        throw StateError('reporter failed');
      },
    );
    throwing.report('boom', null, fatal: true);
    expect(throwing.fatal.value, isNotNull);
  });

  test('install routes framework errors to the reporter as recoverable', () {
    final FlutterExceptionHandler? original = FlutterError.onError;
    addTearDown(() => FlutterError.onError = original);

    handler.install();
    FlutterError.onError!(FlutterErrorDetails(exception: 'layout failed'));

    expect(seen, <String>['recoverable: layout failed']);
    expect(handler.fatal.value, isNull);
  });

  test('a widget that fails to build takes the app to the fallback', () {
    final FlutterExceptionHandler? original = FlutterError.onError;
    addTearDown(() => FlutterError.onError = original);

    handler.install();
    FlutterError.onError!(
      FlutterErrorDetails(exception: 'build failed', library: 'widgets library'),
    );

    expect(seen, <String>['fatal: build failed']);
    expect(handler.fatal.value, isNotNull);
  });
}
