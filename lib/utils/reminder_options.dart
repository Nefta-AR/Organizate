const List<Map<String, dynamic>> kReminderOptions = [
  {'label': 'Sin recordatorio', 'minutes': 0},
  {'label': '10 minutos antes', 'minutes': 10},
  {'label': '15 minutos antes', 'minutes': 15},
  {'label': '30 minutos antes', 'minutes': 30},
  {'label': '1 hora antes', 'minutes': 60},
  {'label': '2 horas antes', 'minutes': 120},
  {'label': '1 día antes', 'minutes': 1440},
];

String reminderLabelFromMinutes(int? minutes) {
  final match = kReminderOptions
      .firstWhere((option) => option['minutes'] == minutes, orElse: () => kReminderOptions.first);
  return match['label'] as String;
}
