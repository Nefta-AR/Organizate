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
      if (value == null) return null;
      final parsed = (value as num).toInt();
      return parsed < kMinimumReminderMinutes
          ? kMinimumReminderMinutes
          : parsed;
    }
  } catch (_) {
    // Si hay un error, regresamos al valor por defecto.
  }
  return kDefaultReminderMinutes;
}

int? extractReminderMinutes(Map<String, dynamic> data) {
  final reminder = data['reminderMinutes'];
  if (reminder is num) {
    final parsed = reminder.toInt();
    return parsed < kMinimumReminderMinutes ? kMinimumReminderMinutes : parsed;
  }
  final legacy = data['reminderOffsetMinutes'];
  if (legacy is num) {
    final value = legacy.toInt();
    if (value <= 0) return null;
    return value < kMinimumReminderMinutes ? kMinimumReminderMinutes : value;
  }
  return null;
}
