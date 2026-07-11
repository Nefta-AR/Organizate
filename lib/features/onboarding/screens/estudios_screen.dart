// ============================================================
// lib/features/onboarding/screens/estudios_screen.dart
// ============================================================
// Pantalla de tareas de la categoría "Estudios" (color naranja).
//
// Idéntica a HogarScreen pero con category='Estudios' y color naranja.
// CRUD: crear, editar, eliminar, completar tareas.
// Al completar: ±10 puntos + StreakService. Hard-delete.
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

class EstudiosScreen extends StatefulWidget {
  const EstudiosScreen({super.key});

  @override
  State<EstudiosScreen> createState() => _EstudiosScreenState();
}

class _EstudiosScreenState extends State<EstudiosScreen> {
  // Subcolección tasks del usuario actual en Firestore
  late final CollectionReference<Map<String, dynamic>> tasksCollection;

  // Documento raíz del usuario (puntos, racha, avatar)
  late final DocumentReference<Map<String, dynamic>> userDocRef;

  // Formateador de fechas en español (ej: "12 Jun, 09:00")
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();

    // Obtenemos el UID del usuario actualmente autenticado
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Apuntamos al documento del usuario en la colección 'users'
    userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // La subcolección 'tasks' almacena todas las tareas del usuario
    // independientemente de la categoría — filtramos en la query
    tasksCollection = userDocRef.collection('tasks');

    // Intentamos el locale español; si el paquete intl no está inicializado,
    // usamos el formato neutral como fallback
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
        title: const Text('Estudios'),
        elevation: 0, // Sin sombra para apariencia limpia
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: true, // Muestra botón "Atrás" si hay ruta previa

        // ── Indicadores en tiempo real: puntos, racha y avatar ────────────
        actions: [
          // StreamBuilder escucha el documento del usuario para actualizar
          // puntos y racha en tiempo real sin necesidad de recargar la pantalla
          StreamBuilder<DocumentSnapshot>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              // Placeholder mientras carga (estrella gris)
              if (!snapshot.hasData || snapshot.hasError) {
                return const Row(children: [
                  Icon(Icons.star, color: Colors.grey),
                  SizedBox(width: 20),
                ]);
              }

              // Cast seguro: el documento puede ser null si el usuario es nuevo
              final userData =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};

              // Conversión segura num→int para evitar errores de tipo
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;

              // Nombre del asset de avatar (ej: 'zorro' → assets/avatars/zorro.png)
              final String? avatarName = userData['avatar'] as String?;

