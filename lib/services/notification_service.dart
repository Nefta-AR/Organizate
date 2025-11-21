import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _timezoneInitialized = false;
  static bool _customSoundAvailable = true;

  static const AndroidNotificationChannel _tasksChannel =
      AndroidNotificationChannel(
    'tareas_channel',
    'Recordatorios de tareas',
    description: 'Notificaciones programadas de tus tareas',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('notificacion1'),
  );

  static FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await _registerTasksChannel();

    await _configureLocalTimeZone();
  }

  static Future<void> scheduleTaskNotification({
    required String taskId,
    required DateTime scheduledTime,
    required String body,
  }) async {
    if (!scheduledTime.isAfter(DateTime.now())) return;
    await _configureLocalTimeZone();

    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await _sendNotificationWithBestSound((details) async {
        await _notificationsPlugin.zonedSchedule(
          taskId.hashCode,
          'Recordatorio de tarea',
          body,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          payload: taskId,
        );
      });
    } catch (_) {
      // Ignoramos fallos para no bloquear la app.
    }
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    await _notificationsPlugin.cancel(taskId.hashCode);
  }

  static Future<void> scheduleReminderIfNeeded({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    required DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (dueDate == null) return;
    if (reminderMinutes == null || reminderMinutes <= 0) return;

    try {
      final snapshot = await userDocRef.get();
      final data = snapshot.data();
      final bool notiTaskEnabled = (data?['notiTaskEnabled'] as bool?) ?? true;
      if (!notiTaskEnabled) return;

      final scheduledTime = dueDate.subtract(Duration(minutes: reminderMinutes));
      if (!scheduledTime.isAfter(DateTime.now())) return;

      await scheduleTaskNotification(
        taskId: taskId,
        body: taskTitle,
        scheduledTime: scheduledTime,
      );
    } catch (_) {
      // Ignoramos fallos para no bloquear la app.
    }
  }

  static Future<NotificationTestResult> showTestNotification({
    bool playPreviewSound = false,
  }) async {
    final permissionStatus = await _ensureNotificationPermission();
    if (permissionStatus == _NotificationPermissionStatus.denied) {
      return const NotificationTestResult(
        notificationSent: false,
        previewSoundPlayed: false,
        failure: NotificationTestFailure.permissionDenied,
      );
    }
    if (permissionStatus == _NotificationPermissionStatus.permanentlyDenied) {
      return const NotificationTestResult(
        notificationSent: false,
        previewSoundPlayed: false,
        failure: NotificationTestFailure.permissionPermanentlyDenied,
      );
    }
    if (permissionStatus == _NotificationPermissionStatus.failed) {
      return const NotificationTestResult(
        notificationSent: false,
        previewSoundPlayed: false,
        failure: NotificationTestFailure.unknown,
        errorDescription:
            'No se pudo validar el permiso de notificaciones del sistema.',
      );
    }

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? areEnabled =
        await androidImplementation?.areNotificationsEnabled();
    if (areEnabled == false) {
      return const NotificationTestResult(
        notificationSent: false,
        previewSoundPlayed: false,
        failure: NotificationTestFailure.permissionPermanentlyDenied,
        errorDescription:
            'Las notificaciones estan desactivadas para la app en Android.',
      );
    }

    bool notificationSent = false;
    String? errorDescription;
    bool usedFallbackSound = false;
    try {
      usedFallbackSound = await _sendNotificationWithBestSound(
        (details) async {
          await _notificationsPlugin.show(
            9999,
            'Prueba',
            'Esto es una notificación de prueba',
            details,
          );
        },
      );
      notificationSent = true;
    } on PlatformException catch (error) {
      notificationSent = false;
      errorDescription = error.message ?? error.code;
    } catch (error) {
      notificationSent = false;
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
      usedFallbackSound: usedFallbackSound,
    );
  }

  static Future<bool> _playTestSoundPreview() async {
    final AudioPlayer previewPlayer = AudioPlayer();
    try {
      await previewPlayer.setReleaseMode(ReleaseMode.stop);
      await previewPlayer.play(
        AssetSource('sounds/Notificacion1.mp3'),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      await previewPlayer.dispose();
    }
  }

  static Future<_NotificationPermissionStatus>
      _ensureNotificationPermission() async {
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return _NotificationPermissionStatus.granted;
    }
    try {
      PermissionStatus status = await Permission.notification.status;
      if (status.isGranted) {
        return _NotificationPermissionStatus.granted;
      }
      status = await Permission.notification.request();
      if (status.isGranted) {
        return _NotificationPermissionStatus.granted;
      }
      if (status.isPermanentlyDenied) {
        return _NotificationPermissionStatus.permanentlyDenied;
      }
      return _NotificationPermissionStatus.denied;
    } catch (_) {
      return _NotificationPermissionStatus.failed;
    }
  }

  static Future<void> _registerTasksChannel() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) return;
    final channel = _customSoundAvailable
        ? _tasksChannel
        : AndroidNotificationChannel(
            _tasksChannel.id,
            _tasksChannel.name,
            description: _tasksChannel.description,
            importance: _tasksChannel.importance,
            playSound: true,
            enableVibration: true,
          );
    await androidImplementation.createNotificationChannel(channel);
  }

  static Future<void> _disableCustomChannelSound() async {
    if (!_customSoundAvailable) return;
    _customSoundAvailable = false;
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.deleteNotificationChannel(_tasksChannel.id);
    await _registerTasksChannel();
  }

  static NotificationDetails _buildNotificationDetails({
    required bool useCustomSound,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _tasksChannel.id,
        _tasksChannel.name,
        channelDescription: _tasksChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: useCustomSound ? _tasksChannel.sound : null,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<bool> _sendNotificationWithBestSound(
    Future<void> Function(NotificationDetails details) action,
  ) async {
    try {
      final details = _buildNotificationDetails(
        useCustomSound: _customSoundAvailable,
      );
      await action(details);
      return false;
    } on PlatformException catch (error) {
      if (error.code == 'invalid_sound' && _customSoundAvailable) {
        await _disableCustomChannelSound();
        final fallbackDetails =
            _buildNotificationDetails(useCustomSound: false);
        await action(fallbackDetails);
        return true;
      }
      rethrow;
    }
  }

  static Future<void> _configureLocalTimeZone() async {
    if (_timezoneInitialized) return;
    tz.initializeTimeZones();
    try {
      final String timeZoneName =
          await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _timezoneInitialized = true;
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

enum _NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  failed,
}
