// ============================================================
// lib/core/services/reminder_dispatcher.dart
// ============================================================
// Orquestador del sistema de recordatorios dual:
//   1. Notificación local (flutter_local_notifications) via [NotificationService]
//   2. Cola de push remota (Firestore → Cloud Functions → FCM) via [PushNotificationService]
//
// Ambos canales trabajan en paralelo para máxima fiabilidad:
//   - El canal local funciona aunque la app esté en background.
//   - El canal remoto funciona aunque el dispositivo haya reiniciado
//     y no tenga la app en memoria.
//
// [normalizeReminderMinutes]: aplica el piso [kMinimumReminderMinutes]
//   para evitar recordatorios con menos de 10 minutos de anticipación.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/reminder_options.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';

/// Dispatcher de recordatorios: programa o cancela ambos canales (local + push).
class ReminderDispatcher {
  ReminderDispatcher._(); // Clase puramente estática, no instanciar

  /// Programa un recordatorio local y uno remoto para una tarea.
  ///
  /// No hace nada si [dueDate] o [reminderMinutes] son null (recordatorio desactivado).
  /// Aplica el piso [kMinimumReminderMinutes] antes de delegar a cada servicio.
  static Future<void> scheduleTaskReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (dueDate == null || reminderMinutes == null) {
      debugPrint(
          '[REMINDER] Recordatorio omitido: falta dueDate o reminderMinutes');
      return;
    }

    final normalizedMinutes = normalizeReminderMinutes(reminderMinutes);
    final normalizedDueDate = dueDate.toLocal();

    try {
      // Canal 1: Notificación local via flutter_local_notifications
      await NotificationService.scheduleReminderIfNeeded(
        userDocRef: userDocRef,
        taskId: taskId,
        taskTitle: taskTitle,
        dueDate: normalizedDueDate,
        reminderMinutes: normalizedMinutes,
      );

      // Canal 2: Cola de push remota en Firestore
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

  /// Cancela el recordatorio local y elimina la cola de push para una tarea.
  static Future<void> cancelTaskReminder({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
  }) async {
    // Cancela el canal local (siempre disponible, no puede fallar con rethrow)
    await NotificationService.cancelTaskNotification(taskId);
    try {
      // Cancela el canal remoto (puede fallar si no hay conexión)
      await PushNotificationService.cancelRemoteReminder(
        userDocRef: userDocRef,
        taskId: taskId,
      );
    } catch (e, stack) {
      debugPrint('[REMINDER] No se pudo cancelar push en cola: $e\n$stack');
      rethrow;
    }
  }

  /// Eleva [reminderMinutes] al mínimo permitido si es menor que [kMinimumReminderMinutes].
  static int normalizeReminderMinutes(int? reminderMinutes) {
    if (reminderMinutes == null) return kMinimumReminderMinutes;
    return reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;
  }
}
