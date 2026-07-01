// ============================================================
// lib/features/tda_focus/screens/progreso_screen.dart
// ============================================================
// Dashboard de progreso del usuario con tres gráficos en tiempo real.
//
// ## Gráficos
//
//   1. **Tareas por categoría** (barras, fl_chart BarChart):
//      Tareas completadas (done: true) agrupadas en 5 categorías:
//      Estudios, Hogar, Meds, Foco, General.
//
//   2. **Uso de pictogramas** (anillo, fl_chart PieChart):
//      Pictogramas más usados por categoría, extraídos del activityLog
//      con tipo `pictogram_used`. Agrupa por regex de la descripción.
//
//   3. **Sesiones Pomodoro** (línea semanal, fl_chart LineChart):
//      Minutos de foco acumulados por día de la semana actual,
//      extraídos del activityLog con tipo `pomodoroCompleted`.
//
// ## Fuentes de datos
//
//   - `users/{uid}`           → puntos, racha, sesiones Pomodoro totales.
//   - `users/{uid}/tasks`     → tareas completadas (campo `done: true`).
//   - `users/{uid}/activityLog` → log de pictogramas usados y Pomodoros.
//
// ## Integración
//
//   - Usuario TDAH/general: accesible desde CustomNavBar (tab "Progreso").
//   - Tutor:               accesible desde TutorSupervisarScreen.
//   - Usuario TEA:         no visible (usa el tablero de pictogramas).
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/services/activity_log_service.dart';

class ProgresoScreen extends StatefulWidget {
  /// Si se proporciona [userId], muestra el progreso de ese usuario (modo tutor).
  /// Si es null, usa el UID del usuario autenticado actual.
  final String? userId;

  const ProgresoScreen({super.key, this.userId});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  // UID efectivo: el del parámetro (modo tutor) o el del usuario autenticado
  late final String _uid;

  // Referencia al documento del usuario para el StreamBuilder de estadísticas
  late final DocumentReference<Map<String, dynamic>> _userDocRef;

  // Referencia a la sub-colección de tareas del usuario
  late final CollectionReference<Map<String, dynamic>> _tasksCollection;

  @override
  void initState() {
    super.initState();

    // Determinamos el UID: parámetro externo (tutor supervisando) o usuario actual
    _uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    // Configuramos las referencias de Firestore para los sub-widgets
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

      // StreamBuilder exterior: lee el documento del usuario para las estadísticas globales
      // (puntos, racha, sesiones Pomodoro totales, minutos totales)
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocRef.snapshots(),
        builder: (context, userSnap) {
          // Spinner mientras carga el primer snapshot
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Extraemos las estadísticas del documento con conversión segura num→int
          final userData      = userSnap.data?.data() ?? {};
          final points        = (userData['points']                 as num?)?.toInt() ?? 0;
          final streak        = (userData['streak']                 as num?)?.toInt() ?? 0;
          final sessions      = (userData['focusSessionsCompleted'] as num?)?.toInt() ?? 0;
          final totalMinutes  = (userData['totalFocusMinutes']      as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // 96 para la nav bar inferior
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de resumen con gradiente azul: 4 métricas en una fila
                _SummaryCard(
                  points:       points,
                  streak:       streak,
                  sessions:     sessions,
                  totalMinutes: totalMinutes,
                ),
                const SizedBox(height: 24),

                // Gráfico 1: Distribución de tareas completadas por categoría
                _sectionTitle('Tareas completadas por categoría'),
                const SizedBox(height: 12),
                // Pasa la referencia de la colección para que el widget haga su propio stream
                _TaskCategoryChart(tasksCollection: _tasksCollection),
                const SizedBox(height: 32),

                // Gráfico 2: Anillo de uso de pictogramas por categoría
                _sectionTitle('Pictogramas más usados'),
                const SizedBox(height: 12),
                _PictogramUsageChart(userId: _uid),
                const SizedBox(height: 32),

                // Gráfico 3: Línea de sesiones Pomodoro de la semana actual
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

  // Helper para títulos de sección con estilo uniforme
  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
}

// ── Tarjeta de resumen con gradiente ─────────────────────────────────────────

/// Card con gradiente azul que muestra las 4 métricas principales del usuario.
class _SummaryCard extends StatelessWidget {
  final int points;       // Puntos acumulados
  final int streak;       // Racha de días consecutivos
  final int sessions;     // Sesiones Pomodoro completadas
  final int totalMinutes; // Minutos totales de foco

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
        // Gradiente diagonal de azul oscuro a azul claro
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
      // 4 ítems de estadística, cada uno ocupa el mismo espacio (Expanded en _StatItem)
      child: Row(
        children: [
          _StatItem(icon: Icons.star_rounded,                value: '$points',          label: 'Puntos'),
          const SizedBox(width: 16),
          _StatItem(icon: Icons.local_fire_department_rounded, value: '$streak',          label: 'Racha'),
          const SizedBox(width: 16),
          _StatItem(icon: Icons.timer_rounded,               value: '$sessions',         label: 'Sesiones'),
          const SizedBox(width: 16),
          _StatItem(icon: Icons.access_time_rounded,         value: '${totalMinutes}m',  label: 'Foco'),
        ],
      ),
    );
  }
}

/// Ítem de estadística: icono + valor + etiqueta, apilados verticalmente.
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
          // Valor numérico en negrita
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          // Etiqueta descriptiva en gris suave
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Gráfico 1: Barras de tareas por categoría ──────────────────────────────────

/// Widget de gráfico de barras usando fl_chart [BarChart].
///
/// Escucha la colección `tasks` filtrada por `done: true`.
/// Agrupa las tareas en las 5 categorías fijas de la app.
class _TaskCategoryChart extends StatelessWidget {
  /// Referencia a la subcolección de tareas del usuario.
  final CollectionReference<Map<String, dynamic>> tasksCollection;

