// ============================================================
// lib/features/tda_focus/screens/tareas_screen.dart
// ============================================================
// Pantalla de gestión de tareas del usuario TDAH.
//
// ## Arquitectura de datos
//
// Las tareas se almacenan en `users/{uid}/tasks`. El tutor puede crear tareas
// para el usuario (campo `addedByTutor: true`); el usuario solo puede editarlas.
//
// ## Soft-delete
//
// Cuando el usuario elimina una tarea, se marca con `deletedByUser: true`
// en lugar de borrarse físicamente. Esto preserva el registro para el tutor
// en [_TutorTasksTab], que filtra por ese campo para mostrar una sección
// separada de "Eliminadas por el usuario". El stream del usuario filtra
// los documentos con ese flag para que no aparezcan en su vista.
//
// ## Sistema de puntos y racha
//
// Al completar una tarea se suman puntos (+10) y se delega en [StreakService]
// para actualizar la racha diaria. El streak se basa en si el usuario completó
// al menos una tarea en días consecutivos (no en el número de tareas).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:simple/core/services/activity_log_service.dart';
import 'package:simple/core/services/reminder_dispatcher.dart';
import 'package:simple/features/tda_focus/services/streak_service.dart';
import 'package:simple/core/utils/date_time_helper.dart';
import 'package:simple/core/utils/reminder_helper.dart';
import 'package:simple/core/utils/reminder_options.dart';
import 'package:simple/core/utils/task_urgency_helper.dart';
import 'package:simple/core/utils/task_visibility_helper.dart';
import 'package:simple/core/widgets/custom_nav_bar.dart';
import 'package:simple/core/widgets/celebration_overlay.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  late final CollectionReference<Map<String, dynamic>> _tasksCollection;
  late final DocumentReference<Map<String, dynamic>> _userDocRef;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream;
  final DateFormat _dateFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');
  String? _selectedCategory;

  static const _filters = [
    _CategoryFilter(
        label: 'Todas',
        value: null,
        icon: Icons.apps_rounded,
        color: Colors.blueGrey),
    _CategoryFilter(
        label: 'Estudios',
        value: 'Estudios',
        icon: Icons.menu_book,
        color: Colors.orange),
    _CategoryFilter(
        label: 'Hogar',
        value: 'Hogar',
        icon: Icons.cottage,
        color: Colors.green),
    _CategoryFilter(
        label: 'Meds',
        value: 'Meds',
        icon: Icons.medication,
        color: Colors.red),
    _CategoryFilter(
        label: 'Foco',
        value: 'Foco',
        icon: Icons.self_improvement,
        color: Colors.purple),
    _CategoryFilter(
        label: 'General',
        value: 'General',
        icon: Icons.task_alt,
        color: Colors.blueGrey),
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Inicializa las referencias en initState para evitar recalcularlas en build.
    _userDocRef      = FirebaseFirestore.instance.collection('users').doc(uid);
    _tasksCollection = _userDocRef.collection('tasks');
    _userDocStream   = _userDocRef.snapshots(); // Stream cacheado para el AppBar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(screen: NavScreen.tareas),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildTasksList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mis tareas'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      automaticallyImplyLeading: false,
      actions: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDocStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final d = snapshot.data!.data() ?? {};
            final points = (d['points'] as num?)?.toInt() ?? 0;
            final streak = (d['streak'] as num?)?.toInt() ?? 0;
            final avatar = d['avatar'] as String?;
            return Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 2),
              Text('$points',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              const SizedBox(width: 12),
              const Icon(Icons.local_fire_department,
                  color: Colors.deepOrange, size: 20),
              const SizedBox(width: 2),
              Text('$streak',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatar != null
                      ? AssetImage('assets/avatars/$avatar.png')
                      : null,
                  child: avatar == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final f = _filters[i];
          final isSelected = _selectedCategory == f.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = f.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? f.color.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? f.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(f.icon,
                    size: 14,
                    color: isSelected ? f.color : Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? f.color : Colors.grey.shade700,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  /// Lista en tiempo real de tareas con tres niveles de filtrado:
  ///   1. Excluye las marcadas como soft-deleted (deletedByUser: true)
  ///   2. Filtra por categoría si hay un chip seleccionado
  ///   3. Ordena pendientes primero, completadas al final
  Widget _buildTasksList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Ordenar por createdAt desc en Firestore garantiza que las tareas más
      // recientes aparezcan primero dentro de cada grupo (pendiente/completada).
      stream:
          _tasksCollection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar tareas'));
        }

        // Nivel 1: Excluye soft-deleted. El tutor puede verlas en su panel.
        final all = (snapshot.data?.docs ?? [])
            .where((d) => d.data()['deletedByUser'] != true)
            .where((d) => shouldShowTaskToday(d.data()))
            .toList();

        // Nivel 2: Filtro por categoría (null = "Todas").
        final filtered = _selectedCategory == null
            ? all
            : all
                .where((d) => d.data()['category'] == _selectedCategory)
                .toList();

        // Nivel 3: Pendientes arriba, completadas abajo.
        final sorted = [...filtered]..sort((a, b) {
            final aDone = a.data()['done'] as bool? ?? false;
            final bDone = b.data()['done'] as bool? ?? false;
            if (aDone == bDone) return 0;
            return aDone ? 1 : -1; // false (pendiente) → 0, true (done) → 1
          });

        if (sorted.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  _selectedCategory == null
                      ? 'Añade tu primera tarea con el botón +'
                      : 'Sin tareas en "$_selectedCategory"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                ),
              ]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final doc = sorted[i];
            final data = doc.data();
            final taskId = doc.id;
            final text = data['text'] as String? ?? '';
            final category = data['category'] as String? ?? 'General';
            final dueDate = data['dueDate'] as Timestamp?;
            final isDone = data['done'] as bool? ?? false;
            final reminderMinutes = extractReminderMinutes(data);
            final addedByTutor = data['addedByTutor'] == true;
            final tutorNote = data['note'] as String?;
            final recurrence = data['recurrence'] as String?;

            return Dismissible(
              key: ValueKey(taskId),
              // Solo las tareas COMPLETADAS son deslizables para eliminar.
              // Evita eliminaciones accidentales de tareas pendientes.
              direction: isDone
                  ? DismissDirection.horizontal
                  : DismissDirection.none,
              background: _buildDismissBackground(Alignment.centerLeft),
              secondaryBackground:
                  _buildDismissBackground(Alignment.centerRight),
              // Soft-delete: no borra de Firestore, solo marca deletedByUser: true.
              onDismissed: (_) => _deleteTask(taskId, text),
              child: GestureDetector(
                onLongPress: () => _showTaskOptionsDialog(
                    context, taskId, text, category, dueDate, reminderMinutes),
                child: _buildTaskItem(
                  taskId: taskId,
                  text: text,
                  category: category,
                  dueDate: dueDate,
                  isDone: isDone,
                  addedByTutor: addedByTutor,
                  tutorNote: tutorNote,
                  recurrence: recurrence,
                  onToggle: () => _toggleTask(taskId, isDone),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskItem({
    required String taskId,
    required String text,
    required String category,
    required bool isDone,
    required VoidCallback onToggle,
    Timestamp? dueDate,
    bool addedByTutor = false,
    String? tutorNote,
    String? recurrence,
  }) {
    final color = _colorOf(category);
    final icon = _iconOf(category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: isDone ? Colors.grey : color),
          ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDone ? Colors.grey : Colors.black87,
              decoration:
                  isDone ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle: (dueDate != null || addedByTutor || recurrence != null || (tutorNote != null && tutorNote.isNotEmpty))
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tutorNote != null && tutorNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 12, color: Colors.blue.shade300),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tutorNote,
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade400, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (dueDate != null || addedByTutor || recurrence != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (addedByTutor) ...[
                            const Icon(Icons.person_pin, size: 12, color: Colors.blue),
                            const SizedBox(width: 3),
                            const Text('Tutor',
                                style: TextStyle(fontSize: 11, color: Colors.blue)),
                            if (dueDate != null || recurrence != null) const SizedBox(width: 8),
                          ],
                          if (dueDate != null) ...[
                            buildTaskUrgencyBadge(dueDate.toDate()) ??
                                const SizedBox.shrink(),
                            const SizedBox(width: 8),
                            Text(
                              _dateFormatter.format(dueDate.toDate()),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                          if (recurrence != null) ...[
                            if (dueDate != null) const SizedBox(width: 8),
                            Icon(Icons.repeat_rounded, size: 12, color: Colors.teal.shade500),
                            const SizedBox(width: 2),
                            Text(
                              _recurrenceLabel(recurrence),
                              style: TextStyle(fontSize: 11, color: Colors.teal.shade500),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                )
              : null,
          trailing: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Alterna el estado done de una tarea y actualiza puntos en batch atómico.
  ///
  /// Al COMPLETAR (isDone cambia de false a true):
  ///   1. Cancela el recordatorio de notificación
  ///   2. Actualiza la racha diaria (StreakService)
  ///   3. Registra la actividad en el log del usuario (visible para el tutor)
  Future<void> _toggleTask(String taskId, bool isDone) async {
    final pointsChange = isDone ? -10 : 10; // +10 al completar, -10 al descompletar
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_tasksCollection.doc(taskId), {
      'done': !isDone,
      'completedAt': isDone
          ? FieldValue.delete()
          : FieldValue.serverTimestamp(),
    });
    batch.update(_userDocRef, {'points': FieldValue.increment(pointsChange)});
    try {
      await batch.commit();
      if (!isDone) {
        // Celebración: confeti + sonido + vibración
        if (mounted) CelebrationOverlay.show(context);
        // Cancela el recordatorio local para que no llegue una notificación
        // de una tarea que el usuario ya marcó como hecha.
        await ReminderDispatcher.cancelTaskReminder(
            userDocRef: _userDocRef, taskId: taskId);
        // Transacción Firestore que actualiza el streak de forma segura.
        await StreakService.updateStreakOnTaskCompletion(_userDocRef);
        // Leer el texto de la tarea para el log (el texto no está en memoria aquí).
        final taskSnap = await _tasksCollection.doc(taskId).get();
        final taskText = taskSnap.data()?['text'] as String? ?? '';
        // Registro de auditoría: el tutor puede ver esto en _TutorHistorialTab.
        await ActivityLogService.log(
          userId: _userDocRef.id,
          type: ActivityType.taskCompleted,
          description: 'Tarea completada: "$taskText"',
          metadata: {'taskId': taskId},
        );
      }
    } catch (e) {
      debugPrint('Error al actualizar tarea: $e');
    }
  }

  Widget _buildDismissBackground(AlignmentGeometry alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
    );
  }

  /// Soft-delete: marca la tarea como eliminada sin borrarla de Firestore.
  ///
  /// El tutor puede ver las tareas eliminadas en la sección "Eliminadas"
  /// de su panel. El campo deletedAt permite al tutor saber cuándo ocurrió.
  Future<void> _deleteTask(String taskId, String text) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'deletedByUser': true,              // Flag de soft-delete
        'deletedAt': FieldValue.serverTimestamp(), // Timestamp de eliminación
      });
      await ReminderDispatcher.cancelTaskReminder(
          userDocRef: _userDocRef, taskId: taskId);
      await ActivityLogService.log(
        userId: _userDocRef.id,
        type: ActivityType.taskDeleted,
        description: 'Tarea eliminada: "$text"',
        metadata: {'taskId': taskId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$text" eliminada')),
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar tarea: $e');
    }
  }

  Future<void> _showAddTaskDialog(BuildContext screenContext) async {
    final ctrl = TextEditingController();
    final categories = ['General', 'Estudios', 'Hogar', 'Meds', 'Foco'];
    String? selectedCat = _selectedCategory ?? 'General';
    DateTime? selectedDate;
    bool isSaving = false;
    bool repeatEnabled = false;
    String recurrence = 'daily';
    final defaultReminder = await fetchDefaultReminderMinutes(_userDocRef);
    int? selectedReminder = defaultReminder;
    if (!screenContext.mounted) return;

    showDialog(
      context: screenContext,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (statCtx, setDlg) => AlertDialog(
          title: const Text('Nueva tarea'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'Descripción'),
                autofocus: true,
              ),
              if (_suggestionsFor(selectedCat).isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _suggestionsFor(selectedCat).map((s) =>
                      ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: _colorOf(selectedCat ?? 'General')
                            .withValues(alpha: 0.10),
                        side: BorderSide(
                          color: _colorOf(selectedCat ?? 'General')
                              .withValues(alpha: 0.35),
                        ),
                        onPressed: () {
                          ctrl.text = s;
                          ctrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: s.length),
                          );
                          setDlg(() {});
                        },
                      ),
                    ).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDlg(() => selectedCat = v),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? 'Sin fecha'
                        : 'Entrega: ${_dateFormatter.format(selectedDate!)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: () async {
                    final p = await pickDateTime(
                        context: statCtx, initialDate: selectedDate);
                    if (p != null) setDlg(() => selectedDate = p);
                  },
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setDlg(() => selectedDate = null),
                  ),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                key: ValueKey(selectedReminder),
                decoration: const InputDecoration(
                    labelText: 'Recordatorio', border: OutlineInputBorder()),
                initialValue: selectedReminder,
                items: kReminderOptions
                    .map((o) => DropdownMenuItem<int?>(
                          value: o['minutes'] as int?,
                          child: Text(o['label'] as String),
                        ))
                    .toList(),
                onChanged: (v) => setDlg(() => selectedReminder = v),
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                title: const Text('Repetir', style: TextStyle(fontSize: 14)),
                value: repeatEnabled,
                onChanged: (v) => setDlg(() => repeatEnabled = v),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (repeatEnabled)
                DropdownButtonFormField<String>(
                  initialValue: recurrence,
                  decoration: const InputDecoration(
                      labelText: 'Frecuencia', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diaria')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  ],
                  onChanged: (v) => setDlg(() => recurrence = v ?? 'daily'),
                ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty || selectedCat == null) {
                        return;
                      }
                      setDlg(() => isSaving = true);
                      try {
                        final data = <String, dynamic>{
                          'text': ctrl.text.trim(),
                          'category': selectedCat,
                          'iconName': _iconNameOf(selectedCat!),
                          'colorName': _colorNameOf(selectedCat!),
                          'done': false,
                          'createdAt': Timestamp.now(),
                          'reminderMinutes': selectedReminder,
                          if (repeatEnabled) 'recurrence': recurrence,
                          if (selectedDate != null)
                            'dueDate': Timestamp.fromDate(selectedDate!),
                        };
                        final ref = await _tasksCollection.add(data);
                        await ReminderDispatcher.scheduleTaskReminder(
                          userDocRef: _userDocRef,
                          taskId: ref.id,
                          taskTitle: ctrl.text.trim(),
                          dueDate: selectedDate,
                          reminderMinutes: selectedReminder,
                        );
                        await ActivityLogService.log(
                          userId: _userDocRef.id,
                          type: ActivityType.taskCreated,
                          description: 'Tarea creada: "${ctrl.text.trim()}"',
                          metadata: {'taskId': ref.id, 'category': selectedCat},
                        );
                        if (dlgCtx.mounted) Navigator.of(dlgCtx).pop();
                      } catch (e) {
                        debugPrint('Error al añadir tarea: $e');
                      } finally {
                        setDlg(() => isSaving = false);
                      }
                    },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskOptionsDialog(
    BuildContext ctx,
    String taskId,
    String text,
    String? category,
    Timestamp? dueDate,
    int? reminderMinutes,
  ) {
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: Text('Opciones:\n"$text"'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.of(dlgCtx).pop();
              _showEditTaskDialog(
                  ctx, taskId, text, category, dueDate, reminderMinutes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final nav = Navigator.of(dlgCtx);
              final msg = ScaffoldMessenger.of(dlgCtx);
              try {
                await _tasksCollection.doc(taskId).update({
                  'deletedByUser': true,
                  'deletedAt': FieldValue.serverTimestamp(),
                });
                await ReminderDispatcher.cancelTaskReminder(
                    userDocRef: _userDocRef, taskId: taskId);
                await ActivityLogService.log(
                  userId: _userDocRef.id,
                  type: ActivityType.taskDeleted,
                  description: 'Tarea eliminada: "$text"',
                  metadata: {'taskId': taskId},
                );
                if (nav.mounted) nav.pop();
                msg.showSnackBar(SnackBar(content: Text('"$text" eliminada')));
              } catch (e) {
                if (nav.mounted) nav.pop();
                msg.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(
    BuildContext ctx,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? currentReminder,
  ) {
    final ctrl = TextEditingController(text: currentText);
    final categories = ['General', 'Estudios', 'Hogar', 'Meds', 'Foco'];
    String? selCat =
        categories.contains(currentCategory) ? currentCategory : 'General';
    DateTime? selDate = currentDueDate?.toDate();
    int? selReminder = currentReminder;

    showDialog(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (statCtx, setDlg) => AlertDialog(
          title: const Text('Editar tarea'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'Nuevo texto'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selCat,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDlg(() => selCat = v),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text(
                    selDate == null
                        ? 'Sin fecha'
                        : 'Entrega: ${_dateFormatter.format(selDate!)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: () async {
                    final p = await pickDateTime(
                        context: statCtx, initialDate: selDate);
                    if (p != null) setDlg(() => selDate = p);
                  },
                ),
                if (selDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setDlg(() => selDate = null),
                  ),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                key: ValueKey(selReminder),
                decoration: const InputDecoration(
                    labelText: 'Recordatorio', border: OutlineInputBorder()),
                initialValue: selReminder,
                items: kReminderOptions
                    .map((o) => DropdownMenuItem<int?>(
                          value: o['minutes'] as int?,
                          child: Text(o['label'] as String),
                        ))
                    .toList(),
                onChanged: (v) => setDlg(() => selReminder = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(dlgCtx);
                if (ctrl.text.trim().isEmpty || selCat == null) {
                  nav.pop();
                  return;
                }
                try {
                  await _tasksCollection.doc(taskId).update({
                    'text': ctrl.text.trim(),
                    'category': selCat,
                    'iconName': _iconNameOf(selCat!),
                    'colorName': _colorNameOf(selCat!),
                    'reminderMinutes': selReminder,
                    'reminderOffsetMinutes': FieldValue.delete(),
                    'dueDate': selDate == null
                        ? FieldValue.delete()
                        : Timestamp.fromDate(selDate!),
                  });
                  await ReminderDispatcher.cancelTaskReminder(
                      userDocRef: _userDocRef, taskId: taskId);
                  await ReminderDispatcher.scheduleTaskReminder(
                    userDocRef: _userDocRef,
                    taskId: taskId,
                    taskTitle: ctrl.text.trim(),
                    dueDate: selDate,
                    reminderMinutes: selReminder,
                  );
                } catch (e) {
                  debugPrint('Error al editar: $e');
                } finally {
                  nav.pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _recurrenceLabel(String r) {
    switch (r) {
      case 'daily': return 'Diaria';
      case 'weekly': return 'Semanal';
      case 'monthly': return 'Mensual';
      default: return r;
    }
  }

  static List<String> _suggestionsFor(String? cat) {
    switch (cat) {
      case 'Estudios':
        return ['Leer capítulo', 'Hacer tarea de matemáticas', 'Estudiar para el examen', 'Repasar apuntes'];
      case 'Hogar':
        return ['Ordenar habitación', 'Lavar los platos', 'Hacer la cama', 'Sacar la basura'];
      case 'Meds':
        return ['Tomar medicamento de la mañana', 'Tomar medicamento de la tarde', 'Tomar medicamento de la noche'];
      case 'Foco':
        return ['Sesión Pomodoro', '10 min de meditación', 'Respiración profunda'];
      case 'General':
        return ['Revisar correo', 'Llamada pendiente', 'Compra semanal'];
      default:
        return [];
    }
  }

  Color _colorOf(String cat) {
    switch (cat) {
      case 'Estudios':
        return Colors.orange;
      case 'Hogar':
        return Colors.green;
      case 'Meds':
        return Colors.red;
      case 'Foco':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _iconOf(String cat) {
    switch (cat) {
      case 'Estudios':
        return Icons.menu_book;
      case 'Hogar':
        return Icons.cottage;
      case 'Meds':
        return Icons.medication;
      case 'Foco':
        return Icons.self_improvement;
      default:
        return Icons.task_alt;
    }
  }

  String _iconNameOf(String cat) {
    switch (cat) {
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

  String _colorNameOf(String cat) {
    switch (cat) {
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

class _CategoryFilter {
  const _CategoryFilter({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String? value;
  final IconData icon;
  final Color color;
}
