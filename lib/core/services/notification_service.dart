import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/reminder_options.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _tzInitialized = false;
  static const int _pomodoroNotificationId = 7777;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tareas_channel',
    'Recordatorios Simple',
    description: 'Notificaciones de tareas y Pomodoro de la app Simple',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> ensureDeviceCanDeliverNotifications() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;

    try {
      if (!await Permission.notification.isGranted) {
        final status = await Permission.notification.request();
        if (!status.isGranted) await openAppSettings();
      }
    } catch (_) {}

    try {
      const ignoreBattery = Permission.ignoreBatteryOptimizations;
      final status = await ignoreBattery.status;
      if (!status.isGranted) {
        final req = await ignoreBattery.request();
        if (!req.isGranted) await openAppSettings();
      }
    } catch (_) {}

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    await _tryRequestIgnoreBatteryOptimizations();
    await _configureLocalTimezone();

    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;

      try {
        await Permission.scheduleExactAlarm.request();
      } catch (_) {}
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    return true;
  }

  static NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tareas_channel',
        'Recordatorios Simple',
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
    if (!_initialized) await init();
    if (!await _arePermissionsGranted()) return;

    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(notificationId, title, body, _defaultDetails(), payload: payload);
  }

  static Future<NotificationTestResult> showTestNotification({bool playPreviewSound = false}) async {
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
    } catch (error) {
      errorDescription = error.toString();
    }

    final bool previewSoundPlayed = playPreviewSound ? await _playTestSoundPreview() : false;

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
    if (!await _arePermissionsGranted()) return;

    await _plugin.show(
      _pomodoroNotificationId,
      'Pomodoro terminado',
      'Buen trabajo, tómate un descanso 😌',
      _defaultDetails(),
    );
  }

  static Future<void> schedulePomodoroNotification(DateTime endTime) async {
    if (kIsWeb) return;

    final hasExactPermission = await _arePermissionsGranted(exact: true);
    final hasBasicPermission = hasExactPermission || await _arePermissionsGranted();
    if (!hasBasicPermission) return;

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
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'pomodoro',
    );
  }

  static Future<void> cancelPomodoroNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_pomodoroNotificationId);
  }

  static Future<void> scheduleReminderIfNeeded({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (kIsWeb) return;
    if (dueDate == null || reminderMinutes == null) return;

    final hasExactPermission = await _arePermissionsGranted(exact: true);
    final hasBasicPermission = hasExactPermission || await _arePermissionsGranted();
    if (!hasBasicPermission) return;

    final int safeMinutes = reminderMinutes < kMinimumReminderMinutes ? kMinimumReminderMinutes : reminderMinutes;

    DateTime scheduledDateTime = dueDate.subtract(Duration(minutes: safeMinutes));
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );
    } catch (error) {
      debugPrint('[NOTI] Error al programar recordatorio: $error');
    }
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    if (kIsWeb) return;
    final int notificationId = taskId.hashCode & 0x7fffffff;
    await _plugin.cancel(notificationId);
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
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      const permission = Permission.ignoreBatteryOptimizations;
      if (!await permission.isGranted) await permission.request();
    } catch (_) {}
  }

  static Future<bool> _arePermissionsGranted({bool exact = false}) async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      if (!await Permission.notification.isGranted) return false;
      if (exact) return await _hasExactAlarmPermission();
      return true;
    }
    if (Platform.isIOS) return await Permission.notification.isGranted;
    return false;
  }

  static Future<bool> _hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _configureLocalTimezone() async {
    if (_tzInitialized) return;
    try {
      tz.initializeTimeZones();
      final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone));
    } catch (_) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _tzInitialized = true;
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
