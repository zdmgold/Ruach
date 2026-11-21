import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The opt-in Daily Run reminder, a scheduled local notification. Nothing is
/// sent from a server; permission is asked only when the player turns the
/// reminder on.
final class NotificationService implements NotificationPort {
  NotificationService({this.onError});

  final void Function(String message)? onError;

  static const int _dailyId = 1;
  static const String _channelId = 'daily_run';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// The next local time at [hour]:[minute] strictly after [now], as year,
  /// month and day. Pure, so it can be tested without the plugin.
  static DateTime nextOccurrence(DateTime now, int hour, int minute) {
    final DateTime today = DateTime(now.year, now.month, now.day, hour, minute);
    return today.isAfter(now) ? today : DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object catch (error) {
      onError?.call('timezone unavailable, using UTC: $error');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _ensureReady();
      final bool? android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (android != null) return android;
      final bool? ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      return ios ?? false;
    } on Object catch (error) {
      onError?.call('notification permission failed: $error');
      return false;
    }
  }

  @override
  Future<bool> isPermitted() async {
    try {
      await _ensureReady();
      final bool? android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      if (android != null) return android;
      final NotificationsEnabledOptions? ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return ios?.isEnabled ?? false;
    } on Object catch (error) {
      onError?.call('notification check failed: $error');
      return false;
    }
  }

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureReady();
      final DateTime next = nextOccurrence(DateTime.now(), hour, minute);
      final tz.TZDateTime when = tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day,
        next.hour,
        next.minute,
      );
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, 'Daily Run reminder'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object catch (error) {
      onError?.call('scheduling the reminder failed: $error');
    }
  }

  @override
  Future<void> cancelDaily() async {
    try {
      await _ensureReady();
      await _plugin.cancel(id: _dailyId);
    } on Object catch (error) {
      onError?.call('cancelling the reminder failed: $error');
    }
  }
}