              return Row(
                children: [
                  // ── Puntos (estrella amarilla) ─────────────────────────
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

                  // ── Racha de días consecutivos (fuego naranja) ─────────
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

                  // ── Avatar circular del usuario ────────────────────────
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

      // Botón flotante naranja para añadir nueva tarea de Estudios
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.orange, // Naranja: color temático de Estudios
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // ── Lista de tareas en tiempo real ────────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksCollection
            .where('category', isEqualTo: 'Estudios') // Filtra solo tareas de Estudios
            .orderBy('done')                          // Pendientes primero (false < true)
            .orderBy('createdAt', descending: true)   // Más recientes arriba
            .snapshots(),
        builder: (context, snapshot) {
          // Cargando: spinner centrado
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error de Firestore: log en consola + mensaje al usuario
          if (snapshot.hasError) {
            debugPrint('ERROR ESTUDIOS: ${snapshot.error}');
            return const Center(child: Text('Error al cargar tareas'));
          }

          // Sin tareas: mensaje de estado vacío amigable
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tienes tareas de estudios.\n¡Añade una con el botón +!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Lista de documentos Firestore filtrados por categoría
          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              // Mapeamos el documento a Map para leer campos individuales
              final taskData = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id; // ID generado por Firestore

              final String currentText = taskData['text'] ?? '';

              // dueDate es null si el usuario no asignó fecha de entrega
              final Timestamp? currentDueDate =
                  taskData['dueDate'] as Timestamp?;

              // done = true cuando se ha marcado como completada
              final bool isCurrentlyDone = taskData['done'] ?? false;

              // extractReminderMinutes soporta campo antiguo y nuevo
              // para compatibilidad con documentos creados antes de la migración
              final int? reminderMinutes = extractReminderMinutes(taskData);

              return GestureDetector(
                // Mantener presionado abre menú de opciones (Editar / Eliminar)
                onLongPress: () => _showTaskOptionsDialog(context, taskId,
                    currentText, 'Estudios', currentDueDate, reminderMinutes),
                child: _buildGoalItem(
                  icon: Icons.menu_book, // Icono de libro para Estudios
                  iconColor: Colors.orange,
                  text: currentText,
                  isDone: isCurrentlyDone,
                  dueDate: currentDueDate,

                  // Callback al pulsar "Hecho" o "Deshacer"
                  onDonePressed: () async {
                    // Completar → +10 puntos; Deshacer → -10 puntos
                    final pointsChange = isCurrentlyDone ? -10 : 10;

                    // Batch atómico: ambas operaciones (tarea + puntos) se
                    // confirman juntas o ninguna, evitando inconsistencias
                    final batch = FirebaseFirestore.instance.batch();
                    batch.update(tasksCollection.doc(taskId), {
                      'done': !isCurrentlyDone,
                      'completedAt': isCurrentlyDone
                          ? FieldValue.delete()
                          : FieldValue.serverTimestamp(),
                    }); // Invierte el estado
                    batch.update(userDocRef,
                        {'points': FieldValue.increment(pointsChange)});

                    try {
                      await batch.commit();

                      // Solo al completar (no al deshacer):
                      // cancelamos el recordatorio y actualizamos la racha
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

  // ── Diálogo para crear una nueva tarea de Estudios ───────────────────────

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    const String fixedCategory = 'Estudios'; // Categoría fija para esta pantalla

    // Lee el offset de recordatorio por defecto configurado en SettingsScreen
    final int? defaultReminder = await fetchDefaultReminderMinutes(userDocRef);
    int? selectedReminderMinutes = defaultReminder;

    // Verificamos que el widget siga montado después del await
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite setState interno al diálogo
        // (picker de fecha actualiza el texto sin reconstruir la pantalla)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Tarea de Estudios'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
                  children: [
                    // Campo de texto: descripción de la tarea
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Descripción'),
                      autofocus: true, // Abre el teclado automáticamente
                    ),
                    const SizedBox(height: 20),

                    // ── Selector de fecha de entrega ───────────────────────
                    Row(
                      children: [
                        Expanded(
                          // Muestra la fecha seleccionada o "Sin fecha de entrega"
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha de entrega'
                                : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        // Icono naranja (color temático de Estudios)
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.orange),
                          onPressed: () async {
                            // pickDateTime: muestra DatePicker luego TimePicker
                            final picked = await pickDateTime(
                                context: context, initialDate: selectedDueDate);
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                        // Botón "X" solo visible si hay fecha seleccionada
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
                    // kReminderOptions define las opciones disponibles (10min, 30min, 1h…)
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
                // Descarta el diálogo sin crear nada
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),

                // Guarda la tarea en Firestore y programa la notificación
                TextButton(
                  onPressed: () async {
                    // No crear tareas con descripción vacía
                    if (taskController.text.isEmpty) return;

                    // Construimos el documento con todos los campos necesarios
                    final data = <String, dynamic>{
                      'text': taskController.text,
                      'category': fixedCategory,
                      // iconName y colorName son usados por TareasScreen
                      // para mostrar el icono y color en la lista general
                      'iconName': _getIconNameFromCategory(fixedCategory),
                      'colorName': _getColorNameFromCategory(fixedCategory),
                      'done': false,               // Tarea nueva siempre pendiente
                      'createdAt': Timestamp.now(), // Para ordenación descendente
                      'reminderMinutes': selectedReminderMinutes,
                      // dueDate solo se incluye si fue seleccionada
                      if (selectedDueDate != null)
                        'dueDate': Timestamp.fromDate(selectedDueDate!),
                    };

                    // add() retorna la referencia con el ID generado automáticamente
                    final docRef = await tasksCollection.add(data);

                    // Programamos la notificación local + remota con el ID real del doc
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

  // ── Tarjeta visual de una tarea individual ───────────────────────────────

  Widget _buildGoalItem({
    required IconData icon,
    required Color iconColor,
    required String text,      // Texto de la tarea
    required bool isDone,      // true si ya fue completada
    required VoidCallback onDonePressed,
    Timestamp? dueDate,        // Fecha de entrega (opcional)
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icono de categoría (libro para Estudios)
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),

          // Texto de la tarea + fecha de entrega (si existe)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    // Tarea completada: gris con tachado; pendiente: negro normal
                    color: isDone ? Colors.grey : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                // Fecha de entrega: solo se renderiza si existe
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

          // Botón de estado: "Hecho" (azul suave) o "Deshacer" (gris)
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25),
              foregroundColor:
                  isDone ? Colors.grey.shade600 : Colors.blue.shade800,
              elevation: 0, // Apariencia plana sin sombra
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isDone ? 'Deshacer' : 'Hecho'),
          ),
        ],
      ),
    );
  }

  // ── Diálogo de opciones (long-press sobre una tarea) ─────────────────────

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
              // Opción Editar: cierra este diálogo y abre el de edición
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Cierra opciones primero
                  _showEditTaskDialog(context, taskId, currentText,
                      currentCategory, currentDueDate, reminderMinutes);
                },
              ),

              // Opción Eliminar: hard-delete del documento Firestore
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () async {
                  // Capturamos referencias antes del await para evitar
                  // usar BuildContext tras desmontaje del widget
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    // Eliminación directa (sin soft-delete)
                    await tasksCollection.doc(taskId).delete();

                    // Cancelamos notificación local + remota (no crítico si falla)
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

  // ── Diálogo para editar una tarea existente ───────────────────────────────

  void _showEditTaskDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? currentReminderMinutes,
  ) {
    // Precargamos el texto actual para que el usuario lo edite sobre él
    final TextEditingController taskController =
        TextEditingController(text: currentText);

    // Categorías disponibles para reasignar la tarea si el usuario lo desea
    final List<String> categories = [
      'General', 'Estudios', 'Hogar', 'Meds', 'Foco'
    ];

    // Defaulteamos a 'Estudios' si la categoría actual no está en la lista
    String? selectedCategory =
        categories.contains(currentCategory) ? currentCategory : 'Estudios';

    // Convertimos Timestamp → DateTime para el DatePicker
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
                    // Campo de texto con el texto actual precargado
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Nuevo texto'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),

                    // Dropdown para cambiar la categoría de la tarea
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

                    // Selector de fecha de entrega (editable)
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

                    // Dropdown de recordatorio (precargado con valor actual)
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
                      // Elimina el campo legacy para evitar ambigüedad
                      'reminderOffsetMinutes': FieldValue.delete(),
                      // Si no hay fecha: elimina el campo; si hay: lo actualiza
                      'dueDate': selectedDueDate == null
                          ? FieldValue.delete()
                          : Timestamp.fromDate(selectedDueDate!),
                    };

                    try {
                      await tasksCollection.doc(taskId).update(updatedData);

                      // Siempre cancelamos antes de reprogramar
                      // para no dejar notificaciones duplicadas
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
                      navigator.pop(); // Siempre cerramos el diálogo
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

  // ── Helpers de mapeo categoría → icono / color ────────────────────────────

  // Devuelve el nombre de icono Material guardado en Firestore.
  // TareasScreen lo usa para reconstruir el IconData en la lista general.
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
        return 'task_alt'; // Icono genérico para 'General'
    }
  }

  // Devuelve el nombre del color temático guardado en Firestore.
  // TareasScreen lo interpreta para pintar la tarjeta con el color correcto.
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
