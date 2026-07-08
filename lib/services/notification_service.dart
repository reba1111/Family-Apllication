import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here if needed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    if (kIsWeb) return; // web doesn't support local notifications in this setup

    // Local notifications setup
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Firebase Messaging Setup
    await _requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Listen to messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Save token to Firestore when it's updated
    _fcm.onTokenRefresh.listen((String token) {
      FirestoreService().updateFCMToken(token);
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirestoreService().updateFCMToken(token);
      }
    }
  }

  Future<void> _showLocalNotification({required String title, required String body}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'push_channel',
        'ئاگادارکردنەوەکان',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFE91E8C),
      ),
      iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true),
    );
    await _plugin.show(DateTime.now().millisecond, title, body, details);
  }

  // ── Push Notification Sender ───────────────────────────────────────────────

  /// Sends a push notification via HTTP v1 API using a Service Account JSON.
  Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      final String response = await rootBundle.loadString('assets/service_account.json');
      final Map<String, dynamic> accountCredentials = jsonDecode(response);
      final String projectId = accountCredentials['project_id'];

      final credentials = auth.ServiceAccountCredentials.fromJson(accountCredentials);
      final client = await auth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      final Map<String, dynamic> message = {
        'message': {
          'token': targetToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
              }
            }
          }
        }
      };

      await client.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );
      client.close();
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // ── Lessons & Tasks (Existing) ──────────────────────────────────────────

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
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFE91E8C),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelLesson(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(AppConstants.lessonNotificationBase + (id % 5000));
  }

  Future<void> scheduleTask({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) return;
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
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF4CAF81),
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTask(String taskId) async {
    if (kIsWeb) return;
    await _plugin.cancel(AppConstants.taskNotificationBase + (taskId.hashCode % 4000));
  }

  // ── Events / Calendar ─────────────────────────────────────────────────────

  Future<void> scheduleEvent({
    required String eventId,
    required String title,
    required String icon,
    required DateTime date,
  }) async {
    if (kIsWeb) return;
    
    // Notify 1 day before the event
    final notifyAt = date.subtract(const Duration(days: 1));
    if (notifyAt.isBefore(DateTime.now())) return;
    
    final id = 10000 + (eventId.hashCode % 5000);
    await _plugin.zonedSchedule(
      id,
      'بۆنە نزیکە! $icon',
      'بەیانی $title یە! خۆت ئامادە بکە 🎉',
      tz.TZDateTime.from(notifyAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'events_channel',
          'بۆنەکان',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF673AB7),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(sound: 'default'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelEvent(String eventId) async {
    if (kIsWeb) return;
    await _plugin.cancel(10000 + (eventId.hashCode % 5000));
  }


  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}
