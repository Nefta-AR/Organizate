import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/reminder_options.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

class ReminderDispatcher {
  ReminderDispatcher._();

  /// Programa la notificacion local y encola la version push en Firestore
  /// para que el backend la envie mediante FCM en la hora configurada.
  static Future<void> scheduleTaskReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (dueDate == null || reminderMinutes == null) {
      debugPrint(
        '[REMINDER] Recordatorio omitido: falta dueDate o reminderMinutes',
      );
      return;
    }

    final normalizedMinutes = normalizeReminderMinutes(reminderMinutes);
    final normalizedDueDate = dueDate.toLocal();

    try {
      await NotificationService.scheduleReminderIfNeeded(
        userDocRef: userDocRef,
        taskId: taskId,
        taskTitle: taskTitle,
        dueDate: normalizedDueDate,
        reminderMinutes: normalizedMinutes,
      );

      await PushNotificationService.queueRemoteReminder(
        userDocRef: userDocRef,
        taskId: taskId,
        taskTitle: taskTitle,
        dueDate: normalizedDueDate,
        reminderMinutes: normalizedMinutes,
      );
    } catch (e, stack) {
      debugPrint('[REMINDER] Error programando recordatorio: $e\n$stack');
      rethrow;
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
      rethrow;
    }
  }

  /// Garantiza que el offset sea al menos el minimo configurado.
  static int normalizeReminderMinutes(int? reminderMinutes) {
    if (reminderMinutes == null) return kMinimumReminderMinutes;
    return reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;
  }
}
