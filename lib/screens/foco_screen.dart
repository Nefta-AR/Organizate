import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:organizate/widgets/custom_nav_bar.dart';


class FocoScreen extends StatefulWidget {
  const FocoScreen({super.key});

  @override
  State<FocoScreen> createState() => _FocoScreenState();
}

class _FocoScreenState extends State<FocoScreen> {
  // --- Referencias a Firestore (igual que en HomeScreen) ---
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('users').doc('neftali_user').collection('tasks');
  final DocumentReference userDocRef =
      FirebaseFirestore.instance.collection('users').doc('neftali_user');
  
  // --- Formateador de Fecha (igual que en HomeScreen) ---
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();
    try { _dateFormatter = DateFormat('dd MMM', 'es_ES'); } 
    catch (e) { _dateFormatter = DateFormat('dd MMM'); }
  }

  @override
  Widget build(BuildContext context) {
    const int screenIndex = 4; // <-- CAMBIADO: Índice 4 para "Foco"

    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: screenIndex), // Pasa el índice
      appBar: AppBar(
        title: const Text('Foco / Mindfulness'), // <-- CAMBIADO: Título
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
              return Row( children: [ Padding( padding: const EdgeInsets.only(left: 8.0), child: Row( children: [ const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 4), Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), ], ), ), Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [ Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20), const SizedBox(width: 4), Text('$streak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), ]), ), if (avatarName != null) Padding( padding: const EdgeInsets.only(right: 12.0), child: CircleAvatar( radius: 15, backgroundImage: AssetImage('assets/avatars/$avatarName.png'), onBackgroundImageError: (e,s){}, ), ), if (avatarName == null) const Padding( padding: const EdgeInsets.only(right: 12.0), child: CircleAvatar(radius: 15, backgroundColor: Colors.grey),), ], );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context), // Llama al diálogo de ESTA pantalla
        backgroundColor: Colors.purple, // <-- CAMBIADO: Color Púrpura de Foco
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // --- Cuerpo con StreamBuilder FILTRADO ---
      body: StreamBuilder<QuerySnapshot>(
        // --- ¡¡¡LA MAGIA ESTÁ AQUÍ!!! ---
        stream: tasksCollection
            .where('category', isEqualTo: 'Foco') // <-- CAMBIADO: Filtro por 'Foco'
            .orderBy('done') // Pendientes (false) primero
            .orderBy('createdAt', descending: true) // Luego las más nuevas
            .snapshots(),
        // --- FIN DE LA MAGIA ---
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
          
          // Imprimimos el error SI EXISTE
          if (snapshot.hasError) { 
            print('¡¡¡ERROR EN FIREBASE (FOCO): ${snapshot.error}!!!');
            return const Center(child: Text('Error al cargar tareas')); 
          }
          
          // Mensaje específico si no hay tareas de FOCO
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { 
            return const Center(child: Padding( 
              padding: EdgeInsets.all(32.0), 
              child: Text('No tienes tareas de foco.\n¡Añade una con el botón +!', // <-- CAMBIADO
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

              // Reutiliza los mismos widgets de `HomeScreen`
              return GestureDetector(
                onLongPress: () => _showTaskOptionsDialog(context, taskId, currentText, 'Foco', currentDueDate), // <-- CAMBIADO
                child: _buildGoalItem(
                  icon: Icons.psychology, // <-- CAMBIADO: Ícono de Foco
                  iconColor: Colors.purple, // <-- CAMBIADO: Color de Foco
                  text: currentText,
                  isDone: isCurrentlyDone,
                  dueDate: currentDueDate,
                  onDonePressed: () {
                      // Lógica para actualizar puntos (igual que en HomeScreen)
                      final pointsChange = isCurrentlyDone ? -10 : 10;
                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      batch.update(tasksCollection.doc(taskId), {'done': !isCurrentlyDone});
                      batch.update(userDocRef, {'points': FieldValue.increment(pointsChange)});
                      batch.commit().catchError((error) { print("Error al actualizar: $error"); });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- MÉTODOS AUXILIARES (Copiados de HomeScreen, con ligeros cambios) ---

  // Diálogo para AÑADIR una nueva tarea (¡GUARDANDO "Foco"!)
  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    const String fixedCategory = 'Foco'; // <-- CAMBIADO: Categoría fija

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Tarea de Foco'), // <-- CAMBIADO: Título específico
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
                    // No necesitamos selector de categoría, ya es 'Foco'
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
                          icon: const Icon(Icons.calendar_today, color: Colors.purple), // <-- CAMBIADO: Color de Foco
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime(DateTime.now().year - 1),
                              lastDate: DateTime(DateTime.now().year + 5),
                            );
                            if (picked != null) setDialogState(() => selectedDueDate = picked);
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
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('Añadir'),
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      String iconName = _getIconNameFromCategory(fixedCategory);
                      String colorName = _getColorNameFromCategory(fixedCategory);
                      Map<String, dynamic> taskData = {
                        'text': taskController.text,
                        'category': fixedCategory, // <-- Guarda "Foco"
                        'iconName': iconName,
                        'colorName': colorName,
                        'done': false,
                        'createdAt': Timestamp.now(),
                        if (selectedDueDate != null) 'dueDate': Timestamp.fromDate(selectedDueDate!),
                      };
                      tasksCollection.add(taskData);
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

  // --- Resto de Métodos Auxiliares (Copiados EXACTOS de HomeScreen/Estudios) ---
  Widget _buildGoalItem({ required IconData icon, required Color iconColor, required String text, required bool isDone, required VoidCallback onDonePressed, Timestamp? dueDate, }) { return Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row( children: [ Icon(icon, color: iconColor, size: 28), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( text, style: TextStyle( fontSize: 16, color: isDone ? Colors.grey : Colors.black87, decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none, ), ), if (dueDate != null) ...[ const SizedBox(height: 4), Text( 'Entrega: ${_dateFormatter.format(dueDate.toDate())}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), ), ], ], ), ), const SizedBox(width: 16), ElevatedButton( onPressed: onDonePressed, style: ElevatedButton.styleFrom( backgroundColor: isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25), foregroundColor: isDone ? Colors.grey.shade600 : Colors.blue.shade800, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), ), child: Text(isDone ? 'Deshacer' : 'Hecho'), ), ], ), ); }
  void _showTaskOptionsDialog(BuildContext context, String taskId, String currentText, String? currentCategory, Timestamp? currentDueDate) { showDialog( context: context, builder: (BuildContext context) { return AlertDialog( title: Text('Opciones:\n"$currentText"'), content: Column( mainAxisSize: MainAxisSize.min, children: <Widget>[ ListTile( leading: const Icon(Icons.edit), title: const Text('Editar'), onTap: () { if (mounted) Navigator.of(context).pop(); _showEditTaskDialog(context, taskId, currentText, currentCategory, currentDueDate); }, ), ListTile( leading: const Icon(Icons.delete), title: const Text('Eliminar'), onTap: () async { try { await tasksCollection.doc(taskId).delete(); if (!mounted) return; Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('"$currentText" eliminada')) ); } catch (error) { if (!mounted) return; Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error al eliminar')) ); } }, ), ], ), actions: <Widget>[ TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()), ], ); }, ); }
  void _showEditTaskDialog(BuildContext context, String taskId, String currentText, String? currentCategory, Timestamp? currentDueDate) { final TextEditingController taskController = TextEditingController(text: currentText); 
    final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds', 'Foco']; 
    String? selectedCategory = categories.contains(currentCategory) ? currentCategory : 'Foco'; 
    DateTime? selectedDueDate = currentDueDate?.toDate(); showDialog( context: context, builder: (BuildContext context) { return StatefulBuilder( builder: (context, setDialogState) { return AlertDialog( title: const Text('Editar Tarea'), content: SingleChildScrollView( child: Column( mainAxisSize: MainAxisSize.min, children: [ TextField( controller: taskController, decoration: const InputDecoration(hintText: "Nuevo texto"), autofocus: true, ), const SizedBox(height: 20), DropdownButtonFormField<String>( initialValue: selectedCategory, decoration: const InputDecoration(labelText: 'Categoría'), items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(), onChanged: (val) => setDialogState(() => selectedCategory = val), ), const SizedBox(height: 20), Row( children: [ Expanded( child: Text( selectedDueDate == null ? 'Sin fecha' : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}', style: TextStyle(color: Colors.grey.shade600), ), ), IconButton( icon: const Icon(Icons.calendar_today), onPressed: () async { final DateTime? picked = await showDatePicker( context: context, initialDate: selectedDueDate ?? DateTime.now(), firstDate: DateTime(DateTime.now().year - 1), lastDate: DateTime(DateTime.now().year + 5) ); if (picked != null) setDialogState(() => selectedDueDate = picked); }, ), if (selectedDueDate != null) IconButton( icon: const Icon(Icons.clear, size: 18), onPressed: () => setDialogState(() => selectedDueDate = null), ), ], ), ], ), ), actions: <Widget>[ TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()), TextButton( child: const Text('Guardar'), onPressed: () async { if (taskController.text.isNotEmpty && selectedCategory != null) { String iconName = _getIconNameFromCategory(selectedCategory!); String colorName = _getColorNameFromCategory(selectedCategory!); Map<String, dynamic> updatedData = { 'text': taskController.text, 'category': selectedCategory, 'iconName': iconName, 'colorName': colorName, 'dueDate': selectedDueDate == null ? FieldValue.delete() : Timestamp.fromDate(selectedDueDate!), }; try { await tasksCollection.doc(taskId).update(updatedData); if (!mounted) return; Navigator.of(context).pop(); } catch (error) { print("Error: $error"); if (!mounted) return; Navigator.of(context).pop(); } } else { if (mounted) Navigator.of(context).pop(); } }, ), ], ); }, ); }, ); }
  
  // --- MÉTODOS DE AYUDA (CORREGIDOS Y COMPLETOS) ---
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'menu_book': return Icons.menu_book;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'medication': return Icons.medication;
      case 'psychology': return Icons.psychology; // Foco
      case 'task_alt': return Icons.task_alt;
      default: return Icons.task;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'purple': return Colors.purple; // Foco
      case 'grey': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _getIconNameFromCategory(String category) {
    switch (category) {
      case 'Estudios': return 'menu_book';
      case 'Hogar': return 'cleaning_services';
      case 'MSeds': return 'medication';
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