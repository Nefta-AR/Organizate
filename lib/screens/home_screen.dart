import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:organizate/main.dart';
import 'package:organizate/screens/estudios_screen.dart';
import 'package:organizate/screens/foco_screen.dart';
import 'package:organizate/screens/hogar_screen.dart';
import 'package:organizate/screens/meds_screen.dart';
import 'package:organizate/screens/settings_screen.dart';
import 'package:organizate/services/reminder_dispatcher.dart';
import 'package:organizate/services/streak_service.dart';
import 'package:organizate/utils/date_time_helper.dart';
import 'package:organizate/utils/emergency_contact_helper.dart';
import 'package:organizate/utils/reminder_helper.dart';
import 'package:organizate/utils/reminder_options.dart';
import 'package:organizate/widgets/custom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  static const List<String> _motivationalPhrases = [
    'Paso pequeño también es progreso.',
    'Tu valor no depende de cuántas tareas terminas.',
    'Divide las tareas en pasos pequeños y respira.',
    'Celebra cada avance, por mínimo que parezca.',
    'Puedes pausar, pero no te rindas.',
    'Organizarte es un acto de cuidado propio.',
  ];

  DocumentReference<Map<String, dynamic>> get userDocRef =>
      FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

  CollectionReference<Map<String, dynamic>> get tasksCollection =>
      userDocRef.collection('tasks');

  final DateFormat _dateTimeFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');

  String get _motivationLine {
    const phrases = _motivationalPhrases;
    if (phrases.isEmpty) return '';
    final index = DateTime.now().day % phrases.length;
    return phrases[index];
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: 0),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressHeader(),
            const SizedBox(height: 16),
            _buildEmergencyContactBanner(),
            const SizedBox(height: 24),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            _buildTodayGoalsHeader(),
            const SizedBox(height: 16),
            _buildTasksStream(),
          ],
        ),
      ),
    );
  }

  // AppBar con puntos, racha y acceso al perfil.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Organízate'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      automaticallyImplyLeading: false,
      actions: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasError ||
                !snapshot.hasData) {
              return const Row(
                children: [
                  Icon(Icons.star, color: Colors.grey, size: 20),
                  SizedBox(width: 4),
                  Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 16),
                  Icon(Icons.local_fire_department, color: Colors.grey, size: 20),
                  SizedBox(width: 4),
                  Text('...'),
                  SizedBox(width: 16),
                  Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              );
            }
            final userData = snapshot.data!.data() ?? {};
            final int points = (userData['points'] as num?)?.toInt() ?? 0;
            final int streak = (userData['streak'] as num?)?.toInt() ?? 0;
            final String? avatarName = userData['avatar'] as String?;

            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.deepOrange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarName != null
                          ? AssetImage('assets/avatars/$avatarName.png')
                          : null,
                      child: avatarName == null
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: _handleLogout,
        ),
      ],
    );
  }

