// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organizate/widgets/custom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance
          .collection('users')
          .doc('neftali_user')
          .collection('tasks');

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
            child: Row(children: const [ // <-- Añadido const aquí
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
      body: SingleChildScrollView( // <-- Solución Overflow
        child: Padding(
          padding: const EdgeInsets.all(20.0), // <-- Con 'padding:'
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),         // Saludo
              const SizedBox(height: 24),
              _buildCategoryGrid(),       // Categorías
              const SizedBox(height: 24),
              _buildTodayGoalsHeader(), // Título Metas
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>( // Lista Metas (SIN Expanded)
                stream: tasksCollection.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Error Firestore: ${snapshot.error}'); // Añadido para depuración
                    return const Center(child: Text('Error al cargar tareas'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Añade tu primera tarea con el botón +'));
                  }
                  final tasks = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true, // <-- Ajuste Scroll
                    physics: const NeverScrollableScrollPhysics(), // <-- Ajuste Scroll
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final taskData = tasks[index].data() as Map<String, dynamic>;
                      final taskId = tasks[index].id;
                      return _buildGoalItem(
                        icon: _getIconFromString(taskData['iconName'] ?? 'task_alt'),
                        iconColor: _getColorFromString(taskData['colorName'] ?? 'grey'),
                        text: taskData['text'] ?? 'Tarea sin nombre',
                        isDone: taskData['done'] ?? false,
                        onDonePressed: () {
                          tasksCollection.doc(taskId).update({
                            'done': !(taskData['done'] ?? false),
                          });
                        },
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
        color: Colors.blue.withAlpha(25), // Usando withAlpha
        borderRadius: BorderRadius.circular(16),
      ),
      // --- REVISADO Y CORREGIDO ---
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column( // Columna para el texto de saludo
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('Hoy, enfoquémonos en 3 tareas', style: TextStyle(fontSize: 16, color: Colors.black54)),
            ],
          ), // <-- Asegúrate que la coma esté aquí
          SizedBox( // Círculo de progreso
            width: 70, height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.60, strokeWidth: 8,
                  backgroundColor: Colors.green.withAlpha(51), // Usando withAlpha
                  color: Colors.green,
                ),
                Center(child: Text('60%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800))), // <-- Asegúrate que la coma esté aquí, aunque sea la última
              ], // <-- Cierre de children del Stack
            ), // <-- Cierre de SizedBox
          ), // <-- Cierre de SizedBox (¡Aquí podría haber estado el error!)
        ], // <-- Cierre de children del Row
      ), // <-- Cierre de Container
    ); // <-- Cierre del return
  }
  // --- FIN DE _buildHeaderCard ---

  Widget _buildCategoryGrid() {
     return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
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
          boxShadow: [ BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 5) ], // Usando withAlpha
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isDone ? Colors.grey : Colors.black87,
                decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25), // Usando withAlpha
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva Tarea'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: "Descripción de la tarea"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Añadir'),
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  tasksCollection.add({
                    'text': taskController.text,
                    'iconName': 'task_alt',
                    'colorName': 'grey',
                    'done': false,
                    'createdAt': Timestamp.now(),
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'menu_book': return Icons.menu_book;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'medication': return Icons.medication;
      case 'task_alt': return Icons.task_alt;
      default: return Icons.task;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'grey': return Colors.grey;
      default: return Colors.blue;
    }
  }
} // ¡FIN DE LA CLASE _HomeScreenState!
