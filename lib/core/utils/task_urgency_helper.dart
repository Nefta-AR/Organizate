// lib/core/utils/task_urgency_helper.dart
//
// Helper para renderizar badges de urgencia en tareas pendientes.
//
// Estados:
//   - HOY     : tarea cuya fecha de entrega es hoy.
//   - MAÑANA  : tarea cuya fecha de entrega es mañana.
//   - DESPUÉS : tarea cuya fecha de entrega es posterior a mañana.
//   - ATRASADA: tarea cuya fecha de entrega ya pasó (más urgente).

import 'package:flutter/material.dart';

/// Información visual de un estado de urgencia.
class _UrgencyInfo {
  const _UrgencyInfo({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

_UrgencyInfo? _resolveUrgency(DateTime? dueDate) {
  if (dueDate == null) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = dueDay.difference(today).inDays;

  if (diff < 0) {
    return const _UrgencyInfo(
      label: 'ATRASADA',
      foreground: Color(0xFFB71C1C),
      background: Color(0xFFFFEBEE),
    );
  }
  if (diff == 0) {
    return const _UrgencyInfo(
      label: 'HOY',
      foreground: Color(0xFFC62828),
      background: Color(0xFFFFEBEE),
    );
  }
  if (diff == 1) {
    return const _UrgencyInfo(
      label: 'MAÑANA',
      foreground: Color(0xFFEF6C00),
      background: Color(0xFFFFF3E0),
    );
  }
  return const _UrgencyInfo(
    label: 'DESPUÉS',
    foreground: Color(0xFF2E7D32),
    background: Color(0xFFE8F5E9),
  );
}

/// Devuelve un widget badge si [dueDate] tiene fecha; de lo contrario `null`.
Widget? buildTaskUrgencyBadge(DateTime? dueDate) {
  final info = _resolveUrgency(dueDate);
  if (info == null) return null;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: info.background,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: info.foreground.withValues(alpha: 0.2)),
    ),
    child: Text(
      info.label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: info.foreground,
        letterSpacing: 0.5,
      ),
    ),
  );
}
