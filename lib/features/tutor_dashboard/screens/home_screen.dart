// ============================================================
// lib/features/tutor_dashboard/screens/home_screen.dart
// ============================================================
// Pantalla principal del rol 'usuario'. Muestra:
//   - Saludo personalizado + frase motivacional del día
//   - Tarjeta de tarea prioritaria (la más urgente pendiente)
//   - Promo del Súper Experto (asistente IA)
//   - Accesos rápidos a Estudios, Hogar y Meds
//
// Arquitectura reactiva:
//   - _userDocRef.snapshots() → puntos, racha, contacto de emergencia
//   - _tasksCollection.snapshots() → tarea prioritaria en tiempo real
//
// La frase motivacional rota día a día usando DateTime.now().day % 6,
// lo que garantiza estabilidad dentro del mismo día sin estado persistente.
//
// La tarjeta de tarea prioritaria usa un algoritmo de ordenamiento:
//   1. Tareas con dueDate más próxima (ascending)
//   2. En empate: las creadas antes (ascending por createdAt)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:simple/features/onboarding/screens/estudios_screen.dart';
import 'package:simple/features/onboarding/screens/hogar_screen.dart';
import 'package:simple/features/onboarding/screens/meds_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/settings_screen.dart';
import 'package:simple/features/tda_focus/screens/tareas_screen.dart';
import 'package:simple/core/services/reminder_dispatcher.dart';
import 'package:simple/features/tda_focus/services/streak_service.dart';
import 'package:simple/core/utils/date_time_helper.dart';
import 'package:simple/core/utils/emergency_contact_helper.dart';
import 'package:simple/core/utils/reminder_helper.dart';
import 'package:simple/core/utils/reminder_options.dart';
import 'package:simple/core/utils/task_urgency_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple/features/onboarding/screens/super_experto_sheet.dart';
import 'package:simple/core/widgets/custom_nav_bar.dart';
import 'package:simple/core/widgets/celebration_overlay.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:simple/core/services/tour_service.dart';
import 'package:simple/core/widgets/tour_step_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Getter directo a FirebaseAuth para no guardar referencia al usuario
  // (el usuario puede cambiar si hace logout/login sin reiniciar la app).
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // Frases motivacionales para usuarios con TEA/TDAH. Se rotan por día del mes.
  static const List<String> _motivationalPhrases = [
    'Paso pequeño también es progreso.',
    'Tu valor no depende de cuántas tareas terminas.',
    'Divide las tareas en pasos pequeños y respira.',
    'Celebra cada avance, por mínimo que parezca.',
    'Puedes pausar, pero no te rindas.',
    'Organizarte es un acto de cuidado propio.',
  ];

  // Referencia al documento del usuario en Firestore.
  DocumentReference<Map<String, dynamic>> get _userDocRef =>
      FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

  // Referencia a la subcolección de tareas del usuario.
  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _userDocRef.collection('tasks');

  // Formateador de fechas en español para las fechas de entrega.
  final DateFormat _dateTimeFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');

  // Selecciona la frase motivacional del día usando el día del mes como índice.
  // Módulo garantiza que el índice nunca esté fuera del rango de la lista.
  String get _motivationLine {
    final index = DateTime.now().day % _motivationalPhrases.length;
    return _motivationalPhrases[index];
  }

  // ── FAB arrastrable ───────────────────────────────────────────────────────
  static const double _fabSize = 56.0;
  static const double _fabTouchSize = 104.0;
  static const double _fabEdgeMargin = 16.0;
  static const double _fabBottomClearance = 40.0;
  static const String _fabDxKey = 'fab_dx_v2';
  static const String _fabDyKey = 'fab_dy_v2';
  Offset _fabOffset = Offset.zero;
  bool _fabReady = false;       // true después de calcular posición inicial
  Offset? _dragOrigin;          // posición del FAB cuando inicia el drag
  Offset? _fabPointerStart;     // punto inicial del dedo/mouse
  bool _fabWasDragged = false;  // diferencia tap vs arrastre real

  final _greetingTourKey    = GlobalKey();
  final _taskCardTourKey    = GlobalKey();
  final _superExpertoTourKey = GlobalKey();
  final _fabTourKey         = GlobalKey();
  final _fabStackKey        = GlobalKey();
  final _navTourKey         = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadFabPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHomeTourIfNeeded());
  }

  Future<void> _loadFabPosition() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final mq = MediaQuery.of(context);
      final safeBottom = mq.padding.bottom + mq.viewInsets.bottom;
      const navBarHeight = 80.0; // Altura aproximada de CustomNavBar

      Future<void> applySaved() async {
        final prefs = await SharedPreferences.getInstance();
        final dx = prefs.getDouble(_fabDxKey);
        final dy = prefs.getDouble(_fabDyKey);
        if (!mounted) return;

        final minTop = mq.padding.top + 16;
        final maxLeft = size.width - _fabSize - _fabEdgeMargin;
        final computedMaxTop = size.height -
            safeBottom -
            navBarHeight -
            _fabSize -
            _fabBottomClearance;
        final maxTop = computedMaxTop < minTop ? minTop : computedMaxTop;
        final defaultTop =
            (size.height * 0.70).clamp(minTop, maxTop).toDouble();

        if (dx != null && dy != null) {
          // Validamos que la posición guardada siga dentro de la pantalla visible
          final clamped = Offset(
            dx.clamp(8.0, maxLeft),
            dy.clamp(minTop, maxTop),
          );
          setState(() {
            _fabOffset = clamped;
            _fabReady = true;
          });
          // Si la posición estaba fuera de límites, guardamos la corregida
          if (clamped.dx != dx || clamped.dy != dy) {
            await prefs.setDouble(_fabDxKey, clamped.dx);
            await prefs.setDouble(_fabDyKey, clamped.dy);
          }
        } else {
          // Primera vez: espacio blanco bajo accesos rápidos, alineado a la derecha.
          setState(() {
            _fabOffset = Offset(maxLeft, defaultTop);
            _fabReady = true;
          });
        }
      }

      applySaved();
    });
  }

  Future<void> _saveFabPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fabDxKey, _fabOffset.dx);
    await prefs.setDouble(_fabDyKey, _fabOffset.dy);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      bottomNavigationBar: KeyedSubtree(
        key: _navTourKey,
        child: const CustomNavBar(screen: NavScreen.inicio),
      ),
      appBar: _buildAppBar(),
      body: Stack(
        key: _fabStackKey,
        children: [
          _buildBody(),
          if (_fabReady) _buildDraggableFab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title:
          const Text('Simple', style: TextStyle(fontWeight: FontWeight.bold)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      automaticallyImplyLeading: false,
      actions: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDocRef.snapshots(),
          builder: (context, snapshot) {
            final d = snapshot.data?.data() ?? {};
            final points = (d['points'] as num?)?.toInt() ?? 0;
            final streak = (d['streak'] as num?)?.toInt() ?? 0;
            final emergencyName = d['emergencyName'] as String?;
            final emergencyPhone =
                d['emergencyPhone'] as String? ?? d['phone'] as String?;
            final hasEmergency = emergencyPhone?.trim().isNotEmpty ?? false;

            return Row(children: [
              const Icon(Icons.star, color: Color(0xFFD4A853), size: 18),
              const SizedBox(width: 2),
              Text('$points',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87)),
              const SizedBox(width: 10),
              const Icon(Icons.local_fire_department,
                  color: Color(0xFFBF8060), size: 18),
              const SizedBox(width: 2),
              Text('$streak',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87)),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.health_and_safety,
                  color: hasEmergency
                      ? const Color(0xFFB05C5C)
                      : Colors.grey.shade400,
                  size: 22,
                ),
                tooltip: 'Contacto de emergencia',
                onPressed: () => handleEmergencyContactAction(
                  context,
                  emergencyName: (emergencyName?.trim().isNotEmpty ?? false)
                      ? emergencyName
                      : null,
                  emergencyPhone: (emergencyPhone?.trim().isNotEmpty ?? false)
                      ? emergencyPhone
                      : null,
                  onNavigateToProfile: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocRef.snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? {};
        final name = (userData['name'] as String?)?.split(' ').first ?? 'amigo';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(key: _greetingTourKey, child: _buildGreeting(name)),
              const SizedBox(height: 28),
              KeyedSubtree(key: _taskCardTourKey, child: _buildPriorityTaskCard()),
              const SizedBox(height: 24),
              KeyedSubtree(key: _superExpertoTourKey, child: _buildSuperExpertoPromo()),
              const SizedBox(height: 28),
              _buildQuickAccess(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreeting(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $name 👋',
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          _motivationLine,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Construye la tarjeta de tarea prioritaria en tiempo real.
  ///
  /// Ordena las tareas pendientes por urgencia:
  ///   - Primero por dueDate más próxima (null al final)
  ///   - En empate: por createdAt más antigua (la tarea más vieja tiene prioridad)
  Widget _buildPriorityTaskCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _tasksCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        // Filtra solo las tareas no completadas.
        final pending =
            docs.where((d) => !(d.data()['done'] as bool? ?? false)).toList();

        // Algoritmo de ordenamiento por urgencia:
        // 1. Si ambas tienen dueDate, la más próxima primero.
        // 2. Si solo una tiene dueDate, esa tiene prioridad.
        // 3. Si ninguna tiene dueDate, ordena por createdAt (más antigua primero).
        pending.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aDue = (aData['dueDate'] as Timestamp?)?.toDate();
          final bDue = (bData['dueDate'] as Timestamp?)?.toDate();
          if (aDue != null && bDue != null) return aDue.compareTo(bDue);
          if (aDue != null) return -1; // a tiene fecha → a es más urgente
          if (bDue != null) return 1;  // b tiene fecha → b es más urgente
          final aCreated = (aData['createdAt'] as Timestamp?)?.toDate();
          final bCreated = (bData['createdAt'] as Timestamp?)?.toDate();
          if (aCreated != null && bCreated != null) {
            return aCreated.compareTo(bCreated);
          }
          return 0;
        });

        if (pending.isEmpty) return _buildEmptyPriorityCard();

        final doc = pending.first;
        final data = doc.data();
        final taskId = doc.id;
        final text = data['text'] as String? ?? '';
        final category = data['category'] as String? ?? 'General';
        final dueDate = data['dueDate'] as Timestamp?;
        final isDone = data['done'] as bool? ?? false;
        final reminderMinutes = extractReminderMinutes(data);

        return _buildTaskCard(
          taskId: taskId,
          text: text,
          category: category,
          dueDate: dueDate,
          isDone: isDone,
          totalPending: pending.length,
          reminderMinutes: reminderMinutes,
        );
      },
    );
  }

  Widget _buildEmptyPriorityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF5F1), Color(0xFFEBF2F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC5D8CE)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 64, color: Color(0xFF7DA88A)),
          const SizedBox(height: 16),
          const Text(
            '¡Todo al día!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A7A5E)),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes tareas pendientes.\nUsa el botón mágico para añadir una.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String taskId,
    required String text,
    required String category,
    required bool isDone,
    required int totalPending,
    Timestamp? dueDate,
    int? reminderMinutes,
  }) {
    final color = _getColorFromString(_getColorNameFromCategory(category));
    final icon = _getIconFromString(_getIconNameFromCategory(category));

    return GestureDetector(
      onLongPress: () => _showTaskOptionsDialog(
          context, taskId, text, category, dueDate, reminderMinutes),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(30), color.withAlpha(12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5),
                  ),
                ]),
                if (dueDate != null) ...[
                  buildTaskUrgencyBadge(dueDate.toDate()) ??
                      const SizedBox.shrink(),
                  if (totalPending > 1) const SizedBox(width: 8),
                ],
                if (totalPending > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${totalPending - 1} más',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'TAREA PRIORITARIA',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3),
            ),
            if (dueDate != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Entrega: ${_dateTimeFormatter.format(dueDate.toDate())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ]),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleTaskCompletion(taskId, isDone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Marcar hecha',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TareasScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperExpertoPromo() {
    return GestureDetector(
      onTap: () => SuperExpertoSheet.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF7C5CBF).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CBF).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CBF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_fix_high_rounded,
                color: Color(0xFF7C5CBF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Te cuesta empezar?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Divide tareas grandes en pasos simples con Súper Experto.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CBF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickAccessItem(
              icon: Icons.menu_book,
              label: 'Estudios',
              color: const Color(0xFFBFA67A),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EstudiosScreen())),
            ),
            const SizedBox(width: 12),
            _buildQuickAccessItem(
              icon: Icons.cottage,
              label: 'Hogar',
              color: const Color(0xFF7DA88A),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HogarScreen())),
            ),
            const SizedBox(width: 12),
            _buildQuickAccessItem(
              icon: Icons.medication,
              label: 'Meds',
              color: const Color(0xFFB98585),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MedsScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Marca o desmarca una tarea como completada y actualiza los puntos.
  ///
  /// Usa batch atómico para que la actualización de puntos y el estado
  /// de la tarea ocurran en la misma operación Firestore.
  ///
  /// Al completar (isDone era false → ahora true):
  ///   - Cancela el recordatorio de notificación de esa tarea.
  ///   - Actualiza la racha diaria del usuario.
  ///
  /// Al descompletar (isDone era true → ahora false):
  ///   - Solo revierte el cambio de puntos, no reactiva el recordatorio.
  Future<void> _toggleTaskCompletion(String taskId, bool isDone) async {
    final messenger = ScaffoldMessenger.of(context);
    // +10 al completar, -10 al descompletar.
    final pointsChange = isDone ? -10 : 10;
    final batch = FirebaseFirestore.instance.batch();
    // Cambia el estado done de la tarea.
    batch.update(_tasksCollection.doc(taskId), {'done': !isDone});
    // Incrementa o decrementa los puntos del usuario.
    batch.update(_userDocRef, {'points': FieldValue.increment(pointsChange)});
    try {
      await batch.commit();
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al actualizar la tarea.')),
      );
      return;
    }

    // Solo al COMPLETAR (no al descompletar) se cancela el recordatorio y se actualiza la racha.
    if (!isDone) {
      // Celebración: confeti + sonido + vibración
      if (mounted) CelebrationOverlay.show(context, message: '¡Tarea completada! 🎉 +10 pts');
      try {
        await ReminderDispatcher.cancelTaskReminder(
            userDocRef: _userDocRef, taskId: taskId);
      } catch (error) {
        debugPrint(
            '[REMINDER] No se pudo cancelar recordatorio $taskId: $error');
      }
      try {
        // StreakService usa una transacción Firestore para actualizar la racha
        // de forma segura (lee el valor actual antes de modificar).
        await StreakService.updateStreakOnTaskCompletion(_userDocRef);
      } catch (error) {
        debugPrint('No se pudo actualizar la racha: $error');
      }
    }
  }

  Future<void> _initHomeTourIfNeeded() async {
    if (!mounted) return;
    final needed = await TourService.needsHomeTour();
    if (needed && mounted) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _startHomeTour();
    }
  }

  void _startHomeTour() {
    final targets = [
      TargetFocus(
        identify: 'greeting',
        keyTarget: _greetingTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const TourStepCard(
              icon: Icons.waving_hand_rounded,
              iconColor: Color(0xFFBFA67A),
              title: 'Inicio',
              body: 'Esta es tu pantalla principal. Aquí ves tu saludo, puntos, racha y un resumen rápido para saber por dónde empezar.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'task_card',
        keyTarget: _taskCardTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const TourStepCard(
              icon: Icons.task_alt_rounded,
              iconColor: Color(0xFF7DA88A),
              title: 'Tarea prioritaria',
              body: 'Aquí aparece la tarea más importante o urgente. Puedes marcarla como hecha, revisar todas tus tareas o crear una nueva cuando lo necesites.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'super_experto',
        keyTarget: _superExpertoTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const TourStepCard(
              icon: Icons.auto_fix_high_rounded,
              iconColor: Color(0xFF7C5CBF),
              title: 'Súper Experto',
              body: 'Si una tarea se siente muy grande, entra aquí para dividirla en pasos simples y fáciles de seguir.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabTourKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const TourStepCard(
              icon: Icons.open_with_rounded,
              iconColor: Color(0xFF7C5CBF),
              title: 'Botón mágico',
              body: 'Tócalo para abrir Súper Experto desde cualquier parte de Inicio. Mantén presionado y arrastra para dejarlo en un lugar cómodo.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'navigation',
        keyTarget: _navTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const TourStepCard(
              icon: Icons.menu_rounded,
              iconColor: Color(0xFF4F7CAC),
              title: 'Menú inferior',
              body: 'Usa esta barra para moverte por la App: Inicio, Tareas, Pictogramas, Foco y Perfil. En Perfil encuentras Configuración, respaldo, cerrar sesión y la opción para repetir este tour.',
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.82,
      hideSkip: false,
      textSkip: 'SALTAR',
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      onFinish: () => TourService.markHomeTourDone(),
      onSkip: () { TourService.markHomeTourDone(); return true; },
    ).show(context: context);
  }

  Widget _buildDraggableFab() {
    final size = MediaQuery.of(context).size;
    const hitSlop = (_fabTouchSize - _fabSize) / 2;
    return Positioned(
      left: _fabOffset.dx - hitSlop,
      top: _fabOffset.dy - hitSlop,
      child: Listener(
        key: _fabTourKey,
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _dragOrigin = _fabOffset;
          _fabPointerStart = event.position;
          _fabWasDragged = false;
        },
        onPointerMove: (event) {
          if (_dragOrigin == null || _fabPointerStart == null) return;
          final delta = event.position - _fabPointerStart!;
          if (!_fabWasDragged && delta.distance <= 4) return;
          if (!_fabWasDragged) {
            _fabWasDragged = true;
            HapticFeedback.mediumImpact();
          }
          final safeBottom = MediaQuery.of(context).padding.bottom +
              MediaQuery.of(context).viewInsets.bottom;
          const navBarHeight = 80.0;
          final computedMaxTop = size.height -
              safeBottom -
              navBarHeight -
              _fabSize -
              _fabBottomClearance;
          final maxTop = computedMaxTop < _fabEdgeMargin
              ? _fabEdgeMargin
              : computedMaxTop;
          setState(() {
            _fabOffset = Offset(
              (_dragOrigin!.dx + delta.dx)
                  .clamp(
                    _fabEdgeMargin,
                    size.width - _fabSize - _fabEdgeMargin,
                  ),
              (_dragOrigin!.dy + delta.dy)
                  .clamp(_fabEdgeMargin, maxTop),
            );
          });
        },
        onPointerUp: (_) {
          final shouldOpen = !_fabWasDragged;
          setState(() {
            _dragOrigin = null;
            _fabPointerStart = null;
            _fabWasDragged = false;
          });
          if (shouldOpen) {
            SuperExpertoSheet.show(context);
          } else {
            _saveFabPosition();
          }
        },
        onPointerCancel: (_) {
          setState(() {
            _dragOrigin = null;
            _fabPointerStart = null;
            _fabWasDragged = false;
          });
        },
        child: SizedBox.square(
          dimension: _fabTouchSize,
          child: Center(
            child: AnimatedScale(
              scale: _dragOrigin != null ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: SizedBox.square(
                dimension: _fabSize,
                child: FloatingActionButton(
                  onPressed: null, // manejado por GestureDetector
                  backgroundColor: const Color(0xFF7C5CBF),
                  foregroundColor: Colors.white,
                  tooltip: 'Súper Experto\n(arrastra para mover)',
                  elevation: _dragOrigin != null ? 12 : 8,
                  child: const Icon(Icons.auto_fix_high, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskOptionsDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? reminderMinutes,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Opciones:\n"$currentText"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showEditTaskDialog(context, taskId, currentText,
                      currentCategory, currentDueDate, reminderMinutes);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await _tasksCollection.doc(taskId).delete();
                    try {
                      await ReminderDispatcher.cancelTaskReminder(
                          userDocRef: _userDocRef, taskId: taskId);
                    } catch (e) {
                      debugPrint('Error al cancelar notificación: $e');
                    }
                    if (navigator.mounted) navigator.pop();
                    messenger.showSnackBar(
                        SnackBar(content: Text('"$currentText" eliminada')));
                  } catch (error) {
                    debugPrint('Error al eliminar tarea $taskId: $error');
                    if (navigator.mounted) navigator.pop();
                    messenger.showSnackBar(
                        SnackBar(content: Text('Error al eliminar: $error')));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? currentReminderMinutes,
  ) {
    final TextEditingController taskController =
        TextEditingController(text: currentText);
    final List<String> categories = [
      'General',
      'Estudios',
      'Hogar',
      'Meds',
      'Foco',
    ];
    String? selectedCategory =
        categories.contains(currentCategory) ? currentCategory : 'General';
    DateTime? selectedDueDate = currentDueDate?.toDate();
    int? selectedReminderMinutes = currentReminderMinutes;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: const Text('Editar tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Nuevo texto'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedCategory = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha'
                                : 'Entrega: ${_dateTimeFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await pickDateTime(
                                context: statefulContext,
                                initialDate: selectedDueDate);
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setDialogState(() => selectedDueDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      key: ValueKey(selectedReminderMinutes),
                      decoration: const InputDecoration(
                          labelText: 'Recordatorio',
                          border: OutlineInputBorder()),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map((o) => DropdownMenuItem<int?>(
                                value: o['minutes'] as int?,
                                child: Text(o['label'] as String),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedReminderMinutes = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (taskController.text.isEmpty || selectedCategory == null) {
                      return;
                    }
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);
                    final updatedData = <String, dynamic>{
                      'text': taskController.text,
                      'category': selectedCategory,
                      'iconName': _getIconNameFromCategory(selectedCategory!),
                      'colorName': _getColorNameFromCategory(selectedCategory!),
                      'reminderMinutes': selectedReminderMinutes,
                      'reminderOffsetMinutes': FieldValue.delete(),
                      'dueDate': selectedDueDate == null
                          ? FieldValue.delete()
                          : Timestamp.fromDate(selectedDueDate!),
                    };
                    try {
                      await _tasksCollection.doc(taskId).update(updatedData);
                      await ReminderDispatcher.cancelTaskReminder(
                          userDocRef: _userDocRef, taskId: taskId);
                      await ReminderDispatcher.scheduleTaskReminder(
                        userDocRef: _userDocRef,
                        taskId: taskId,
                        taskTitle: taskController.text,
                        dueDate: selectedDueDate,
                        reminderMinutes: selectedReminderMinutes,
                      );
                    } catch (error) {
                      debugPrint('Error al actualizar tarea $taskId: $error');
                      messenger.showSnackBar(const SnackBar(
                        content: Text('No se pudo guardar los cambios.'),
                      ));
                    } finally {
                      if (navigator.mounted && navigator.canPop()) {
                        navigator.pop();
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return Icons.menu_book;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'medication':
        return Icons.medication;
      case 'psychology':
        return Icons.psychology;
      default:
        return Icons.task_alt;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange':
        return const Color(0xFFBFA67A);
      case 'green':
        return const Color(0xFF7DA88A);
      case 'red':
        return const Color(0xFFB98585);
      case 'purple':
        return const Color(0xFF9486AD);
      case 'grey':
        return const Color(0xFF8B9FAE);
      default:
        return const Color(0xFF7EA3BC);
    }
  }

  String _getIconNameFromCategory(String category) {
    switch (category) {
      case 'Estudios':
        return 'menu_book';
      case 'Hogar':
        return 'cleaning_services';
      case 'Meds':
        return 'medication';
      case 'Foco':
        return 'psychology';
      default:
        return 'task_alt';
    }
  }

  String _getColorNameFromCategory(String category) {
    switch (category) {
      case 'Estudios':
        return 'orange';
      case 'Hogar':
        return 'green';
      case 'Meds':
        return 'red';
      case 'Foco':
        return 'purple';
      default:
        return 'grey';
    }
  }
}
