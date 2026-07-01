// ============================================================
// lib/features/onboarding/screens/hogar_screen.dart
// ============================================================
// Pantalla de tareas de la categoría "Hogar" (color verde).
//
// Funcionalmente idéntica a TareasScreen pero filtrada a category='Hogar'.
// Diferencias respecto a TareasScreen:
//   - Usa hard-delete (no soft-delete con deletedByUser: true).
//   - Sin IA / SuperExpertoSheet.
//   - Color temático: verde.
//
// CRUD completo: crear, editar, eliminar, marcar completada.
// Al completar una tarea: ±10 puntos en batch + StreakService.
// Recordatorios: ReminderDispatcher (local + push).
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

class HogarScreen extends StatefulWidget {
  const HogarScreen({super.key});

  @override
  State<HogarScreen> createState() => _HogarScreenState();
}

class _HogarScreenState extends State<HogarScreen> {
  // Referencia a la subcolección tasks del usuario actual
  late final CollectionReference<Map<String, dynamic>> tasksCollection;

  // Referencia al documento raíz del usuario (para puntos y racha)
  late final DocumentReference<Map<String, dynamic>> userDocRef;

  // Formateador de fechas localizado al español (ej: "12 Jun, 09:00")
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();

    // Obtenemos el UID del usuario actual de Firebase Auth
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Apuntamos al documento del usuario en Firestore
    userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // La subcolección 'tasks' contiene todas las tareas del usuario,
    // independientemente de la categoría — filtramos en la query
    tasksCollection = userDocRef.collection('tasks');

    // Intentamos formatear con locale español; si falla (locale no cargado),
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
        title: const Text('Hogar'),
        elevation: 0, // Sin sombra debajo del AppBar
        backgroundColor: Colors.transparent, // AppBar transparente
        foregroundColor: Colors.black,
        automaticallyImplyLeading: true, // Muestra flecha "atrás" si hay ruta previa

