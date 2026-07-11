// ============================================================
// lib/features/onboarding/screens/meds_screen.dart
// ============================================================
// Pantalla de tareas de la categoría "Meds" (medicamentos, color rojo).
//
// Idéntica a HogarScreen pero con category='Meds' y color rojo.
// Especialmente importante para usuarios con rutinas de medicación.
// CRUD: crear, editar, eliminar, completar. Hard-delete.
// Recordatorios via ReminderDispatcher (local + push).
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:simple/core/services/reminder_dispatcher.dart';
import 'package:simple/features/tda_focus/services/streak_service.dart';
import 'package:simple/core/utils/date_time_helper.dart';
import 'package:simple/core/utils/reminder_helper.dart';
import 'package:simple/core/utils/reminder_options.dart';

class MedsScreen extends StatefulWidget {
  const MedsScreen({super.key});

  @override
  State<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends State<MedsScreen> {
  // Subcolección 'tasks' del usuario actual en Firestore
  late final CollectionReference<Map<String, dynamic>> tasksCollection;

  // Documento raíz del usuario (puntos, racha, avatar)
  late final DocumentReference<Map<String, dynamic>> userDocRef;

  // Formateador de fechas en español (ej: "12 Jun, 09:00")
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();

    // UID del usuario autenticado actualmente en Firebase Auth
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Referencia al documento del usuario dentro de la colección 'users'
    userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // La subcolección 'tasks' contiene todas las tareas del usuario;
    // filtramos por categoría='Meds' en la query del StreamBuilder
    tasksCollection = userDocRef.collection('tasks');

    // Intentamos el locale español para el formateador de fechas.
    // Si el paquete intl no tiene el locale cargado, usamos formato neutral
    try {
      _dateFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');
    } catch (_) {
      _dateFormatter = DateFormat('dd MMM, HH:mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        elevation: 0,               // Sin sombra debajo del AppBar
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: true, // Muestra "Atrás" si hay ruta previa

        // ── Indicadores en tiempo real de puntos, racha y avatar ──────────
        actions: [
          // StreamBuilder escucha el documento del usuario para mostrar
          // puntos y racha actualizados sin necesidad de recargar la pantalla
          StreamBuilder<DocumentSnapshot>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              // Placeholder mientras llegan los datos (estrella gris)
              if (!snapshot.hasData || snapshot.hasError) {
                return const Row(children: [
                  Icon(Icons.star, color: Colors.grey),
                  SizedBox(width: 20),
                ]);
              }

              // Cast seguro al Map del documento; {} como fallback si es null
              final userData =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};

              // Conversión num→int para evitar errores de tipo en tiempo de ejecución
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;

              // Nombre del avatar: construye ruta 'assets/avatars/{nombre}.png'
              final String? avatarName = userData['avatar'] as String?;

              return Row(
                children: [
                  // ── Puntos: estrella amarilla + número ────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('$points',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                    ]),
                  ),

                  // ── Racha: fuego naranja + número de días ─────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.deepOrange, size: 20),
                      const SizedBox(width: 4),
                      Text('$streak',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                    ]),
                  ),

                  // ── Avatar circular ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: avatarName != null
                        ? CircleAvatar(
                            radius: 15,
                            backgroundImage:
                                AssetImage('assets/avatars/$avatarName.png'),
                            // Silencia el error si el asset no existe
                            onBackgroundImageError: (_, __) {},
                          )
                        : const CircleAvatar(
                            radius: 15, backgroundColor: Colors.grey),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      // Botón flotante rojo (color temático de Meds/Medicamentos)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.red, // Rojo: alerta visual para medicamentos
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // ── Lista en tiempo real de recordatorios de medicación ───────────
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksCollection
            .where('category', isEqualTo: 'Meds') // Filtra solo tareas de Meds
            .orderBy('done')                       // Pendientes primero
            .orderBy('createdAt', descending: true) // Más recientes arriba
            .snapshots(),
        builder: (context, snapshot) {
          // Spinner mientras Firestore procesa la primera respuesta
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error: mostramos en consola (para debugging) y al usuario
          if (snapshot.hasError) {
            debugPrint('ERROR MEDS: ${snapshot.error}');
            return const Center(child: Text('Error al cargar tareas'));
          }

          // Sin documentos: pantalla vacía amigable con instrucción
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tienes recordatorios de medicamentos.\n¡Añade uno con el botón +!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              // Casteamos el documento a Map para leer sus campos
              final taskData = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id; // ID único generado por Firestore

              final String currentText = taskData['text'] ?? '';
              final Timestamp? currentDueDate = taskData['dueDate'] as Timestamp?;
              final bool isCurrentlyDone = taskData['done'] ?? false;

              // extractReminderMinutes: lee 'reminderMinutes' (nuevo) o
              // 'reminderOffsetMinutes' (campo legacy) con soporte dual
              final int? reminderMinutes = extractReminderMinutes(taskData);

              return GestureDetector(
                // Long-press: abre el menú de opciones (Editar / Eliminar)
                onLongPress: () => _showTaskOptionsDialog(context, taskId,
                    currentText, 'Meds', currentDueDate, reminderMinutes),
                child: _buildGoalItem(
                  icon: Icons.medication, // Icono de píldora para medicamentos
                  iconColor: Colors.red,
                  text: currentText,
                  isDone: isCurrentlyDone,
                  dueDate: currentDueDate,

                  // Callback para marcar como hecho o deshacer
                  onDonePressed: () async {
                    // Completar suma puntos; deshacer los resta
                    final pointsChange = isCurrentlyDone ? -10 : 10;

                    // Batch atómico: actualiza tarea y puntos en una sola operación
                    // (ambas escrituras se confirman juntas o ninguna)
                    final batch = FirebaseFirestore.instance.batch();
                    batch.update(tasksCollection.doc(taskId), {
                      'done': !isCurrentlyDone,
                      'completedAt': isCurrentlyDone
                          ? FieldValue.delete()
                          : FieldValue.serverTimestamp(),
                    });
                    batch.update(userDocRef,
                        {'points': FieldValue.increment(pointsChange)});

                    try {
                      await batch.commit();

                      // Al completar: cancela el recordatorio y actualiza la racha
                      // Al deshacer: no se cancela (la tarea vuelve a estar pendiente)
                      if (!isCurrentlyDone) {
                        await ReminderDispatcher.cancelTaskReminder(
                            userDocRef: userDocRef, taskId: taskId);
                        await StreakService.updateStreakOnTaskCompletion(
                            userDocRef);
                      }
                    } catch (error) {
                      debugPrint('Error al actualizar: $error');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Diálogo para crear un nuevo recordatorio de medicamento ──────────────

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    const String fixedCategory = 'Meds'; // Categoría fija para esta pantalla

    // Lee el offset de recordatorio por defecto desde la configuración del usuario
    final int? defaultReminder = await fetchDefaultReminderMinutes(userDocRef);
    int? selectedReminderMinutes = defaultReminder;

    // Verificamos que el context siga montado después del await asíncrono
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite setState local al diálogo para actualizar
        // el texto de fecha sin reconstruir la pantalla completa
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Recordatorio de Medicamento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de descripción del medicamento o dosis
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Descripción'),
                      autofocus: true, // Teclado aparece inmediatamente
                    ),
                    const SizedBox(height: 20),

                    // ── Selector de fecha/hora del recordatorio ────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha de entrega'
                                : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        // Icono rojo (color temático de Meds)
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.red),
                          onPressed: () async {
                            // pickDateTime encadena DatePicker + TimePicker
                            final picked = await pickDateTime(
                                context: context, initialDate: selectedDueDate);
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                        // Botón para limpiar la fecha (solo visible si hay fecha)
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: Colors.grey),
                            tooltip: 'Quitar fecha',
                            onPressed: () =>
                                setDialogState(() => selectedDueDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selector de anticipación del recordatorio
                    // (cuántos minutos antes de la hora programada avisar)
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
                // Cancela sin guardar
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),

                // Añade el recordatorio y programa la notificación
                TextButton(
                  onPressed: () async {
                    if (taskController.text.isEmpty) return;

                    final data = <String, dynamic>{
                      'text': taskController.text,
                      'category': fixedCategory,
                      // iconName y colorName para TareasScreen (lista general)
                      'iconName': _getIconNameFromCategory(fixedCategory),
                      'colorName': _getColorNameFromCategory(fixedCategory),
                      'done': false,
                      'createdAt': Timestamp.now(),
                      'reminderMinutes': selectedReminderMinutes,
                      if (selectedDueDate != null)
                        'dueDate': Timestamp.fromDate(selectedDueDate!),
                    };

                    // add() crea el documento y retorna la referencia con el ID generado
                    final docRef = await tasksCollection.add(data);

                    // Programamos notificación local + remota
                    await ReminderDispatcher.scheduleTaskReminder(
                      userDocRef: userDocRef,
                      taskId: docRef.id,
                      taskTitle: taskController.text,
                      dueDate: selectedDueDate,
                      reminderMinutes: selectedReminderMinutes,
                    );

                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Tarjeta visual de un recordatorio de medicamento ─────────────────────

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
          // Icono de píldora (representativo de medicamentos)
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),

          // Texto del recordatorio + fecha/hora si existe
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    // Completado: gris con tachado; pendiente: negro legible
                    color: isDone ? Colors.grey : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                // Fecha/hora del recordatorio (solo si fue asignada)
                if (dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Entrega: ${_dateFormatter.format(dueDate.toDate())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),

          // "Hecho" en azul suave o "Deshacer" en gris
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25),
              foregroundColor:
                  isDone ? Colors.grey.shade600 : Colors.blue.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isDone ? 'Deshacer' : 'Hecho'),
          ),
        ],
      ),
    );
  }

