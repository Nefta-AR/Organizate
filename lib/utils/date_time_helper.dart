import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime({
  required BuildContext context,
  DateTime? initialDate,
}) async {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  // Use now as baseline to avoid suggesting past dates by default.
  final DateTime initial =
      (initialDate != null && initialDate.isAfter(now)) ? initialDate : now;

  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: today,
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

  final DateTime result = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  if (result.isBefore(now)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No puedes agendar en el pasado')),
    );
    return null;
  }

  return result;
}
