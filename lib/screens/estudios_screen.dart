import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:organizate/services/reminder_dispatcher.dart';
import 'package:organizate/services/streak_service.dart';
import 'package:organizate/utils/date_time_helper.dart';
import 'package:organizate/utils/reminder_helper.dart';
import 'package:organizate/utils/reminder_options.dart';
import 'package:organizate/widgets/custom_nav_bar.dart';

// --- Convertido a StatefulWidget (para manejar la lógica) ---
class EstudiosScreen extends StatefulWidget {
  const EstudiosScreen({super.key});

  @override
  State<EstudiosScreen> createState() => _EstudiosScreenState();
}

class _EstudiosScreenState extends State<EstudiosScreen> {
  // --- Referencias a Firestore (igual que en HomeScreen) ---
  final CollectionReference<Map<String, dynamic>> tasksCollection =
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tasks');
  final DocumentReference<Map<String, dynamic>> userDocRef =
      FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
  
  // --- Formateador de Fecha (igual que en HomeScreen) ---
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();
    try {
      _dateFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');
    } catch (e) {
      _dateFormatter = DateFormat('dd MMM, HH:mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    const int screenIndex = 1; // Índice 1 para "Estudios" en la barra

    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: screenIndex), // Pasa el índice
      appBar: AppBar(
        title: const Text('Estudios'), // Título de la pantalla
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // Quita la flecha de "atrás"
        actions: [ // Muestra Puntos/Racha/Avatar (igual que en HomeScreen)
          StreamBuilder<DocumentSnapshot>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.hasError) { return const Row(children: [Icon(Icons.star, color: Colors.grey), SizedBox(width: 20)]); }
              final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;
              final String? avatarName = userData['avatar'] as String?;
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
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
                  if (avatarName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage: AssetImage('assets/avatars/$avatarName.png'),
                        onBackgroundImageError: (e, s) {},
                      ),
                    ),
                  if (avatarName == null)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(radius: 15, backgroundColor: Colors.grey),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context), // Llama al diálogo de ESTA pantalla
        backgroundColor: Colors.orange, // Color Naranja de Estudios
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // --- Cuerpo con StreamBuilder FILTRADO ---
      body: StreamBuilder<QuerySnapshot>(
        // 1. Filtra por categoría 'Estudios'
        // 2. Ordena por 'done' (para mostrar pendientes primero)
        // 3. Luego ordena por fecha de creación
        stream: tasksCollection
            .where('category', isEqualTo: 'Estudios')
            .orderBy('done') // Pendientes (false) primero
            .orderBy('createdAt', descending: true) // Luego las más nuevas
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
          if (snapshot.hasError) { 
            debugPrint('¡¡¡ERROR EN FIREBASE (ESTUDIOS): ${snapshot.error}!!!');
            return const Center(child: Text('Error al cargar tareas')); 
          }
          // Mensaje específico si no hay tareas de ESTUDIOS
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { 
            return const Center(child: Padding( 
              padding: EdgeInsets.all(32.0), 
              child: Text('No tienes tareas de estudios.\n¡Añade una con el botón +!', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            )); 
          }

          final tasks = snapshot.data!.docs;
          // Usamos ListView.builder para mostrar la lista
          return ListView.builder(
            padding: const EdgeInsets.all(20.0), // Padding para la lista
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskData = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id;
              final String currentText = taskData['text'] ?? '';
              final Timestamp? currentDueDate = taskData['dueDate'] as Timestamp?;
              final bool isCurrentlyDone = taskData['done'] ?? false;
              final int? reminderMinutes = extractReminderMinutes(taskData);

              // Reutiliza los mismos widgets de `HomeScreen`
              return GestureDetector(
                onLongPress: () => _showTaskOptionsDialog(
                    context, taskId, currentText, 'Estudios', currentDueDate, reminderMinutes),
                child: _buildGoalItem(
                  icon: Icons.menu_book, // Ícono fijo de Estudios
                  iconColor: Colors.orange, // Color fijo de Estudios
                  text: currentText,
                  isDone: isCurrentlyDone,
                  dueDate: currentDueDate,
                  onDonePressed: () async {
                      // Misma lógica centralizada: batch para puntos + racha.
                      final pointsChange = isCurrentlyDone ? -10 : 10;
                      final batch = FirebaseFirestore.instance.batch();
                      batch.update(tasksCollection.doc(taskId), {'done': !isCurrentlyDone});
                      batch.update(userDocRef, {'points': FieldValue.increment(pointsChange)});
                      try {
                        await batch.commit();
                        if (!isCurrentlyDone) {
                          await ReminderDispatcher.cancelTaskReminder(
                            userDocRef: userDocRef,
                            taskId: taskId,
                          );
                          await StreakService.updateStreakOnTaskCompletion(userDocRef);
                        }
                      } catch (error) {
                        debugPrint("Error al actualizar: $error");
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

  // Diálogo para AÑADIR una nueva tarea (¡GUARDANDO "Estudios"!)
  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    const String fixedCategory = 'Estudios'; // <-- Categoría fija
    final int? defaultReminder =
        await fetchDefaultReminderMinutes(userDocRef);
    int? selectedReminderMinutes = defaultReminder;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Tarea de Estudios'), // Título específico
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration: const InputDecoration(hintText: "Descripción"),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    // No necesitamos selector de categoría, ya es 'Estudios'
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
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.orange),
                          onPressed: () async {
                            final picked = await pickDateTime(
                              context: context,
                              initialDate: selectedDueDate,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            tooltip: 'Quitar fecha',
                            onPressed: () => setDialogState(() => selectedDueDate = null),
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
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Añadir'),
                  onPressed: () async {
                    if (taskController.text.isEmpty) return;
                    final iconName = _getIconNameFromCategory(fixedCategory);
                    final colorName = _getColorNameFromCategory(fixedCategory);
                    final data = <String, dynamic>{
                      'text': taskController.text,
                      'category': fixedCategory,
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
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Resto de Métodos Auxiliares (Copiados EXACTOS de HomeScreen) ---
  Widget _buildGoalItem({ required IconData icon, required Color iconColor, required String text, required bool isDone, required VoidCallback onDonePressed, Timestamp? dueDate, }) { return Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row( children: [ Icon(icon, color: iconColor, size: 28), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( text, style: TextStyle( fontSize: 16, color: isDone ? Colors.grey : Colors.black87, decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none, ), ), if (dueDate != null) ...[ const SizedBox(height: 4), Text( 'Entrega: ${_dateFormatter.format(dueDate.toDate())}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), ), ], ], ), ), const SizedBox(width: 16), ElevatedButton( onPressed: onDonePressed, style: ElevatedButton.styleFrom( backgroundColor: isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25), foregroundColor: isDone ? Colors.grey.shade600 : Colors.blue.shade800, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), ), child: Text(isDone ? 'Deshacer' : 'Hecho'), ), ], ), ); }
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
                      context, taskId, currentText, currentCategory, currentDueDate, reminderMinutes);
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

  void _showEditTaskDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? currentReminderMinutes,
  ) {
    final TextEditingController taskController = TextEditingController(text: currentText);
    final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds', 'Foco'];
    String? selectedCategory = categories.contains(currentCategory) ? currentCategory : 'Estudios';
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
                    TextField(
                      controller: taskController,
                      decoration: const InputDecoration(hintText: 'Nuevo texto'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 20),
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
                            onPressed: () => setDialogState(() => selectedDueDate = null),
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
                    final navigator = Navigator.of(dialogContext);
                    if (taskController.text.isEmpty || selectedCategory == null) {
                      navigator.pop();
                      return;
                    }

                    final String iconName = _getIconNameFromCategory(selectedCategory!);
                    final String colorName = _getColorNameFromCategory(selectedCategory!);
                    final Map<String, dynamic> updatedData = {
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
  String _getIconNameFromCategory(String category) {
    switch (category) {
      case 'Estudios': return 'menu_book';
      case 'Hogar': return 'cleaning_services';
      case 'Meds': return 'medication';
      case 'Foco': return 'psychology'; // Foco
      case 'General':
      default: return 'task_alt'; // ¡¡CON RETURN!!
    }
  }

  String _getColorNameFromCategory(String category) {
    switch (category) {
      case 'Estudios': return 'orange';
      case 'Hogar': return 'green';
      case 'Meds': return 'red';
      case 'Foco': return 'purple'; // Foco
      case 'General':
      default: return 'grey'; // ¡¡CON RETURN!!
    }
  }

} // ¡FIN DE LA CLASE!