Future<void> _handleLogout() async {
  try {
    // Cierra sesión en Firebase
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    // Espera un poco a que el estado se actualice internamente
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Limpia todo el stack y vuelve al AuthGate (no directamente al LoginScreen)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  } catch (e, stack) {
    debugPrint('Error al cerrar sesión: $e');
    debugPrint('$stack');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al cerrar sesión')),
    );
  }
}


  // Muestra el progreso del día calculando tareas completadas hoy.
  Widget _buildProgressHeader() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tasksCollection.snapshots(),
      builder: (context, snapshot) {
        double progress = 0;
        String percentText = '0%';
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));
          int totalTasks = 0;
          int completedTasks = 0;

          for (final doc in docs) {
            final data = doc.data();
            final Timestamp? dueStamp = data['dueDate'] as Timestamp?;
            final Timestamp? createdStamp = data['createdAt'] as Timestamp?;
            final DateTime? referenceDate =
                dueStamp?.toDate() ?? createdStamp?.toDate();
            if (referenceDate == null) continue;
            if (!referenceDate.isBefore(startOfDay) &&
                referenceDate.isBefore(endOfDay)) {
              totalTasks++;
              if ((data['done'] as bool?) ?? false) {
                completedTasks++;
              }
            }
          }

          if (totalTasks > 0) {
            progress = completedTasks / totalTasks;
            percentText = '${(progress * 100).round()}%';
          }
        }
        return _buildHeaderCard(
          progress.clamp(0.0, 1.0).toDouble(),
          percentText,
          _motivationLine,
        );
      },
    );
  }

  // Tarjeta que enseña progreso y frase motivacional.
  Widget _buildEmergencyContactBanner() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocRef.snapshots(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data?.data();
        final String? emergencyName = data?['emergencyName'] as String?;
        final String? emergencyPhone =
            data?['emergencyPhone'] as String? ?? data?['phone'] as String?;

        final String? trimmedName =
            (emergencyName?.trim().isEmpty ?? true) ? null : emergencyName!.trim();
        final String? trimmedPhone =
            (emergencyPhone?.trim().isEmpty ?? true) ? null : emergencyPhone!.trim();

        final String subtitle = isLoading
            ? 'Cargando tu contacto...'
            : trimmedPhone != null
                ? (trimmedName != null
                    ? '$trimmedName - $trimmedPhone'
                    : trimmedPhone)
                : 'Configura un contacto desde tu perfil.';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contacto de emergencia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => handleEmergencyContactAction(
                  context,
                  emergencyName: trimmedName ?? emergencyName,
                  emergencyPhone: trimmedPhone ?? emergencyPhone,
                  onNavigateToProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('SOS'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
      double progress, String percentText, String motivationalText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola 👋',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hoy, enfoquémonos en...',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 180,
                child: Text(
                  motivationalText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.green.withAlpha(50),
                  color: Colors.green,
                ),
                Center(
                  child: Text(
                    percentText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Resumen por categoría para saltar rápido a cada vista especializada.
  Widget _buildCategoryGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tasksCollection.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final Map<String, List<Map<String, dynamic>>> pendingByCategory = {
          'Estudios': [],
          'Hogar': [],
          'Meds': [],
          'Foco': [],
          'General': [],
        };
        for (final doc in docs) {
          final data = doc.data();
          final bool isDone = (data['done'] as bool?) ?? false;
          if (isDone) continue;
          final category = (data['category'] as String?) ?? 'General';
          final normalized = pendingByCategory.containsKey(category)
              ? category
              : 'General';
          final list = pendingByCategory[normalized];
          if (list != null) {
            list.add(data);
          }
        }

        List<String> topTasksFor(String category) {
          final entries =
              pendingByCategory[category] ?? <Map<String, dynamic>>[];
          return entries
              .map((task) => (task['text'] as String?)?.trim())
              .whereType<String>()
              .where((text) => text.isNotEmpty)
              .take(3)
              .toList();
        }

        int countFor(String category) =>
            pendingByCategory[category]?.length ?? 0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildCategoryCard(
              title: 'Estudios',
              subtitle: 'Organiza tus clases',
              icon: Icons.menu_book,
              color: Colors.orange,
              pendingCount: countFor('Estudios'),
              topTasks: topTasksFor('Estudios'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EstudiosScreen()),
              ),
            ),
            _buildCategoryCard(
              title: 'Hogar',
              subtitle: 'Lista visual',
              icon: Icons.cottage,
              color: Colors.green,
              pendingCount: countFor('Hogar'),
              topTasks: topTasksFor('Hogar'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HogarScreen()),
              ),
            ),
            _buildCategoryCard(
              title: 'Medicamentos',
              subtitle: 'Recordatorios',
              icon: Icons.medication,
              color: Colors.red,
              pendingCount: countFor('Meds'),
              topTasks: topTasksFor('Meds'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedsScreen()),
              ),
            ),
            _buildCategoryCard(
              title: 'Foco',
              subtitle: 'Respira y enfoca',
              icon: Icons.self_improvement,
              color: Colors.purple,
              pendingCount: countFor('Foco'),
              topTasks: topTasksFor('Foco'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FocoScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget reutilizable para dibujar cada tarjeta de categoría.
  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int pendingCount,
    required List<String> topTasks,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(40),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            if (pendingCount == 0)
              const Text(
                'Sin tareas pendientes',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              )
            else ...[
              Text(
                '$pendingCount pendientes',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Lista scrollable con límite de alto para evitar desbordes
              Flexible(
                    child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 56, // ~3-4 líneas
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: topTasks.length,
                        itemBuilder: (context, index) {
                          final task = topTasks[index];
                          return Text(
                            '• $task',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (pendingCount > topTasks.length)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    '…',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Encabezado simple para la lista de tareas del día.
  Widget _buildTodayGoalsHeader() {
    return const Text(
      'Tus metas de hoy',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Lista en vivo de tareas ordenadas por fecha de creación.
  Widget _buildTasksStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tasksCollection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar tareas'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Añade tu primera tarea con el botón +'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final taskId = docs[index].id;
            final String text = data['text'] as String? ?? '';
            final String? category = data['category'] as String?;
            final Timestamp? dueDate = data['dueDate'] as Timestamp?;
            final int? reminderMinutes = extractReminderMinutes(data);
            final bool isDone = data['done'] as bool? ?? false;
            return GestureDetector(
              onLongPress: () => _showTaskOptionsDialog(
                context,
                taskId,
                text,
                category,
                dueDate,
                reminderMinutes,
              ),
              child: _buildGoalItem(
                icon: _getIconFromString(data['iconName'] as String? ?? 'task_alt'),
                iconColor:
                    _getColorFromString(data['colorName'] as String? ?? 'grey'),
                text: text,
                isDone: isDone,
                dueDate: dueDate,
                onDonePressed: () => _toggleTaskCompletion(taskId, isDone),
              ),
            );
          },
        );
      },
    );
  }

  // Tarjeta reutilizable que muestra una tarea cualquiera.
  Widget _buildGoalItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDone,
    required VoidCallback onDonePressed,
    Timestamp? dueDate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDone ? Colors.grey : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Entrega: ${_dateTimeFormatter.format(dueDate.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(30),
              foregroundColor:
                  isDone ? Colors.grey.shade600 : Colors.blue.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isDone ? 'Deshacer' : 'Hecho'),
          ),
        ],
      ),
    );
  }

  /// Cambia el estado de una tarea, actualiza puntos y, si aplica, la racha.
  Future<void> _toggleTaskCompletion(String taskId, bool isDone) async {
    final messenger = ScaffoldMessenger.of(context);
    // Suma 10 puntos al completar y resta 10 al deshacer.
    final pointsChange = isDone ? -10 : 10;
    final batch = FirebaseFirestore.instance.batch();
    // 1) Invierte el campo done.
    batch.update(tasksCollection.doc(taskId), {'done': !isDone});
    // 2) Ajusta los puntos del usuario.
    batch.update(userDocRef, {'points': FieldValue.increment(pointsChange)});
    try {
      // 3) Ejecuta ambas operaciones juntas para mantener consistencia.
      await batch.commit();
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al actualizar la tarea.')),
      );
      return;
    }

    // Solo al pasar de pendiente -> completada evaluamos la racha.
    if (!isDone) {
      try {
        await ReminderDispatcher.cancelTaskReminder(
          userDocRef: userDocRef,
          taskId: taskId,
        );
      } catch (error, stack) {
        debugPrint(
            '[REMINDER] No se pudo cancelar recordatorio para $taskId: $error');
        debugPrint('$stack');
      }

      try {
        await StreakService.updateStreakOnTaskCompletion(userDocRef);
      } catch (error) {
        debugPrint('No se pudo actualizar la racha: $error');
      }
    }
  }

  // Diálogo para crear una tarea con categoría, fecha y recordatorio.
  // Diálogo para crear una tarea con categoría, fecha y recordatorio.
Future<void> _showAddTaskDialog(BuildContext screenContext) async {
  final TextEditingController taskController = TextEditingController();
  final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds'];
  String? selectedCategory = 'General';
  DateTime? selectedDueDate;
  bool isSaving = false; // 👈 evita múltiples taps
  final int? defaultReminder = await fetchDefaultReminderMinutes(userDocRef);
  int? selectedReminderMinutes = defaultReminder;
  if (!screenContext.mounted) return;

  showDialog(
    context: screenContext,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (statefulContext, setDialogState) {
          return AlertDialog(
            title: const Text('Nueva tarea'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskController,
                    decoration: const InputDecoration(hintText: 'Descripción'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
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
                            initialDate: selectedDueDate,
                          );
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
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedReminderMinutes,
                    items: kReminderOptions
                        .map(
                          (option) => DropdownMenuItem<int?>(
                            value: option['minutes'] as int?,
                            child: Text(option['label'] as String),
                          ),
                        )
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
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (taskController.text.trim().isEmpty ||
                            selectedCategory == null) {
                          return;
                        }

                        setDialogState(() => isSaving = true); // 🚫 bloquea taps
                        try {
                          final iconName =
                              _getIconNameFromCategory(selectedCategory!);
                          final colorName =
                              _getColorNameFromCategory(selectedCategory!);

                          final data = <String, dynamic>{
                            'text': taskController.text.trim(),
                            'category': selectedCategory,
                            'iconName': iconName,
                            'colorName': colorName,
                            'done': false,
                            'createdAt': Timestamp.now(),
                            'reminderMinutes': selectedReminderMinutes,
                            if (selectedDueDate != null)
                              'dueDate': Timestamp.fromDate(selectedDueDate!),
                          };

                          final docRef = await tasksCollection.add(data);
                          await ReminderDispatcher.scheduleTaskReminder(
                            userDocRef: userDocRef,
                            taskId: docRef.id,
                            taskTitle: taskController.text,
                            dueDate: selectedDueDate,
                            reminderMinutes: selectedReminderMinutes,
                          );

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(); // ✅ cierra 1 sola vez
                            if (!screenContext.mounted) return;
                            ScaffoldMessenger.of(screenContext).showSnackBar(
                              const SnackBar(
                                content: Text('Tarea añadida correctamente'),
                              ),
                            );
                          }
                        } catch (e, stack) {
                          debugPrint('Error al añadir tarea: $e');
                          debugPrint('$stack');
                          if (!screenContext.mounted) return;
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            const SnackBar(
                              content: Text('Error al crear la tarea'),
                            ),
                          );
                        } finally {
                          setDialogState(() => isSaving = false);
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('Añadir'),
              ),
            ],
          );
        },
      );
    },
  );
}


  // Menú contextual que permite editar o eliminar una tarea.
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
                  _showEditTaskDialog(
                    context,
                    taskId,
                    currentText,
                    currentCategory,
                    currentDueDate,
                    reminderMinutes,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await tasksCollection.doc(taskId).delete();
                    debugPrint('Tarea $taskId eliminada correctamente');
                    try {
                      await ReminderDispatcher.cancelTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                      );
                      debugPrint('Notificación de $taskId cancelada');
                    } catch (e, stack) {
                      debugPrint('Error al cancelar notificación de $taskId: $e');
                      debugPrint('$stack');
                    }
                    if (navigator.mounted) {
                      navigator.pop();
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text('"$currentText" eliminada')),
                    );
                  } catch (error, stack) {
                    debugPrint('Error al eliminar tarea $taskId: $error');
                    debugPrint('$stack');
                    if (navigator.mounted) {
                      navigator.pop();
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al eliminar: $error')),
                    );
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

  // Diálogo de edición reutilizable con mismos campos que el alta.
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
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
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
                              initialDate: selectedDueDate,
                            );
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
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map(
                            (option) => DropdownMenuItem<int?>(
                              value: option['minutes'] as int?,
                              child: Text(option['label'] as String),
                            ),
                          )
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
                  if (taskController.text.isEmpty ||
                      selectedCategory == null) {
                    return;
                  }
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);
                  final iconName =
                      _getIconNameFromCategory(selectedCategory!);
                  final colorName =
                      _getColorNameFromCategory(selectedCategory!);
                    final updatedData = <String, dynamic>{
                        'text': taskController.text,
                        'category': selectedCategory,
                        'iconName': iconName,
                        'colorName': colorName,
                        'reminderMinutes': selectedReminderMinutes,
                        'reminderOffsetMinutes': FieldValue.delete(),
                        'dueDate': selectedDueDate == null
                            ? FieldValue.delete()
                            : Timestamp.fromDate(selectedDueDate!),
                    };
                    try {
                      await tasksCollection.doc(taskId).update(updatedData);
                      await ReminderDispatcher.cancelTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                      );
                      await ReminderDispatcher.scheduleTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                        taskTitle: taskController.text,
                        dueDate: selectedDueDate,
                        reminderMinutes: selectedReminderMinutes,
                      );
                    } catch (error, stack) {
                      debugPrint('Error al actualizar tarea $taskId: $error');
                      debugPrint('$stack');
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo guardar los cambios.'),
                        ),
                      );
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

  // Convierte el nombre guardado en Firestore al IconData correspondiente.
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
      case 'task_alt':
      default:
        return Icons.task_alt;
    }
  }

  // Convierte el identificador textual al color usado en la tarjeta.
  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Helpers de selección inversa: dado una categoría, devuelve nombre de icono.
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
      case 'General':
      default:
        return 'task_alt';
    }
  }

  // Y en este helper lo mismo pero para el color.
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
      case 'General':
      default:
        return 'grey';
    }
  }
}