  const _TaskCategoryChart({required this.tasksCollection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Filtramos directamente en Firestore para no traer tareas pendientes
      stream: tasksCollection.where('done', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        // Spinner de espera mientras se recibe el primer snapshot
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = snapshot.data?.docs ?? [];

        // Mapa de conteo por categoría con valores iniciales en 0
        final categoryCounts = <String, double>{
          'Estudios': 0,
          'Hogar':    0,
          'Meds':     0,
          'Foco':     0,
          'General':  0,
        };

        // Contamos cada tarea en su categoría; categorías no reconocidas → General
        for (final task in tasks) {
          final category = task.data()['category'] as String?;
          if (category != null && categoryCounts.containsKey(category)) {
            categoryCounts[category] = categoryCounts[category]! + 1;
          } else {
            // Categorías no mapeadas (ej: categorías antiguas) van a 'General'
            categoryCounts['General'] = categoryCounts['General']! + 1;
          }
        }

        // Máximo para escalar el eje Y del gráfico
        final maxVal = categoryCounts.values.reduce((a, b) => a > b ? a : b);
        final hasData = tasks.isNotEmpty;

        // Estado vacío: mensaje motivacional
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

        // Paleta de colores por categoría (mismo orden que categoryCounts)
        final colors = [
          Colors.orange,  // Estudios
          Colors.green,   // Hogar
          Colors.red,     // Meds
          Colors.purple,  // Foco
          Colors.grey,    // General
        ];
        final labels = ['Estudios', 'Hogar', 'Meds', 'Foco', 'General'];

        return SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal + 1, // +1 para dar espacio sobre la barra más alta

              // Tooltip al tocar una barra: muestra categoría y cantidad
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
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                // Eje Y izquierdo: muestra solo números enteros (sin el 0)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox(); // Ocultar el 0
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),

                // Eje X inferior: nombre de la categoría en pequeño
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      // Guard para valores fuera del rango de labels
                      final text = (i >= 0 && i < labels.length) ? labels[i] : '';
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(text, style: const TextStyle(fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),

              borderData: FlBorderData(show: false), // Sin borde exterior
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,  // Solo líneas horizontales
                horizontalInterval: 1,    // Línea por cada unidad
              ),

              // 5 grupos de barras, uno por categoría
              barGroups: List.generate(5, (i) {
                return BarChartGroupData(
                  x: i, // Índice en el eje X
                  barRods: [
                    BarChartRodData(
                      toY:   categoryCounts[labels[i]]!, // Altura de la barra
                      color: colors[i],
                      width: 18,
                      // Bordes redondeados solo en la parte superior de la barra
                      borderRadius: const BorderRadius.only(
                        topLeft:  Radius.circular(4),
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

// ── Gráfico 2: Anillo de uso de pictogramas ────────────────────────────────────

/// Widget de anillo (PieChart) con el uso de pictogramas por categoría.
///
/// Lee el activityLog filtrado por tipo `pictogram_used`.
/// Extrae la categoría del campo `description` con una regex.
class _PictogramUsageChart extends StatelessWidget {
  final String userId;

  const _PictogramUsageChart({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Escuchamos el activityLog completo del usuario
      stream: ActivityLogService.getStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final logs = snapshot.data ?? [];

        // Filtramos solo los eventos de uso de pictograma
        final pictoLogs = logs
            .where((l) => l['type'] == ActivityType.pictogramUsed)
            .toList();

        // Estado vacío: sin uso de pictogramas aún
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

        // Agrupamos los usos por categoría.
        // El formato del campo description es: "Pictograma: ETIQUETA (categoría)"
        final categoryCounts = <String, int>{};
        for (final log in pictoLogs) {
          final desc = log['description'] as String? ?? '';

          // Extraemos la categoría con regex: busca texto entre los últimos paréntesis
          final categoryMatch = RegExp(r'\(([^)]+)\)$').firstMatch(desc);
          final category = categoryMatch?.group(1) ?? 'General';

          // Incrementamos el contador de esa categoría
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }

        // Ordenamos de mayor a menor y tomamos solo las 5 principales
        final sorted = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCategories = sorted.take(5).toList();

        // Total para calcular porcentajes
        final total = topCategories.fold<int>(0, (acc, e) => acc + e.value);

        // Paleta de 5 colores para las secciones del anillo
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
              // Anillo (PieChart con hueco en el centro): ocupa 3/5 del ancho
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace:      2,  // Separación entre secciones
                    centerSpaceRadius: 40,  // Radio del hueco central (aspecto de dona)
                    sections: List.generate(topCategories.length, (i) {
                      final entry = topCategories[i];
                      // Calculamos el porcentaje para mostrarlo en la sección
                      final percentage = (entry.value / total * 100).round();
                      return PieChartSectionData(
                        value:    entry.value.toDouble(),
                        title:    '$percentage%',   // Porcentaje visible en la sección
                        color:    colors[i % colors.length],
                        radius:   60,
                        titleStyle: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.bold,
                          color:      Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Leyenda de categorías: ocupa 2/5 del ancho
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topCategories.asMap().entries.map((e) {
                    final i     = e.key;
                    final entry = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          // Bullet coloreado de la categoría
                          Container(
                            width:  10, height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Nombre de la categoría (truncado si es largo)
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Cantidad de usos
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize:   11,
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

// ── Gráfico 3: Línea semanal de Pomodoro ──────────────────────────────────────

/// Widget de línea (LineChart) de sesiones Pomodoro de la semana actual.
///
/// Acumula los minutos de foco por día de la semana (Lun–Dom) a partir
/// del activityLog filtrado por tipo `pomodoroCompleted`.
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

        // Filtramos solo los eventos de Pomodoro completado
        final pomodoroLogs = logs
            .where((l) => l['type'] == ActivityType.pomodoroCompleted)
            .toList();

        // Calculamos el inicio de la semana actual (lunes a las 00:00:00)
        final now         = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay  = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

        // Array de 7 posiciones [0=Lun … 6=Dom], inicializado en 0 minutos
        final dailyMinutes = List.filled(7, 0.0);
        const dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

        for (final log in pomodoroLogs) {
          final ts = log['timestamp'] as Timestamp?;
          if (ts == null) continue;

          final date = ts.toDate();

          // Ignoramos sesiones de semanas anteriores
          if (date.isBefore(startOfDay)) continue;

          // weekday: 1=Lun … 7=Dom → convertimos a índice 0-based
          final dayIndex = date.weekday - 1;

          // Los minutos de la sesión están en metadata.minutes (por defecto 25)
          final metadata = log['metadata'] as Map<String, dynamic>?;
          final minutes  = (metadata?['minutes'] as num?)?.toDouble() ?? 25.0;

          // Acumulamos los minutos del día correspondiente
          dailyMinutes[dayIndex] += minutes;
        }

        // Máximo para escalar el eje Y
        final maxMinutes = dailyMinutes.reduce((a, b) => a > b ? a : b);
        final hasData    = dailyMinutes.any((m) => m > 0); // ¿Hay al menos un día con datos?

        // Estado vacío: sin sesiones esta semana
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
                show:             true,
                drawVerticalLine: false, // Solo cuadrícula horizontal
                horizontalInterval: 15,  // Línea cada 15 minutos
              ),

              titlesData: FlTitlesData(
                show: true,
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                // Eje Y izquierdo: muestra minutos con sufijo "m"
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox(); // Ocultar el 0
                      return Text(
                        '${value.toInt()}m',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),

                // Eje X inferior: nombre del día de la semana
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      // Guard para valores fuera del rango de etiquetas
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
                show:   true,
                border: Border.all(color: Colors.grey.shade200),
              ),

              minX: 0, maxX: 6,   // 7 días de la semana
              minY: 0,
              // +10 para que la línea no toque el borde superior; mínimo 30 si no hay datos
              maxY: maxMinutes > 0 ? maxMinutes + 10 : 30,

              lineBarsData: [
                LineChartBarData(
                  // Un FlSpot por cada día: x = índice del día, y = minutos acumulados
                  spots: List.generate(7, (i) => FlSpot(i.toDouble(), dailyMinutes[i])),
                  isCurved:        true,   // Línea suavizada
                  curveSmoothness: 0.3,    // Curvatura moderada
                  color:           Colors.deepOrange,
                  barWidth:        3,
                  dotData:         const FlDotData(show: true), // Puntos visibles en cada día
                  belowBarData: BarAreaData(
                    show:  true,
                    // Relleno semitransparente bajo la línea para efecto de área
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
