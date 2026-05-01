import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    // Demander permission Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Notification immédiate (budget dépassé)
  static Future<void> showBudgetAlert(double spent, double limit) async {
    await _plugin.show(
      1,
      '⚠️ Budget dépassé !',
      'Vous avez dépensé ${spent.toStringAsFixed(0)} TND sur ${limit.toStringAsFixed(0)} TND ce mois',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_channel', 'Alertes Budget',
          channelDescription: 'Notifications de dépassement de budget',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFE53935),
        ),
        iOS: DarwinNotificationDetails(badgeNumber: 1),
      ),
    );
  }

  // Notification quotidienne de rappel
  static Future<void> scheduleDailyReminder() async {
    await _plugin.zonedSchedule(
      2,
      '💰 BudgetApp',
      'N\'oubliez pas de saisir vos dépenses du jour !',
      _nextInstanceOf(20, 0), // chaque soir à 20h00
      const NotificationDetails(
        android: AndroidNotificationDetails('reminder_channel', 'Rappels quotidiens',
            importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}