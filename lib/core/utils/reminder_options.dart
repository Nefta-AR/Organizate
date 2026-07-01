// ============================================================
// lib/core/utils/reminder_options.dart
// ============================================================
// Constantes y opciones para el sistema de recordatorios de tareas.
//
// [kDefaultReminderMinutes]: valor por defecto si el usuario
//   no ha configurado un offset personalizado.
//
// [kMinimumReminderMinutes]: piso mínimo de minutos para evitar
//   recordatorios inútiles (< 10 min de anticipación).
//
// [kReminderOptions]: lista de opciones para el DropdownButton
//   de recordatorio en los diálogos de tareas.
// ============================================================

/// Minutos de anticipación por defecto para los recordatorios.
const int kDefaultReminderMinutes = 30;

/// Mínimo de minutos permitidos para un recordatorio.
/// Valores menores se elevan a este piso en [normalizeReminderMinutes].
const int kMinimumReminderMinutes = 10;

/// Opciones disponibles para el selector de recordatorio en el UI.
/// El campo 'minutes' puede ser null (sin recordatorio) o un entero > 0.
const List<Map<String, dynamic>> kReminderOptions = [
  {'label': 'Sin recordatorio', 'minutes': null},
  {'label': '10 minutos antes', 'minutes': 10},
  {'label': '15 minutos antes', 'minutes': 15},
  {'label': '30 minutos antes', 'minutes': 30},
  {'label': '1 hora antes', 'minutes': 60},
  {'label': '2 horas antes', 'minutes': 120},
  {'label': '1 día antes', 'minutes': 1440},
];

/// Devuelve la etiqueta textual correspondiente a [minutes].
/// Si no hay coincidencia exacta, retorna 'Sin recordatorio'.
String reminderLabelFromMinutes(int? minutes) {
  final match = kReminderOptions.firstWhere(
    (option) => option['minutes'] == minutes,
    orElse: () => kReminderOptions.first,
  );
  return match['label'] as String;
}
