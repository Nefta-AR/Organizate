// lib/features/tda_focus/screens/progreso_screen.dart
//
// Dashboard de progreso del usuario. Muestra tres gráficos en tiempo real:
//
//   1. **Tareas por categoría** (barras): tareas completadas agrupadas por
//      categoría (Estudios, Hogar, Meds, Foco, General).
//
//   2. **Uso de pictogramas** (anillo): pictogramas más usados por categoría,
//      extraídos del activityLog con tipo `pictogram_used`.
//
//   3. **Sesiones Pomodoro** (línea semanal): minutos de foco acumulados por
//      día de la semana actual, combinando `focusSessionsCompleted` y
//      `totalFocusMinutes` del documento del usuario.
//
// ## Fuentes de datos
//
//   - `users/{uid}` → puntos, racha, sesiones Pomodoro totales, minutos totales.
//   - `users/{uid}/tasks` → tareas completadas (campo `done: true`).
//   - `users/{uid}/activityLog` → log de pictogramas usados y Pomodoros.
//
// ## Integración
//
//   - Usuario TDAH/general: accesible desde `CustomNavBar` (tab "Progreso").
//   - Tutor: accesible desde `TutorSupervisarScreen` (tab "Progreso").
//   - Usuario TEA: no visible (la interfaz de pictogramas es su dashboard).

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/services/activity_log_service.dart';

class ProgresoScreen extends StatefulWidget {
  /// Si se proporciona [userId], muestra el progreso de ese usuario (modo tutor).
  /// Si es null, usa el usuario autenticado actual.
  final String? userId;

  const ProgresoScreen({super.key, this.userId});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  late final String _uid;
  late final DocumentReference<Map<String, dynamic>> _userDocRef;
  late final CollectionReference<Map<String, dynamic>> _tasksCollection;

