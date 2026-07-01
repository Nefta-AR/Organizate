// ============================================================
// lib/core/services/push_notification_service.dart
// ============================================================
// Servicio de notificaciones push remotas via Firebase Cloud Messaging (FCM).
//
// ## Arquitectura de notificaciones remotas
//
//   Flutter app → Firestore `notificationQueue/{taskId}` → Cloud Functions
//   → FCM → Dispositivo del usuario
//
// El diseño con cola en Firestore permite que las notificaciones
// se envíen aunque la app no esté abierta. Cloud Functions sondea
// la cola y envía las FCM programadas con exactitud de segundos.
//
// ## Función `firebaseMessagingBackgroundHandler`
//
// Debe ser top-level (no un método de clase) y estar anotada con
// @pragma('vm:entry-point') para que el AOT compiler no la elimine.
// Se registra en main.dart via [FirebaseMessaging.onBackgroundMessage].
//
// ## Tokens FCM
//
// [syncUserToken] guarda el token del dispositivo en Firestore bajo
// `users/{uid}/fcmTokens` (arrayUnion). Cloud Functions lee esta
// lista para enviar la push al dispositivo correcto del usuario.
// ============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../utils/reminder_options.dart';
import 'notification_service.dart';

/// Manejador de mensajes FCM en background. Debe ser función top-level.
/// Se registra en main.dart con [FirebaseMessaging.onBackgroundMessage].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase debe inicializarse en el contexto isolado de background.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // No es necesario mostrar notificación aquí: FCM la muestra automáticamente.
}

/// Servicio de push notifications remotas via FCM.
class PushNotificationService {
  PushNotificationService._(); // Clase puramente estática

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenSubscription;
  static String? _currentUserId;

  /// Inicializa FCM: solicita permisos, configura opciones de presentación
  /// y registra listeners de mensajes en foreground y al abrir la app.
  static Future<void> initialize() async {
    if (_initialized) return;

    final messaging = FirebaseMessaging.instance;

    // Solicitar permisos al usuario (iOS requiere esto explícitamente)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[PUSH] Permiso FCM: ${settings.authorizationStatus}');

    // En iOS, las notificaciones en foreground no se muestran por defecto
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listener para mensajes mientras la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // Listener para cuando el usuario toca una notificación y abre la app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _initialized = true;
  }

  /// Guarda el token FCM del [user] en Firestore y suscribe al refresh.
  ///
  /// Se llama después de cada login exitoso. Si el usuario cambia,
  /// cancela la suscripción anterior y crea una nueva para el nuevo UID.
  static Future<void> syncUserToken(User user) async {
    final messaging = FirebaseMessaging.instance;

    // Si el usuario cambió, cancelar la suscripción al token del usuario anterior
    if (_currentUserId != user.uid) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      _currentUserId = user.uid;
    }

    // Guardar el token actual
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('[PUSH] Token actual: $token');
      await _saveToken(user.uid, token);
    }

    // Suscribirse a los refrescos de token (FCM rota tokens periódicamente)
    _tokenSubscription ??= messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[PUSH] Token refrescado: $newToken');
      await _saveToken(user.uid, newToken);
    });
  }

  /// Encola un recordatorio remoto en Firestore para [taskId].
  ///
  /// [runAt] se calcula como: dueDate - reminderMinutes.
  /// Si ese momento ya pasó, se programa 5 segundos en el futuro.
  /// Cloud Functions procesa la cola y envía la FCM en el momento indicado.
  static Future<void> queueRemoteReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (dueDate == null || reminderMinutes == null) {
      throw ArgumentError('dueDate y reminderMinutes son requeridos para encolar un recordatorio remoto');
    }

    // Aplica el piso mínimo
    final normalizedMinutes = reminderMinutes < kMinimumReminderMinutes ? kMinimumReminderMinutes : reminderMinutes;

    final now = DateTime.now();
    final scheduledAt = dueDate.toLocal().subtract(Duration(minutes: normalizedMinutes));
    // Si el momento ya pasó, program 5 segundos en el futuro (para pruebas/debug)
    final runAt = scheduledAt.isBefore(now) ? now.add(const Duration(seconds: 5)) : scheduledAt;

    await userDocRef.collection('notificationQueue').doc(taskId).set(
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
        'sentAt': FieldValue.delete(),       // Limpiar campos de estado anterior
        'lastError': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );

    debugPrint('[PUSH] Recordatorio remoto encolado para $taskId a las $runAt');
  }

  /// Elimina el recordatorio remoto de la cola para [taskId].
  static Future<void> cancelRemoteReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
  }) async {
    try {
      await userDocRef.collection('notificationQueue').doc(taskId).delete();
      debugPrint('[PUSH] Recordatorio remoto cancelado para $taskId');
    } catch (e) {
      debugPrint('[PUSH] Error cancelando recordatorio remoto $taskId: $e');
      rethrow;
    }
  }

  /// Guarda el token FCM en Firestore usando arrayUnion para no duplicar.
  static Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token])
        },
        SetOptions(merge: true),
      );
      debugPrint('[PUSH] Token guardado correctamente en Firestore');
    } catch (e) {
      debugPrint('[PUSH] Error guardando token: $e');
      rethrow;
    }
  }

  /// Muestra una notificación local cuando llega un mensaje FCM en foreground.
  /// (FCM no muestra notificaciones automáticamente cuando la app está abierta.)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    await NotificationService.showInstantNotification(
      title: title ?? 'Simple',
      body: body ?? '',
      payload: message.data['payload'],
    );
  }

  /// Callback cuando el usuario toca una notificación y abre la app.
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[PUSH] Notificacion abierta con data=${message.data}');
    // TODO: navegar a la pantalla relevante según message.data
  }
}
