import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/reminder_options.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

class ReminderDispatcher {
  ReminderDispatcher._();

  /// Programa la notificación local y encola la versión push en Firestore
  /// para que el backend la envíe mediante FCM en la hora configurada.
  static Future<void> scheduleTaskReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    await NotificationService.scheduleReminderIfNeeded(
      userDocRef: userDocRef,
      taskId: taskId,
      taskTitle: taskTitle,
      dueDate: dueDate,
      reminderMinutes: reminderMinutes,
    );

    try {
      await PushNotificationService.queueRemoteReminder(
        userDocRef: userDocRef,
        taskId: taskId,
        taskTitle: taskTitle,
        dueDate: dueDate,
        reminderMinutes: reminderMinutes,
      );
    } catch (e, stack) {
      debugPrint('[REMINDER] No se pudo encolar push: $e\n$stack');
    }
  }

  static Future<void> cancelTaskReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
  }) async {
    await NotificationService.cancelTaskNotification(taskId);
    try {
      await PushNotificationService.cancelRemoteReminder(
        userDocRef: userDocRef,
        taskId: taskId,
      );
    } catch (e, stack) {
      debugPrint('[REMINDER] No se pudo cancelar push en cola: $e\n$stack');
    }
  }

  /// Garantiza que el offset sea al menos el mínimo configurado.
  static int normalizeReminderMinutes(int? reminderMinutes) {
    if (reminderMinutes == null) return kMinimumReminderMinutes;
    return reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;
  }
}
