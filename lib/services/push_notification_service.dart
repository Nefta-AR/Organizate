import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:organizate/utils/reminder_options.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenSubscription;
  static String? _currentUserId;

  static Future<void> initialize() async {
    if (_initialized) return;
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[PUSH] Permiso FCM: ${settings.authorizationStatus}');

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _initialized = true;
  }

  static Future<void> syncUserToken(User user) async {
    final messaging = FirebaseMessaging.instance;
    if (_currentUserId != user.uid) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      _currentUserId = user.uid;
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    _tokenSubscription ??= messaging.onTokenRefresh.listen((newToken) {
      _saveToken(user.uid, newToken);
    });
  }

  /// Encola en Firestore un recordatorio para ser enviado por FCM.
  static Future<void> queueRemoteReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    required DateTime? dueDate,
    required int? reminderMinutes,
  }) async {
    if (dueDate == null || reminderMinutes == null) return;

    final safeMinutes = reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;

    DateTime scheduledDateTime =
        dueDate.toUtc().subtract(Duration(minutes: safeMinutes));
    final DateTime nowUtc = DateTime.now().toUtc();
    if (scheduledDateTime.isBefore(nowUtc.add(const Duration(seconds: 5)))) {
      scheduledDateTime = nowUtc.add(const Duration(seconds: 5));
    }

    await userDocRef.collection('notificationQueue').doc(taskId).set({
      'taskId': taskId,
      'taskTitle': taskTitle,
      'dueDate': Timestamp.fromDate(dueDate.toUtc()),
      'reminderMinutes': safeMinutes,
      'runAt': Timestamp.fromDate(scheduledDateTime),
      'status': 'pending',
      'type': 'task',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> cancelRemoteReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
  }) async {
    await userDocRef.collection('notificationQueue').doc(taskId).delete();
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final String? title = notification?.title ?? message.data['title']?.toString();
    final String? body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) {
      debugPrint('[PUSH] Mensaje sin título/cuerpo: ${message.data}');
      return;
    }

    await NotificationService.showInstantNotification(
      title: title ?? 'Organízate',
      body: body ?? '',
      payload: message.data['payload']?.toString(),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[PUSH] Notificación abierta con data=${message.data}');
  }

  static Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[PUSH] No se pudo guardar token FCM: $e');
    }
  }
}
