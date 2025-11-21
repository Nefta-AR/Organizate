import 'package:cloud_firestore/cloud_firestore.dart';

import 'reminder_options.dart';

Future<int?> fetchDefaultReminderMinutes(
  DocumentReference<Map<String, dynamic>> userDoc,
) async {
  try {
    final snapshot = await userDoc.get();
    final data = snapshot.data();
    if (data == null) {
      return kDefaultReminderMinutes;
    }
    if (data.containsKey('notiTaskDefaultOffsetMinutes')) {
      final value = data['notiTaskDefaultOffsetMinutes'];
      return value == null ? null : (value as num).toInt();
    }
  } catch (_) {
    // Si hay un error, regresamos al valor por defecto.
  }
  return kDefaultReminderMinutes;
}

int? extractReminderMinutes(Map<String, dynamic> data) {
  final reminder = data['reminderMinutes'];
  if (reminder is num) {
    return reminder.toInt();
  }
  final legacy = data['reminderOffsetMinutes'];
  if (legacy is num) {
    final value = legacy.toInt();
    return value > 0 ? value : null;
  }
  return null;
}
