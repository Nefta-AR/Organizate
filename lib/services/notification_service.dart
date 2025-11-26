import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:organizate/utils/reminder_options.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _tzInitialized = false;
  static const int _pomodoroNotificationId = 7777;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tareas_channel',
    'Recordatorios Organízate',
    description: 'Notificaciones de tareas y Pomodoro',
    // Importance.max hace que siempre aparezca banner heads-up
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    );

  /// Guía y solicita permisos/ajustes para mejorar la entrega en dispositivos con ROMs agresivas
  static Future<void> ensureDeviceCanDeliverNotifications() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        if (!await Permission.notification.isGranted) {
          final status = await Permission.notification.request();
          if (!status.isGranted) {
            debugPrint('[NOTI] Notificaciones denegadas. Abriendo ajustes de app.');
            await openAppSettings();
          }
        }
      } catch (e) {
        debugPrint('[NOTI] Error solicitando POST_NOTIFICATIONS: $e');
      }

      try {
        final ignoreBattery = Permission.ignoreBatteryOptimizations;
        final status = await ignoreBattery.status;
        if (!status.isGranted) {
          final req = await ignoreBattery.request();
          if (!req.isGranted) {
            debugPrint('[NOTI] Optimización de batería activa. Sugerir desactivarla.');
            await openAppSettings();
          } else {
            debugPrint('[NOTI] Concedido ignoreBatteryOptimizations.');
          }
        }
      } catch (e) {
        debugPrint('[NOTI] No se pudo solicitar ignoreBatteryOptimizations: $e');
      }

      try {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('[NOTI] No se pudo solicitar exact alarm: $e');
      }
    }
  }

  static Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      debugPrint('[NOTI] Notificaciones locales no disponibles en Web.');
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(_channel);

    // 🔥 Solicitar permisos modernos (Android 13+)
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    // Intentar mitigar restricciones de batería (Xiaomi/HyperOS)
    await _tryRequestIgnoreBatteryOptimizations();

    await _configureLocalTimezone();

    _initialized = true;
    debugPrint('[NOTI] Servicio de notificaciones inicializado.');
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      debugPrint('[NOTI] Web no requiere permisos de notificaciones.');
      return true;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('[NOTI] Permiso de notificaciones denegado.');
        return false;
      }

      try {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (!alarmStatus.isGranted) {
          debugPrint('[NOTI] Permiso de alarmas exactas denegado.');
        }
      } catch (_) {
        // Algunos dispositivos no permiten solicitar este permiso por código.
      }
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('[NOTI] Permiso de notificaciones denegado en iOS.');
        return false;
      }
    }

    debugPrint('[NOTI] Permisos de notificación concedidos.');
    return true;
  }

  static NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tareas_channel',
        'Recordatorios Organízate',
        channelDescription: 'Notificaciones de tareas y Pomodoro',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    if (!await _arePermissionsGranted()) return;

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(
      notificationId,
      title,
      body,
      _defaultDetails(),
      payload: payload,
    );
  }

  static Future<NotificationTestResult> showTestNotification({
    bool playPreviewSound = false,
  }) async {
    if (!await _arePermissionsGranted()) {
      return const NotificationTestResult(
        notificationSent: false,
        previewSoundPlayed: false,
        failure: NotificationTestFailure.permissionDenied,
        errorDescription: 'Permiso de notificaciones denegado',
      );
    }

    bool notificationSent = false;
    String? errorDescription;

    try {
      await _plugin.show(
        9999,
        'Prueba de notificación',
        'Si ves esto, las notificaciones están funcionando.',
        _defaultDetails(),
      );
      notificationSent = true;
      debugPrint('[NOTI] Notificación de prueba enviada.');
    } catch (error) {
      debugPrint('[NOTI] Error al mostrar notificación de prueba: $error');
      errorDescription = error.toString();
    }

    bool previewSoundPlayed = false;
    if (playPreviewSound) {
      previewSoundPlayed = await _playTestSoundPreview();
    }

    return NotificationTestResult(
      notificationSent: notificationSent,
      previewSoundPlayed: previewSoundPlayed,
      failure: notificationSent ? null : NotificationTestFailure.unknown,
      errorDescription: errorDescription,
      usedFallbackSound: false,
    );
  }

  static Future<void> showPomodoroFinishedNotification() async {
    if (kIsWeb) return;
    if (!await _arePermissionsGranted()) {
      debugPrint('[NOTI] No hay permiso para mostrar notificación de Pomodoro');
      return;
    }

    await _plugin.show(
      _pomodoroNotificationId,
      'Pomodoro terminado',
      'Buen trabajo, tómate un descanso 😌',
      _defaultDetails(),
    );

    debugPrint('[NOTI] Notificación de Pomodoro mostrada.');
  }

  static Future<void> schedulePomodoroNotification(DateTime endTime) async {
    if (kIsWeb) {
      debugPrint('[NOTI] Pomodoro no disponible en Web.');
      return;
    }

    final hasExactPermission = await _arePermissionsGranted(exact: true);
    final hasBasicPermission =
        hasExactPermission || await _arePermissionsGranted();

    if (!hasBasicPermission) {
      debugPrint('[NOTI] No se programa Pomodoro por falta de permisos');
      return;
    }

    final tzDateTime = tz.TZDateTime.from(endTime, tz.local);

    await _plugin.zonedSchedule(
      _pomodoroNotificationId,
      'Pomodoro terminado',
      'Buen trabajo, tómate un descanso 😌',
      tzDateTime,
      _defaultDetails(),
      androidScheduleMode: hasExactPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'pomodoro',
    );

    debugPrint('[NOTI] Pomodoro programado para $tzDateTime');
  }

  static Future<void> cancelPomodoroNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_pomodoroNotificationId);
    debugPrint('[NOTI] Pomodoro cancelado.');
  }

  static Future<void> scheduleReminderIfNeeded({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    debugPrint('[NOTI] → Entró al método scheduleReminderIfNeeded');
    if (kIsWeb) {
      debugPrint('[NOTI] Recordatorios locales no disponibles en Web.');
      return;
    }

    final hasExactPermission = await _arePermissionsGranted(exact: true);
    final hasBasicPermission =
        hasExactPermission || await _arePermissionsGranted();

    if (!hasBasicPermission) {
      debugPrint('[NOTI] No se programa tarea por falta de permisos');
      return;
    }

    if (dueDate == null || reminderMinutes == null) return;

    final int safeMinutes = reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;

    DateTime scheduledDateTime =
        dueDate.subtract(Duration(minutes: safeMinutes));

    final DateTime now = DateTime.now();
    if (scheduledDateTime.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduledDateTime = now.add(const Duration(seconds: 5));
    }

    final int notificationId = taskId.hashCode & 0x7fffffff;
    try {
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      await _plugin.zonedSchedule(
        notificationId,
        'Recordatorio: $taskTitle',
        'Tarea programada para ${dueDate.toLocal()}',
        tzDateTime,
        _defaultDetails(),
        androidScheduleMode: hasExactPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );
      debugPrint('[NOTI] Recordatorio programado para $tzDateTime');
    } catch (error) {
      debugPrint('[NOTI] Error al programar recordatorio: $error');
    }
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    if (kIsWeb) return;
    final int notificationId = taskId.hashCode & 0x7fffffff;
    await _plugin.cancel(notificationId);
    debugPrint('[NOTI] Notificación cancelada para taskId=$taskId');
  }

  static Future<bool> _playTestSoundPreview() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/Notificacion1.mp3'));
      await player.onPlayerComplete.first;
      return true;
    } catch (error) {
      debugPrint('[NOTI] Error al reproducir preview: $error');
      return false;
    } finally {
      await player.dispose();
    }
  }

  static Future<void> _tryRequestIgnoreBatteryOptimizations() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    try {
      final permission = Permission.ignoreBatteryOptimizations;
      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        if (result.isGranted) {
          debugPrint('[NOTI] Ignorando optimización de batería concedido.');
        } else {
          debugPrint('[NOTI] Usuario no concedió ignorar optimización de batería.');
        }
      }
    } catch (e) {
      debugPrint('[NOTI] Error solicitando ignorar optimización de batería: $e');
    }
  }

  static Future<bool> _arePermissionsGranted({bool exact = false}) async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final hasNotifications = await Permission.notification.isGranted;
      if (!hasNotifications) return false;
      if (exact) return await _hasExactAlarmPermission();
      return true;
    }
    if (Platform.isIOS) return await Permission.notification.isGranted;
    return false;
  }

  static Future<bool> _hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (_) {
      // Android < 12 no requiere este permiso
      return true;
    }
  }

  static Future<void> _configureLocalTimezone() async {
    if (_tzInitialized) return;
    try {
      tz.initializeTimeZones();
      final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone));
      debugPrint('[NOTI] Timezone configurado: $timeZone');
      _tzInitialized = true;
    } catch (e) {
      debugPrint('[NOTI] No se pudo configurar timezone, fallback UTC: $e');
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      _tzInitialized = true;
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NOTI] Notification tapped with payload=${response.payload}');
  }
}

class NotificationTestResult {
  final bool notificationSent;
  final bool previewSoundPlayed;
  final NotificationTestFailure? failure;
  final String? errorDescription;
  final bool usedFallbackSound;

  const NotificationTestResult({
    required this.notificationSent,
    required this.previewSoundPlayed,
    this.failure,
    this.errorDescription,
    this.usedFallbackSound = false,
  });
}

enum NotificationTestFailure {
  permissionDenied,
  permissionPermanentlyDenied,
  unknown,
}
