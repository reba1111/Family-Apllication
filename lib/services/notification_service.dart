import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return; // web doesn't support local notifications

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // ── Lessons ─────────────────────────────────────────────────────────────────

  Future<void> scheduleLesson({
    required int id,
    required String title,
    required String subject,
    required DateTime dateTime,
    required int minutesBefore,
  }) async {
    if (kIsWeb) return;

    final notifyAt = dateTime.subtract(Duration(minutes: minutesBefore));
    if (notifyAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      AppConstants.lessonNotificationBase + (id % 5000),
      '📚 وانە نزیکایەتی دەبێت!',
      subject.isNotEmpty
          ? '$title — $subject  ⏰ ${_fmt(dateTime)}'
          : '$title  ⏰ ${_fmt(dateTime)}',
      tz.TZDateTime.from(notifyAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lessons_channel',
          'وانەکان',
          channelDescription: 'ئاگادارکردنەوەی وانەکان',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFE91E8C),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelLesson(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(AppConstants.lessonNotificationBase + (id % 5000));
  }

  // ── Tasks ────────────────────────────────────────────────────────────────────

  Future<void> scheduleTask({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) return;

    // Notify 1 hour before due date
    final notifyAt = dueDate.subtract(const Duration(hours: 1));
    if (notifyAt.isBefore(DateTime.now())) return;

    final id = AppConstants.taskNotificationBase + (taskId.hashCode % 4000);
    await _plugin.zonedSchedule(
      id,
      '✅ تاسک نزیکایەتی دەبێت!',
      '$title — کاتی تواوبوون: ${_fmtDate(dueDate)}',
      tz.TZDateTime.from(notifyAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'تاسکەکان',
          channelDescription: 'ئاگادارکردنەوەی تاسکەکان',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF4CAF81),
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTask(String taskId) async {
    if (kIsWeb) return;
    await _plugin.cancel(
        AppConstants.taskNotificationBase + (taskId.hashCode % 4000));
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}
