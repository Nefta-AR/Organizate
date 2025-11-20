import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _timezoneInitialized = false;

  static const AndroidNotificationChannel _tasksChannel =
      AndroidNotificationChannel(
    'tasks_channel',
    'Recordatorios de tareas',
    description: 'Notificaciones para recordarte las tareas pendientes.',
    importance: Importance.max,
  );

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
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_tasksChannel);
    await _configureLocalTimeZone();
  }

  static Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required DateTime scheduledTime,
  }) async {
    if (!scheduledTime.isAfter(DateTime.now())) return;
    await _configureLocalTimeZone();

    final androidDetails = AndroidNotificationDetails(
      _tasksChannel.id,
      _tasksChannel.name,
      channelDescription: _tasksChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      taskId.hashCode,
      title,
      'Tienes una tarea próxima.',
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId,
    );
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    await _notificationsPlugin.cancel(taskId.hashCode);
  }

  static Future<void> scheduleReminderIfNeeded({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    required DateTime? dueDate,
    int? reminderOffsetMinutes,
  }) async {
    if (dueDate == null) return;

    try {
      final snapshot = await userDocRef.get();
      final data = snapshot.data();
      final bool notiTaskEnabled = (data?['notiTaskEnabled'] as bool?) ?? true;
      if (!notiTaskEnabled) return;

      final int offsetMinutes = (reminderOffsetMinutes != null &&
              reminderOffsetMinutes > 0)
          ? reminderOffsetMinutes
          : (data?['notiTaskDefaultOffsetMinutes'] as num?)?.toInt() ?? 30;
      final scheduledTime = dueDate.subtract(Duration(minutes: offsetMinutes));
      if (!scheduledTime.isAfter(DateTime.now())) return;

      await scheduleTaskNotification(
        taskId: taskId,
        title: 'Recordatorio: $taskTitle',
        scheduledTime: scheduledTime,
      );
    } catch (_) {
      // Ignora errores silenciosamente para no bloquear la creación de tareas.
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
