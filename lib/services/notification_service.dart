import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _timezoneInitialized = false;

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
    await androidImplementation?.createNotificationChannel(_tasksChannel);

    await _configureLocalTimeZone();
  }

  static Future<void> scheduleTaskNotification({
    required String taskId,
    required DateTime scheduledTime,
    required String body,
  }) async {
    if (!scheduledTime.isAfter(DateTime.now())) return;
    await _configureLocalTimeZone();

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _tasksChannel.id,
        _tasksChannel.name,
        channelDescription: _tasksChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: _tasksChannel.sound,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
    );

    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      taskId.hashCode,
      'Recordatorio de tarea',
      body,
      tzScheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
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

  static Future<void> showTestNotification() async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _tasksChannel.id,
        _tasksChannel.name,
        channelDescription: _tasksChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: _tasksChannel.sound,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
    );
    await _notificationsPlugin.show(
      9999,
      'Prueba',
      'Esto es una notificación de prueba',
      details,
    );
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