  @override
  void initState() {
    super.initState();
    _uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _userDocRef = FirebaseFirestore.instance.collection('users').doc(_uid);
    _tasksCollection = _userDocRef.collection('tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocRef.snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = userSnap.data?.data() ?? {};
          final points = (userData['points'] as num?)?.toInt() ?? 0;
          final streak = (userData['streak'] as num?)?.toInt() ?? 0;
          final sessions = (userData['focusSessionsCompleted'] as num?)?.toInt() ?? 0;
          final totalMinutes = (userData['totalFocusMinutes'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de resumen
                _SummaryCard(
                  points: points,
                  streak: streak,
                  sessions: sessions,
                  totalMinutes: totalMinutes,
                ),
                const SizedBox(height: 24),

                // Gráfico 1: Tareas por categoría
                _sectionTitle('Tareas completadas por categoría'),
                const SizedBox(height: 12),
                _TaskCategoryChart(tasksCollection: _tasksCollection),
                const SizedBox(height: 32),

                // Gráfico 2: Uso de pictogramas
                _sectionTitle('Pictogramas más usados'),
                const SizedBox(height: 12),
                _PictogramUsageChart(userId: _uid),
                const SizedBox(height: 32),

                // Gráfico 3: Pomodoro semanal
                _sectionTitle('Sesiones de foco esta semana'),
                const SizedBox(height: 12),
                _PomodoroWeeklyChart(userId: _uid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
}

// ─── Tarjeta de resumen ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int points;
  final int streak;
  final int sessions;
  final int totalMinutes;

  const _SummaryCard({
    required this.points,
    required this.streak,
    required this.sessions,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.star_rounded,
            value: '$points',
            label: 'Puntos',
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.local_fire_department_rounded,
            value: '$streak',
            label: 'Racha',
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.timer_rounded,
            value: '$sessions',
            label: 'Sesiones',
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.access_time_rounded,
            value: '${totalMinutes}m',
            label: 'Foco',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Gráfico 1: Tareas por categoría ─────────────────────────────────────────

class _TaskCategoryChart extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> tasksCollection;

  const _TaskCategoryChart({required this.tasksCollection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tasksCollection.where('done', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = snapshot.data?.docs ?? [];
        final categoryCounts = <String, double>{
          'Estudios': 0,
          'Hogar': 0,
          'Meds': 0,
          'Foco': 0,
          'General': 0,
        };

        for (final task in tasks) {
          final category = task.data()['category'] as String?;
          if (category != null && categoryCounts.containsKey(category)) {
            categoryCounts[category] = categoryCounts[category]! + 1;
          } else {
            categoryCounts['General'] = categoryCounts['General']! + 1;
          }
        }

        final maxVal = categoryCounts.values.reduce((a, b) => a > b ? a : b);
        final hasData = tasks.isNotEmpty;

        if (!hasData) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Completa tareas para ver tu progreso',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }

        final colors = [
          Colors.orange,
          Colors.green,
          Colors.red,
          Colors.purple,
          Colors.grey,
        ];
        final labels = ['Estudios', 'Hogar', 'Meds', 'Foco', 'General'];

        return SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal + 1,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${labels[group.x.toInt()]}\n${rod.toY.toInt()} tareas',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      final text = (i >= 0 && i < labels.length)
                          ? labels[i]
                          : '';
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
              barGroups: List.generate(5, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: categoryCounts[labels[i]]!,
                      color: colors[i],
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ─── Gráfico 2: Uso de pictogramas ───────────────────────────────────────────

class _PictogramUsageChart extends StatelessWidget {
  final String userId;

  const _PictogramUsageChart({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ActivityLogService.getStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final logs = snapshot.data ?? [];
        final pictoLogs = logs
            .where((l) => l['type'] == ActivityType.pictogramUsed)
            .toList();

        if (pictoLogs.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Usa pictogramas para ver estadísticas',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }

        // Agrupar por categoría (extraída del description)
        final categoryCounts = <String, int>{};
        for (final log in pictoLogs) {
          final desc = log['description'] as String? ?? '';
          // El formato del description es "Pictograma: ETIQUETA (categoría)"
          final categoryMatch = RegExp(r'\(([^)]+)\)$').firstMatch(desc);
          final category = categoryMatch?.group(1) ?? 'General';
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }

        final sorted = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topCategories = sorted.take(5).toList();
        final total = topCategories.fold<int>(0, (acc, e) => acc + e.value);

        final colors = [
          Colors.purple,
          Colors.teal,
          Colors.orange,
          Colors.blue,
          Colors.pink,
        ];

        return SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(topCategories.length, (i) {
                      final entry = topCategories[i];
                      final percentage = (entry.value / total * 100).round();
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '$percentage%',
                        color: colors[i % colors.length],
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topCategories.asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Gráfico 3: Pomodoro semanal ─────────────────────────────────────────────

class _PomodoroWeeklyChart extends StatelessWidget {
  final String userId;

  const _PomodoroWeeklyChart({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ActivityLogService.getStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final logs = snapshot.data ?? [];
        final pomodoroLogs = logs
            .where((l) => l['type'] == ActivityType.pomodoroCompleted)
            .toList();

        // Agrupar por día de la semana actual
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

        final dailyMinutes = List.filled(7, 0.0);
        final dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

        for (final log in pomodoroLogs) {
          final ts = log['timestamp'] as Timestamp?;
          if (ts == null) continue;
          final date = ts.toDate();
          if (date.isBefore(startOfDay)) continue;

          final dayIndex = date.weekday - 1; // 0=Lun, 6=Dom
          final metadata = log['metadata'] as Map<String, dynamic>?;
          final minutes = (metadata?['minutes'] as num?)?.toDouble() ?? 25.0;
          dailyMinutes[dayIndex] += minutes;
        }

        final maxMinutes = dailyMinutes.reduce((a, b) => a > b ? a : b);
        final hasData = dailyMinutes.any((m) => m > 0);

        if (!hasData) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Completa sesiones Pomodoro para ver tu semana',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 15,
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Text(
                        '${value.toInt()}m',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i > 6) return const SizedBox();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          dayLabels[i],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade200),
              ),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxMinutes > 0 ? maxMinutes + 10 : 30,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(7, (i) => FlSpot(i.toDouble(), dailyMinutes[i])),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Colors.deepOrange,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.deepOrange.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
