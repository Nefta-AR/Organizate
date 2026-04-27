// lib/services/push_notification_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../utils/reminder_options.dart';
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

  /// Inicializa permisos FCM y listeners base.
  static Future<void> initialize() async {
    if (_initialized) return;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
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

  /// Se ejecuta al iniciar sesion, guarda token limpio.
  static Future<void> syncUserToken(User user) async {
    final messaging = FirebaseMessaging.instance;

    if (_currentUserId != user.uid) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      _currentUserId = user.uid;
    }

    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('[PUSH] Token actual: $token');
      await _saveToken(user.uid, token);
    }

    _tokenSubscription ??=
        messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[PUSH] Token refrescado: $newToken');
      await _saveToken(user.uid, newToken);
    });
  }

  /// Encola un recordatorio en Firestore (lo procesa el backend).
  static Future<void> queueRemoteReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (dueDate == null || reminderMinutes == null) {
      throw ArgumentError(
        'dueDate y reminderMinutes son requeridos para encolar un recordatorio remoto',
      );
    }

    final normalizedMinutes = reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;

    final now = DateTime.now();
    final scheduledAt =
        dueDate.toLocal().subtract(Duration(minutes: normalizedMinutes));
    final runAt = scheduledAt.isBefore(now)
        ? now.add(const Duration(seconds: 5))
        : scheduledAt;

    final queueDoc = userDocRef.collection('notificationQueue').doc(taskId);

    await queueDoc.set(
      {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'runAt': Timestamp.fromDate(runAt),
        'status': 'pending',
        'type': 'task',
        'dueDate': Timestamp.fromDate(dueDate),
        'reminderMinutes': normalizedMinutes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sentAt': FieldValue.delete(),
        'lastError': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );

    debugPrint(
      '[PUSH] Recordatorio remoto encolado en notificationQueue para $taskId a las $runAt',
    );
  }

  /// Cancela un recordatorio remoto ya encolado.
  static Future<void> cancelRemoteReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
  }) async {
    final queueDoc = userDocRef.collection('notificationQueue').doc(taskId);
    try {
      await queueDoc.delete();
      debugPrint('[PUSH] Recordatorio remoto cancelado para $taskId');
    } catch (e) {
      debugPrint('[PUSH] Error cancelando recordatorio remoto $taskId: $e');
      rethrow;
    }
  }

  /// Guarda token en el array fcmTokens (sin duplicados).
  static Future<void> _saveToken(String uid, String token) async {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(uid);

      await userDoc.set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      debugPrint('[PUSH] Token guardado correctamente en Firestore');
    } catch (e) {
      debugPrint('[PUSH] Error guardando token: $e');
      rethrow;
    }
  }

  /// Recibe push en foreground y lo convierte en notificacion local.
  static Future<void> _handleForegroundMessage(
      RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null && body == null) {
      debugPrint('[PUSH] Mensaje sin contenido');
      return;
    }

    await NotificationService.showInstantNotification(
      title: title ?? 'Organizate',
      body: body ?? '',
      payload: message.data['payload'],
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[PUSH] Notificacion abierta con data=${message.data}');
  }
}
