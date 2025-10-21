// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Importa el paquete para formatear fechas
import 'package:organizate/widgets/custom_nav_bar.dart'; // Asegúrate que la ruta sea correcta

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance
          .collection('users')
          .doc('neftali_user') // Tu ID simulado
          .collection('tasks'); // Tu colección personal de tareas

  // Formateador de fecha (ej: "21 Oct")
  final DateFormat _dateFormatter = DateFormat('dd MMM', 'es_ES'); // Asegúrate de tener locale 'es_ES'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(),
      appBar: AppBar(
        title: const Text('Organízate'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(children: const [
              Icon(Icons.local_fire_department, color: Colors.deepOrange),
              Text('5', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              _buildTodayGoalsHeader(),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: tasksCollection.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
                   if (snapshot.hasError) { print('Error Firestore: ${snapshot.error}'); return const Center(child: Text('Error al cargar tareas')); }
                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return const Center(child: Text('Añade tu primera tarea con el botón +')); }

                  final tasks = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final taskData = tasks[index].data() as Map<String, dynamic>;
                      final taskId = tasks[index].id;
                      final String currentText = taskData['text'] ?? 'Tarea sin nombre';
                      final String? currentCategory = taskData['category'] as String?;
                      final Timestamp? currentDueDate = taskData['dueDate'] as Timestamp?;

                      return GestureDetector(
                        onLongPress: () {
                          _showTaskOptionsDialog(context, taskId, currentText, currentCategory, currentDueDate);
                        },
                        child: _buildGoalItem(
                          icon: _getIconFromString(taskData['iconName'] ?? 'task_alt'),
                          iconColor: _getColorFromString(taskData['colorName'] ?? 'grey'),
                          text: currentText,
                          isDone: taskData['done'] ?? false,
                          dueDate: currentDueDate,
                          onDonePressed: () {
                            tasksCollection.doc(taskId).update({
                              'done': !(taskData['done'] ?? false),
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  Widget _buildHeaderCard() {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('Hoy, enfoquémonos en 3 tareas', style: TextStyle(fontSize: 16, color: Colors.black54)),
            ],
          ),
          SizedBox(
            width: 70, height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.60, strokeWidth: 8,
                  backgroundColor: Colors.green.withAlpha(51),
                  color: Colors.green,
                ),
                Center(child: Text('60%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
     return GridView.count(
      // --- CORREGIDO: Faltaba crossAxisCount ---
      crossAxisCount: 2,
      crossAxisSpacing: 16, mainAxisSpacing: 16,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCategoryCard(title: 'Estudios', subtitle: 'Pomodoro + pendientes', icon: Icons.school, color: Colors.orange, onTap: () { print('Estudios'); }),
        _buildCategoryCard(title: 'Quehaceres', subtitle: 'Lista visual', icon: Icons.cottage, color: Colors.green, onTap: () { print('Quehaceres'); }),
        _buildCategoryCard(title: 'Medicamentos', subtitle: 'Recordatorios', icon: Icons.medication, color: Colors.red, onTap: () { print('Medicamentos'); }),
        _buildCategoryCard(title: 'Mindfulness', subtitle: 'Respira y enfoca', icon: Icons.self_improvement, color: Colors.purple, onTap: () { print('Mindfulness'); }),
      ],
    );
  }

  Widget _buildCategoryCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
      return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [ BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 5) ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            // --- CORREGIDO: Faltaba el texto aquí ---
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

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

  Widget _buildGoalItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDone,
    required VoidCallback onDonePressed,
    Timestamp? dueDate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
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
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25),
              foregroundColor: isDone ? Colors.grey.shade600 : Colors.blue.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isDone ? 'Deshacer' : 'Hecho'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds'];
    String? selectedCategory = 'General';
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Tarea'),
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
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val),
                      validator: (v) => v == null ? 'Selecciona' : null,
                    ),
                    const SizedBox(height: 20),
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
                          icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              // --- CORREGIDO: firstDate y lastDate ---
                              firstDate: DateTime(DateTime.now().year - 1), // Permite elegir desde el año pasado
                              lastDate: DateTime(DateTime.now().year + 5), // Permite elegir hasta 5 años en el futuro
                            );
                            if (picked != null && picked != selectedDueDate) {
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
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('Añadir'),
                  onPressed: () {
                    if (taskController.text.isNotEmpty && selectedCategory != null) {
                      String iconName = _getIconNameFromCategory(selectedCategory!);
                      String colorName = _getColorNameFromCategory(selectedCategory!);
                      Map<String, dynamic> taskData = {
                        'text': taskController.text,
                        'category': selectedCategory,
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

  void _showTaskOptionsDialog(BuildContext context, String taskId, String currentText, String? currentCategory, Timestamp? currentDueDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Opciones para:\n"$currentText"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Editar Tarea'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditTaskDialog(context, taskId, currentText, currentCategory, currentDueDate);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar Tarea'),
                onTap: () {
                     tasksCollection.doc(taskId).delete().then((_) { print("Tarea eliminada"); Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('"$currentText" eliminada')) ); }).catchError((error) { print("Error al eliminar: $error"); Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('No se pudo eliminar la tarea')) ); });
                 },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, String taskId, String currentText, String? currentCategory, Timestamp? currentDueDate) {
    final TextEditingController taskController = TextEditingController(text: currentText);
    final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds'];
    String? selectedCategory = categories.contains(currentCategory) ? currentCategory : 'General';
    DateTime? selectedDueDate = currentDueDate?.toDate();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration: const InputDecoration(hintText: "Nuevo texto"),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null ? 'Sin fecha' : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                               // --- CORREGIDO: showDatePicker necesita estos 3 ---
                               context: context,
                               initialDate: selectedDueDate ?? DateTime.now(),
                               firstDate: DateTime(DateTime.now().year - 1), // Desde el año pasado
                               lastDate: DateTime(DateTime.now().year + 5) // Hasta 5 años en el futuro
                            );
                            if (picked != null) setDialogState(() => selectedDueDate = picked);
                          },
                        ),
                        if (selectedDueDate != null)
                         IconButton( icon: const Icon(Icons.clear, size: 18, color: Colors.grey), onPressed: () => setDialogState(() => selectedDueDate = null), ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('Guardar'),
                  onPressed: () {
                    if (taskController.text.isNotEmpty && selectedCategory != null) {
                      String iconName = _getIconNameFromCategory(selectedCategory!);
                      String colorName = _getColorNameFromCategory(selectedCategory!);
                      Map<String, dynamic> updatedData = {
                        'text': taskController.text,
                        'category': selectedCategory,
                        'iconName': iconName,
                        'colorName': colorName,
                        'dueDate': selectedDueDate == null ? FieldValue.delete() : Timestamp.fromDate(selectedDueDate!),
                      };
                      tasksCollection.doc(taskId).update(updatedData).then((_) {
                        print("Tarea actualizada completa");
                        Navigator.of(context).pop();
                      }).catchError((error){
                        print("Error al actualizar: $error");
                        Navigator.of(context).pop();
                      });
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

  // --- Funciones Auxiliares ---

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'menu_book': return Icons.menu_book;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'medication': return Icons.medication;
      case 'task_alt': return Icons.task_alt;
      // --- CORREGIDO: Faltaba default ---
      default: return Icons.task;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'grey': return Colors.grey;
      // --- CORREGIDO: Faltaba default ---
      default: return Colors.blue;
    }
  }

  String _getIconNameFromCategory(String category) {
    switch (category) {
      case 'Estudios': return 'menu_book';
      case 'Hogar': return 'cleaning_services';
      case 'Meds': return 'medication';
      case 'General':
      // --- CORREGIDO: Faltaba default ---
      default: return 'task_alt';
    }
  }

  String _getColorNameFromCategory(String category) {
    switch (category) {
      case 'Estudios': return 'orange';
      case 'Hogar': return 'green';
      case 'Meds': return 'red';
      case 'General':
      // --- CORREGIDO: Faltaba default ---
      default: return 'grey';
    }
  }

} // ¡FIN DE LA CLASE _HomeScreenState!