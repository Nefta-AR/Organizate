import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime({
  required BuildContext context,
  DateTime? initialDate,
}) async {
  final DateTime now = DateTime.now();
  final DateTime initial = initialDate ?? now;

  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
    locale: const Locale('es', 'ES'),
  );
  if (!context.mounted) return null;
  if (pickedDate == null) return null;

  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    helpText: 'Selecciona la hora',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );
  if (!context.mounted) return null;
  if (pickedTime == null) return null;

  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}