  // ── Diálogo de opciones (long-press) ──────────────────────────────────────

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
              // Editar: cierra este diálogo y abre el de edición
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showEditTaskDialog(context, taskId, currentText,
                      currentCategory, currentDueDate, reminderMinutes);
                },
              ),

              // Eliminar: hard-delete + cancelación del recordatorio
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await tasksCollection.doc(taskId).delete();
                    try {
                      await ReminderDispatcher.cancelTaskReminder(
                          userDocRef: userDocRef, taskId: taskId);
                    } catch (e) {
                      debugPrint('Error al cancelar notificación $taskId: $e');
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

  // ── Diálogo para editar un recordatorio existente ─────────────────────────

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

    final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds', 'Foco'];

    // Si la categoría no está en la lista (dato corrupto), defaulteamos a 'Meds'
    String? selectedCategory =
        categories.contains(currentCategory) ? currentCategory : 'Meds';

    DateTime? selectedDueDate = currentDueDate?.toDate();
    int? selectedReminderMinutes = currentReminderMinutes;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de texto precargado con el contenido actual
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Nuevo texto'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),

                    // Dropdown de categorías para reasignar la tarea
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 20),

                    // Selector de fecha de entrega editable
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha'
                                : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
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

                    // Selector de recordatorio
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
                    final navigator = Navigator.of(dialogContext);
                    if (taskController.text.isEmpty || selectedCategory == null) {
                      navigator.pop();
                      return;
                    }

                    final updatedData = <String, dynamic>{
                      'text': taskController.text,
                      'category': selectedCategory,
                      'iconName': _getIconNameFromCategory(selectedCategory!),
                      'colorName': _getColorNameFromCategory(selectedCategory!),
                      'reminderMinutes': selectedReminderMinutes,
                      // Elimina el campo legacy para evitar confusión futura
                      'reminderOffsetMinutes': FieldValue.delete(),
                      'dueDate': selectedDueDate == null
                          ? FieldValue.delete()
                          : Timestamp.fromDate(selectedDueDate!),
                    };

                    try {
                      await tasksCollection.doc(taskId).update(updatedData);

                      // Cancela el recordatorio anterior y programa el nuevo
                      await ReminderDispatcher.cancelTaskReminder(
                          userDocRef: userDocRef, taskId: taskId);
                      await ReminderDispatcher.scheduleTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                        taskTitle: taskController.text,
                        dueDate: selectedDueDate,
                        reminderMinutes: selectedReminderMinutes,
                      );
                    } catch (error) {
                      debugPrint('Error: $error');
                    } finally {
                      navigator.pop();
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

  // ── Helpers de mapeo categoría → icono y color ────────────────────────────

  // Nombre del icono Material para almacenar en Firestore.
  // TareasScreen usa este string para reconstruir el IconData en la lista general.
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

  // Nombre del color temático para almacenar en Firestore.
  // TareasScreen lo interpreta para aplicar el color correcto a la tarjeta.
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
