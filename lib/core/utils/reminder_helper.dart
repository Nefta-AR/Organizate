// ============================================================
// lib/core/utils/reminder_helper.dart
// ============================================================
// Helpers para leer la configuración de recordatorios del usuario
// desde Firestore.
//
// [fetchDefaultReminderMinutes]: lee el offset por defecto
//   configurado en el documento del usuario (`notiTaskDefaultOffsetMinutes`).
//   Aplica el piso mínimo de [kMinimumReminderMinutes].
//
// [extractReminderMinutes]: extrae los minutos de recordatorio
//   de un mapa de datos de tarea. Soporta el campo nuevo
//   (`reminderMinutes`) y el campo legacy (`reminderOffsetMinutes`)
//   para retrocompatibilidad con tareas anteriores.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/reminder_options.dart';

/// Lee el offset de recordatorio por defecto del usuario desde Firestore.
///
/// Retorna [kMinimumReminderMinutes] como piso si el valor guardado
/// es menor. Retorna [kDefaultReminderMinutes] si el campo no existe.
/// Retorna null si el usuario desactivó el recordatorio por defecto.
Future<int?> fetchDefaultReminderMinutes(
  DocumentReference<Map<String, dynamic>> userDoc,
) async {
  try {
    final snapshot = await userDoc.get();
    final data = snapshot.data();
    if (data == null) return kDefaultReminderMinutes;
    if (data.containsKey('notiTaskDefaultOffsetMinutes')) {
      final value = data['notiTaskDefaultOffsetMinutes'];
      if (value == null) return null; // El usuario eligió "sin recordatorio"
      final parsed = (value as num).toInt();
      // Aplica el piso mínimo para evitar recordatorios demasiado cortos
      return parsed < kMinimumReminderMinutes
          ? kMinimumReminderMinutes
          : parsed;
    }
  } catch (_) {}
  return kDefaultReminderMinutes;
}

/// Extrae los minutos de recordatorio de un documento de tarea.
///
/// Prioriza el campo moderno `reminderMinutes` sobre el legacy
/// `reminderOffsetMinutes`. Aplica el piso [kMinimumReminderMinutes].
/// Retorna null si no hay recordatorio configurado.
int? extractReminderMinutes(Map<String, dynamic> data) {
  // Campo moderno
  final reminder = data['reminderMinutes'];
  if (reminder is num) {
    final parsed = reminder.toInt();
    return parsed < kMinimumReminderMinutes ? kMinimumReminderMinutes : parsed;
  }
  // Campo legacy (tareas creadas antes de la migración)
  final legacy = data['reminderOffsetMinutes'];
  if (legacy is num) {
    final value = legacy.toInt();
    if (value <= 0) return null; // 0 significa desactivado en el esquema antiguo
    return value < kMinimumReminderMinutes ? kMinimumReminderMinutes : value;
  }
  return null;
}
