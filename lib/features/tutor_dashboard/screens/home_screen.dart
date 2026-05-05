// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'package:simple/features/onboarding/screens/estudios_screen.dart';
import 'package:simple/features/onboarding/screens/hogar_screen.dart';
import 'package:simple/features/auth/screens/login_screen.dart';
import 'package:simple/features/onboarding/screens/meds_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/settings_screen.dart';
import 'package:simple/features/tda_focus/screens/tareas_screen.dart';
import 'package:simple/core/services/reminder_dispatcher.dart';
import 'package:simple/features/tda_focus/services/streak_service.dart';
import 'package:simple/core/utils/date_time_helper.dart';
import 'package:simple/core/utils/emergency_contact_helper.dart';
import 'package:simple/core/utils/reminder_helper.dart';
import 'package:simple/core/utils/reminder_options.dart';
import 'package:simple/features/onboarding/screens/super_experto_sheet.dart';
import 'package:simple/features/tea_board/screens/pantalla_paciente_tea.dart';
import 'package:simple/core/widgets/custom_nav_bar.dart';

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

  DocumentReference<Map<String, dynamic>> get _userDocRef =>
      FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _userDocRef.collection('tasks');

  final DateFormat _dateTimeFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');

  String get _motivationLine {
    final index = DateTime.now().day % _motivationalPhrases.length;
    return _motivationalPhrases[index];
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: 0),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => SuperExpertoSheet.show(context),
        backgroundColor: const Color(0xFF7B93A3),
        foregroundColor: Colors.white,
        tooltip: 'Súper Experto',
        child: const Icon(Icons.auto_fix_high, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _buildBody(),
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
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                tooltip: 'Cerrar sesión',
                onPressed: _handleLogout,
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
              _buildGreeting(name),
              const SizedBox(height: 28),
              _buildPriorityTaskCard(),
              const SizedBox(height: 28),
              _buildQuickAccess(),
              const SizedBox(height: 20),
              _buildTeaButton(),
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
        final pending =
            docs.where((d) => !(d.data()['done'] as bool? ?? false)).toList();

        pending.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aDue = (aData['dueDate'] as Timestamp?)?.toDate();
          final bDue = (bData['dueDate'] as Timestamp?)?.toDate();
          if (aDue != null && bDue != null) return aDue.compareTo(bDue);
          if (aDue != null) return -1;
          if (bDue != null) return 1;
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

  Widget _buildTeaButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaPacienteTEA()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B8FD4), Color(0xFF3A6BBF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A6BBF).withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.record_voice_over, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo TEA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pictogramas con voz para comunicación',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<void> _toggleTaskCompletion(String taskId, bool isDone) async {
    final messenger = ScaffoldMessenger.of(context);
    final pointsChange = isDone ? -10 : 10;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_tasksCollection.doc(taskId), {'done': !isDone});
    batch.update(_userDocRef, {'points': FieldValue.increment(pointsChange)});
    try {
      await batch.commit();
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al actualizar la tarea.')),
      );
      return;
    }

    if (!isDone) {
      try {
        await ReminderDispatcher.cancelTaskReminder(
            userDocRef: _userDocRef, taskId: taskId);
      } catch (error) {
        debugPrint(
            '[REMINDER] No se pudo cancelar recordatorio $taskId: $error');
      }
      try {
        await StreakService.updateStreakOnTaskCompletion(_userDocRef);
      } catch (error) {
        debugPrint('No se pudo actualizar la racha: $error');
      }
    }
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
                    if (taskController.text.isEmpty || selectedCategory == null)
                      return;
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
