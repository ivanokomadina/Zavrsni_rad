import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/obligation.dart';

/// Servis koji upravlja lokalnim notifikacijama - inicijalizacija, traženje dozvola, zakazivanje i otkazivanje
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _dailyHabitReminderId = 0;

  /// Postavlja plugin i vremensku zonu
  Future<void> initialize() async {
    if (_initialized) return;

    // Učitava bazu podataka svih svjetskih vremenskih zona
    tz_data.initializeTimeZones();

    // Očitava stvarnu vremensku zonu ovog uređaja
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  /// Traži dozvolu za notifikacije od korisnika
  Future<bool> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool granted = true;

    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission() ?? true;
    }
    if (iosImpl != null) {
      granted =
          await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }

    return granted;
  }

  /// Vraća sljedeći termin za zadano vrijeme
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Zakazuje dnevni podsjetnik za navike koji se ponavlja svaki dan u isto vrijeme
  Future<void> scheduleDailyHabitReminder({
    int hour = 8,
    int minute = 0,
  }) async {
    await _plugin.zonedSchedule(
      _dailyHabitReminderId,
      'Trackify podsjetnik',
      'Ne zaboravi odraditi svoje navike za danas!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_habit_channel',
          'Dnevni podsjetnik za navike',
          channelDescription: 'Podsjeća te svaki dan da odradiš navike',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyHabitReminder() async {
    await _plugin.cancel(_dailyHabitReminderId);
  }

  /// Zakazuje podsjetnik za rok jedne obveze
  Future<void> scheduleObligationReminder(Obligation obligation) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      obligation.dueDate.year,
      obligation.dueDate.month,
      obligation.dueDate.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      obligation.id!,
      'Rok danas: ${obligation.name}',
      'Obveza "${obligation.name}" ima rok danas.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'obligation_channel',
          'Podsjetnici za obveze',
          channelDescription: 'Podsjeća te na rokove obveza',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelObligationReminder(int obligationId) async {
    await _plugin.cancel(obligationId);
  }

  /// Otkazuje sve zakazane notifikacije
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