        // ── Indicadores en tiempo real de puntos, racha y avatar ──────────────
        actions: [
          // StreamBuilder escucha cambios en el documento del usuario
          // para reflejar puntos y racha al instante sin recargar
          StreamBuilder<DocumentSnapshot>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              // Mientras carga, mostramos un estrella gris como placeholder
              if (!snapshot.hasData || snapshot.hasError) {
                return const Row(children: [
                  Icon(Icons.star, color: Colors.grey),
                  SizedBox(width: 20),
                ]);
              }

              // Extraemos los datos del documento con cast seguro a Map
              final userData =
                  snapshot.data!.data() as Map<String, dynamic>? ?? {};

              // Leemos puntos y racha con conversión segura (num→int)
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;

              // Nombre del avatar (ej: 'zorro') para construir el asset path
              final String? avatarName = userData['avatar'] as String?;

              return Row(
                children: [
                  // ── Puntos (estrella amarilla + número) ───────────────────
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

                  // ── Racha (fuego naranja + número de días) ────────────────
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

                  // ── Avatar circular del usuario ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: avatarName != null
                        ? CircleAvatar(
                            radius: 15,
                            backgroundImage:
                                AssetImage('assets/avatars/$avatarName.png'),
                            // onBackgroundImageError: ignora si el asset no existe
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

      // ── Botón flotante para añadir nueva tarea ────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.green, // Verde: color temático de Hogar
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // ── Lista de tareas en tiempo real via StreamBuilder ──────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksCollection
            .where('category', isEqualTo: 'Hogar') // Filtra solo tareas de Hogar
            .orderBy('done')                       // Pendientes primero (false < true)
            .orderBy('createdAt', descending: true) // Más recientes arriba
            .snapshots(),
        builder: (context, snapshot) {
          // Estado de espera: mostramos spinner central
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error de Firestore: se imprime en consola y muestra mensaje al usuario
          if (snapshot.hasError) {
            debugPrint('ERROR HOGAR: ${snapshot.error}');
            return const Center(child: Text('Error al cargar tareas'));
          }

          // Sin datos o colección vacía: estado vacío amigable
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tienes tareas de hogar.\n¡Añade una con el botón +!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Lista de documentos Firestore de esta categoría
          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              // Mapeamos el documento a un Map para leer campos
              final taskData = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id; // ID Firestore del documento

              final String currentText = taskData['text'] ?? '';

              // dueDate puede ser null si el usuario no asignó fecha
              final Timestamp? currentDueDate =
                  taskData['dueDate'] as Timestamp?;

              // done = true cuando la tarea fue marcada como completada
              final bool isCurrentlyDone = taskData['done'] ?? false;

              // extractReminderMinutes soporta campo antiguo (reminderOffsetMinutes)
              // y el nuevo (reminderMinutes) para compatibilidad
              final int? reminderMinutes = extractReminderMinutes(taskData);

              return GestureDetector(
                // Mantener presionado abre el diálogo de opciones (editar/eliminar)
                onLongPress: () => _showTaskOptionsDialog(context, taskId,
                    currentText, 'Hogar', currentDueDate, reminderMinutes),
                child: _buildGoalItem(
                  icon: Icons.cleaning_services, // Icono temático de hogar
                  iconColor: Colors.green,
                  text: currentText,
                  isDone: isCurrentlyDone,
                  dueDate: currentDueDate,

                  // Callback al pulsar "Hecho" / "Deshacer"
                  onDonePressed: () async {
                    // Si ya estaba hecha: -10 puntos. Si se completa: +10 puntos
                    final pointsChange = isCurrentlyDone ? -10 : 10;

                    // Usamos batch atómico: ambas escrituras se confirman juntas
                    // o ninguna, evitando inconsistencias en puntos vs estado de tarea
                    final batch = FirebaseFirestore.instance.batch();

                    // Invierte el estado done de la tarea
                    batch.update(tasksCollection.doc(taskId),
                        {'done': !isCurrentlyDone});

                    // Incrementa (o decrementa) los puntos del usuario
                    batch.update(userDocRef,
                        {'points': FieldValue.increment(pointsChange)});

                    try {
                      await batch.commit();

                      // Solo al completar (no al deshacer): cancela el recordatorio
                      // y actualiza la racha de días consecutivos
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

  // ── Diálogo para crear una nueva tarea de Hogar ──────────────────────────

  Future<void> _showAddTaskDialog(BuildContext context) async {
    // Controlador del campo de texto de la tarea
    final TextEditingController taskController = TextEditingController();

    DateTime? selectedDueDate; // Fecha de entrega elegida por el usuario (opcional)
    const String fixedCategory = 'Hogar'; // Categoría fija para esta pantalla

    // Leemos el offset por defecto desde Firestore (configurado en SettingsScreen)
    final int? defaultReminder = await fetchDefaultReminderMinutes(userDocRef);
    int? selectedReminderMinutes = defaultReminder;

    // Verificamos que el context siga montado tras el await anterior
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite actualizar el estado del diálogo internamente
        // sin necesidad de convertir el widget padre a StatefulWidget
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Tarea de Hogar'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // El diálogo solo ocupa lo necesario
                  children: [
                    // Campo de texto: descripción de la tarea
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Descripción'),
                      autofocus: true, // El teclado aparece automáticamente
                    ),
                    const SizedBox(height: 20),

                    // ── Selector de fecha de entrega ───────────────────────
                    Row(
                      children: [
                        Expanded(
                          // Muestra la fecha elegida o "Sin fecha" si aún no hay
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha de entrega'
                                : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),

                        // Botón calendario: abre el selector de fecha+hora
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.green),
                          onPressed: () async {
                            // pickDateTime: DatePicker → TimePicker en cadena
                            // con validación de fecha pasada incorporada
                            final picked = await pickDateTime(
                                context: context, initialDate: selectedDueDate);
                            if (picked != null) {
                              // setDialogState actualiza solo el diálogo, no la pantalla
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),

                        // Botón de limpiar fecha: solo aparece si hay fecha seleccionada
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

                    // ── Selector de anticipación del recordatorio ──────────
                    // kReminderOptions: lista de opciones (ej: 10 min, 30 min, 1 h…)
                    // ValueKey fuerza reconstrucción del dropdown si cambia el valor
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
                // Cancela sin guardar nada
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),

                // Guarda la tarea y programa el recordatorio
                TextButton(
                  onPressed: () async {
                    // Validación: no añadir tareas vacías
                    if (taskController.text.isEmpty) return;

                    // Construimos el documento Firestore con todos los campos
                    final data = <String, dynamic>{
                      'text': taskController.text,
                      'category': fixedCategory,

                      // iconName y colorName se usan en TareasScreen para
                      // mostrar el icono y color correcto en la lista general
                      'iconName': _getIconNameFromCategory(fixedCategory),
                      'colorName': _getColorNameFromCategory(fixedCategory),

                      'done': false,               // Nueva tarea siempre pendiente
                      'createdAt': Timestamp.now(), // Para ordenar más recientes primero

                      'reminderMinutes': selectedReminderMinutes,

                      // dueDate solo se incluye en el Map si fue seleccionada
                      if (selectedDueDate != null)
                        'dueDate': Timestamp.fromDate(selectedDueDate!),
                    };

                    // add() crea el documento y devuelve su referencia con el ID generado
                    final docRef = await tasksCollection.add(data);

                    // Programamos la notificación local + remota con el ID real
                    await ReminderDispatcher.scheduleTaskReminder(
                      userDocRef: userDocRef,
                      taskId: docRef.id,
                      taskTitle: taskController.text,
                      dueDate: selectedDueDate,
                      reminderMinutes: selectedReminderMinutes,
                    );

                    // Cerramos el diálogo solo si el widget sigue montado
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
    required String text,      // Descripción de la tarea
    required bool isDone,      // Estado actual (completada o pendiente)
    required VoidCallback onDonePressed, // Acción al pulsar el botón
    Timestamp? dueDate,        // Fecha de entrega (puede ser null)
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8), // Separación entre tarjetas
      child: Row(
        children: [
          // Icono de categoría (ej: escoba para Hogar)
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),

          // Columna central: texto de la tarea + fecha de entrega
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,

                    // Tarea completada: texto gris con tachado
                    color: isDone ? Colors.grey : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),

                // La fecha solo aparece si el usuario asignó una
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

          // Botón de acción: "Hecho" (azul suave) o "Deshacer" (gris)
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25),
              foregroundColor:
                  isDone ? Colors.grey.shade600 : Colors.blue.shade800,
              elevation: 0, // Sin sombra para apariencia plana
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isDone ? 'Deshacer' : 'Hecho'),
          ),
        ],
      ),
    );
  }

  // ── Diálogo de opciones al mantener presionada una tarea ─────────────────

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
          title: Text('Opciones:\n"$currentText"'), // Muestra el texto de la tarea
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opción Editar: abre _showEditTaskDialog con datos actuales
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Cierra este diálogo primero
                  _showEditTaskDialog(context, taskId, currentText,
                      currentCategory, currentDueDate, reminderMinutes);
                },
              ),

              // Opción Eliminar: hard-delete (sin soft-delete como en TareasScreen)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () async {
                  // Capturamos navigator y messenger antes del await
                  // para evitar usar context tras desmontaje del widget
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    // Eliminación directa del documento en Firestore
                    await tasksCollection.doc(taskId).delete();

                    // Cancelamos la notificación local y remota asociada
                    try {
                      await ReminderDispatcher.cancelTaskReminder(
                          userDocRef: userDocRef, taskId: taskId);
                    } catch (e) {
                      // Error no crítico: la notificación puede ya no existir
                      debugPrint('Error al cancelar notificación $taskId: $e');
                    }

                    // Cerramos el diálogo y confirmamos con Snackbar
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
    // Precargamos el texto actual en el controlador
    final TextEditingController taskController =
        TextEditingController(text: currentText);

    // Lista de categorías disponibles para reasignar la tarea
    final List<String> categories = [
      'General',
      'Estudios',
      'Hogar',
      'Meds',
      'Foco'
    ];

    // Si la categoría actual es válida la usamos; si no, defaulteamos a 'Hogar'
    String? selectedCategory =
        categories.contains(currentCategory) ? currentCategory : 'Hogar';

    // Convertimos el Timestamp de Firestore a DateTime para el picker
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
                    // Campo de texto: nuevo nombre de la tarea
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Nuevo texto'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),

                    // Selector de categoría: permite mover la tarea a otra sección
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

                    // ── Selector de fecha de entrega ───────────────────────
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

                    // Selector de recordatorio (igual que en el diálogo de creación)
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

                    // Validación: texto no vacío y categoría seleccionada
                    if (taskController.text.isEmpty ||
                        selectedCategory == null) {
                      navigator.pop();
                      return;
                    }

                    // Mapa de campos a actualizar en Firestore
                    final updatedData = <String, dynamic>{
                      'text': taskController.text,
                      'category': selectedCategory,
                      'iconName': _getIconNameFromCategory(selectedCategory!),
                      'colorName': _getColorNameFromCategory(selectedCategory!),
                      'reminderMinutes': selectedReminderMinutes,

                      // FieldValue.delete() elimina el campo antiguo 'reminderOffsetMinutes'
                      // (campo legacy) para no confundir a extractReminderMinutes()
                      'reminderOffsetMinutes': FieldValue.delete(),

                      // Si no hay fecha: elimina el campo. Si hay: lo actualiza.
                      'dueDate': selectedDueDate == null
                          ? FieldValue.delete()
                          : Timestamp.fromDate(selectedDueDate!),
                    };

                    try {
                      // Actualizamos el documento existente en Firestore
                      await tasksCollection.doc(taskId).update(updatedData);

                      // Cancelamos el recordatorio anterior antes de reprogramar
                      await ReminderDispatcher.cancelTaskReminder(
                          userDocRef: userDocRef, taskId: taskId);

                      // Programamos el nuevo recordatorio con los datos actualizados
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
                      // Cerramos el diálogo siempre, incluso si hubo error
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

  // ── Helpers de mapeo categoría → icono / color ────────────────────────────

  // Devuelve el nombre del icono Material correspondiente a la categoría.
  // Este string se guarda en Firestore y TareasScreen lo usa para
  // reconstruir el IconData en la lista general.
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

  // Devuelve el nombre del color temático de cada categoría.
  // Se guarda en Firestore y se usa para pintar la tarjeta en TareasScreen.
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
