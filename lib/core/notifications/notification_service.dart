import 'dart:ui';
import 'package:flutter/material.dart';
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

    // Création du canal Android (Obligatoire pour les versions récentes)
    const androidChannel = AndroidNotificationChannel(
      'budget_channel', 
      'Alertes Budget',
      description: 'Notifications de dépassement de budget',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Demander la permission
    await requestPermission();
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Notification de test
  static Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      'Test Stouchy',
      'Si vous voyez ceci, les notifications fonctionnent ! ✅',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_channel', 'Alertes Budget',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }

  static Future<void> showBudgetAlert(double spent, double limit, String symbol) async {
    await _plugin.show(
      1,
      '⚠️ Budget dépassé !',
      'Vous avez dépensé ${spent.toStringAsFixed(0)} $symbol sur ${limit.toStringAsFixed(0)} $symbol ce mois',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_channel', 'Alertes Budget',
          channelDescription: 'Notifications de dépassement de budget',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFE53935),
        ),
        iOS: DarwinNotificationDetails(badgeNumber: 1),
      ),
    );
  }

  static Future<void> showRecurringTransactionAlert({
    required String title,
    required double amount,
    required String symbol,
    required bool isExpense,
  }) async {
    final type = isExpense ? 'dépense' : 'revenu';
    final icon = isExpense ? '💸' : '💰';
    await _plugin.show(
      DateTime.now().millisecond + title.hashCode, 
      '$icon Transaction enregistrée',
      'Votre $type "$title" de $amount $symbol a été ajouté.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_channel', 'Transactions Récurrentes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required double amount,
    required String symbol,
    required DateTime scheduledDate,
    required bool isExpense,
  }) async {
    final type = isExpense ? 'dépense' : 'revenu';
    final icon = isExpense ? '💸' : '💰';
    
    // Utilisation de inexactAllowWhileIdle pour éviter les erreurs de permission Android 12+
    await _plugin.zonedSchedule(
      id,
      '$icon Rappel : Transaction prévue',
      'Votre $type "$title" de $amount $symbol sera enregistré aujourd\'hui.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_channel', 'Transactions Récurrentes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> scheduleDailyReminder() async {
    await _plugin.zonedSchedule(
      2,
      '💰 Stouchy',
      'N\'oubliez pas de saisir vos dépenses du jour !',
      _nextInstanceOf(20, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails('reminder_channel', 'Rappels quotidiens',
            importance: Importance.defaultImportance),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
}
