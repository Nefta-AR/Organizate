// ============================================================
// lib/core/utils/date_time_helper.dart
// ============================================================
// Utilidad para selección de fecha y hora en diálogos.
//
// [pickDateTime] encadena showDatePicker → showTimePicker y valida
// que el resultado no sea en el pasado. Retorna null si el usuario
// cancela cualquiera de los dos pasos, o si la fecha resultante
// ya pasó (muestra un SnackBar informativo en ese caso).
// ============================================================

import 'package:flutter/material.dart';

/// Abre un selector de fecha seguido de un selector de hora.
///
/// Retorna la [DateTime] combinada, o null si:
///   - El usuario cancela alguno de los pasos.
///   - La fecha/hora resultante es anterior al momento actual.
///   - El [BuildContext] ya no está montado entre pasos.
///
/// [initialDate]: fecha/hora de inicio del selector (por defecto: ahora).
Future<DateTime?> pickDateTime({
  required BuildContext context,
  DateTime? initialDate,
}) async {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  // Si initialDate es pasado o null, usamos "ahora" como punto de inicio.
  final DateTime initial =
      (initialDate != null && initialDate.isAfter(now)) ? initialDate : now;

  // Paso 1: Seleccionar la fecha
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: today,
    lastDate: DateTime(now.year + 5),
    locale: const Locale('es', 'ES'),
  );
  if (!context.mounted) return null;
  if (pickedDate == null) return null; // Usuario canceló

  // Paso 2: Seleccionar la hora
  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    helpText: 'Selecciona la hora',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );
  if (!context.mounted) return null;
  if (pickedTime == null) return null; // Usuario canceló

  // Combinar fecha y hora en un solo DateTime
  final DateTime result = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  // Validar que no sea en el pasado. Se compara contra ahora truncado al minuto
  // porque el selector de hora solo permite elegir horas y minutos (no segundos).
  // Si now = 19:47:45 y el usuario elige 19:47, result = 19:47:00 es válido.
  final DateTime nowMinute =
      DateTime(now.year, now.month, now.day, now.hour, now.minute);
  if (result.isBefore(nowMinute)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No puedes agendar en el pasado')),
    );
    return null;
  }

  return result;
}
