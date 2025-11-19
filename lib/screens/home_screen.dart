// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Asegúrate que flutter pub add intl funcionó
import 'package:organizate/widgets/custom_nav_bar.dart'; // Verifica ruta
import 'package:organizate/screens/estudios_screen.dart'; // Importa para navegación
import 'package:organizate/screens/hogar_screen.dart';    // Importa para navegación
import 'package:organizate/screens/meds_screen.dart';     // Importa para navegación
import 'package:organizate/screens/foco_screen.dart';     // Importa para navegación
// No necesita importar ProgresoScreen si solo navega a ella desde la barra

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get userDocRef =>
      FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

  CollectionReference<Map<String, dynamic>> get tasksCollection =>
      userDocRef.collection('tasks');

  final DateFormat _dateFormatter = DateFormat('dd MMM', 'es_ES'); // Formato fecha

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: 0), // Indica que esta es la pantalla de Inicio (índice 0)
      appBar: AppBar(
        title: const Text('Organízate'),
        elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.black, automaticallyImplyLeading: false, // Quita flecha atrás
        actions: [
          // StreamBuilder para Puntos, Racha y Avatar
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.hasError) {
              return Row(
                children: [
                    const Icon(Icons.star, color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    const Text(
                      '...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: const [
                          Icon(Icons.local_fire_department, color: Colors.grey, size: 20),
                          SizedBox(width: 4),
                          Text('...'),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(radius: 15, backgroundColor: Colors.grey),
                    ),
                  ],
                );
              }

              final userData = snapshot.data?.data() ?? {};
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
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: AssetImage('assets/avatars/$avatarName.png'),
                        onBackgroundImageError: (e, s) {
                          debugPrint('Error avatar: $e');
                        },
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton( onPressed: () => _showAddTaskDialog(context), backgroundColor: Colors.blueAccent, child: const Icon(Icons.add, color: Colors.white), ),
      body: SingleChildScrollView( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeaderCard(), const SizedBox(height: 24), _buildCategoryGrid(), const SizedBox(height: 24), _buildTodayGoalsHeader(), const SizedBox(height: 16),
              // StreamBuilder para la lista de tareas
              StreamBuilder<QuerySnapshot>( stream: tasksCollection.orderBy('createdAt', descending: true).snapshots(), builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
                   if (snapshot.hasError) { debugPrint('Error Firestore: ${snapshot.error}'); return const Center(child: Text('Error al cargar tareas')); }
                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return const Center(child: Text('Añade tu primera tarea con el botón +')); }
                  final tasks = snapshot.data!.docs;
                  // Construye la lista
                  return ListView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: tasks.length, itemBuilder: (context, index) {
                      final taskData = tasks[index].data() as Map<String, dynamic>; final taskId = tasks[index].id;
                      final String currentText = taskData['text'] ?? ''; final String? currentCategory = taskData['category'] as String?;
                      final Timestamp? currentDueDate = taskData['dueDate'] as Timestamp?; final bool isCurrentlyDone = taskData['done'] ?? false;
                      // GestureDetector para Long Press
                      return GestureDetector( onLongPress: () => _showTaskOptionsDialog(context, taskId, currentText, currentCategory, currentDueDate),
                        child: _buildGoalItem( // Dibuja cada tarea
                          icon: _getIconFromString(taskData['iconName'] ?? 'task_alt'), iconColor: _getColorFromString(taskData['colorName'] ?? 'grey'),
                          text: currentText, isDone: isCurrentlyDone, dueDate: currentDueDate,
                          // --- ¡AQUÍ ESTÁ LA LÓGICA DE PUNTOS! ---
                          onDonePressed: () {
                             final pointsChange = isCurrentlyDone ? -10 : 10; // Suma 10 si no está hecha, resta 10 si sí
                             WriteBatch batch = FirebaseFirestore.instance.batch(); // Prepara operaciones múltiples
                             // Operación 1: Cambia el estado 'done' de la tarea
                             batch.update(tasksCollection.doc(taskId), {'done': !isCurrentlyDone});
                             // Operación 2: Incrementa/decrementa los puntos del usuario
                             batch.update(userDocRef, {'points': FieldValue.increment(pointsChange)});
                             // TODO: Actualizar racha aquí (lógica más compleja)
                             // Ejecuta ambas operaciones juntas
                              final messenger = ScaffoldMessenger.of(context);
                              batch.commit().then((_){
                               debugPrint('Tarea ${!isCurrentlyDone ? 'completada' : 'desmarcada'} y puntos actualizados.');
                              }).catchError((error) {
                               debugPrint('Error al actualizar tarea/puntos: $error');
                               messenger.showSnackBar( const SnackBar(content: Text('Error al marcar tarea.')) );
                              });
                          },
                          // --- FIN LÓGICA DE PUNTOS ---
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

  // --- MÉTODOS AUXILIARES (Sin cambios, ya estaban bien) ---
  Widget _buildHeaderCard() { return Container( padding: const EdgeInsets.all(20), decoration: BoxDecoration( color: Colors.blue.withAlpha(25), borderRadius: BorderRadius.circular(16), ), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Hola 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Hoy, enfoquémonos en...', style: TextStyle(fontSize: 16, color: Colors.black54)), ], ), SizedBox( width: 70, height: 70, child: Stack( fit: StackFit.expand, children: [ CircularProgressIndicator( value: 0.60, strokeWidth: 8, backgroundColor: Colors.green.withAlpha(51), color: Colors.green, ), Center(child: Text('60%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800))), ], ), ), ], ), ); }
  Widget _buildCategoryGrid() { return GridView.count( crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
        // --- NAVEGACIÓN AÑADIDA ---
        _buildCategoryCard(title: 'Estudios', subtitle: 'Pomodoro + pendientes', icon: Icons.school, color: Colors.orange, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EstudiosScreen()))),
        _buildCategoryCard(title: 'Quehaceres', subtitle: 'Lista visual', icon: Icons.cottage, color: Colors.green, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HogarScreen()))),
        _buildCategoryCard(title: 'Medicamentos', subtitle: 'Recordatorios', icon: Icons.medication, color: Colors.red, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedsScreen()))),
        _buildCategoryCard(title: 'Mindfulness', subtitle: 'Respira y enfoca', icon: Icons.self_improvement, color: Colors.purple, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FocoScreen()))),
      ], ); }
  Widget _buildCategoryCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) { return GestureDetector( onTap: onTap, child: Container( padding: const EdgeInsets.all(16), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [ BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 5) ], ), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Icon(icon, size: 32, color: color), const Spacer(), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)), ], ), ), ); }
  Widget _buildTodayGoalsHeader() { return const Text( 'Tus metas de hoy', style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, ), ); }
  Widget _buildGoalItem({ required IconData icon, required Color iconColor, required String text, required bool isDone, required VoidCallback onDonePressed, Timestamp? dueDate, }) { return Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row( children: [ Icon(icon, color: iconColor, size: 28), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( text, style: TextStyle( fontSize: 16, color: isDone ? Colors.grey : Colors.black87, decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none, ), ), if (dueDate != null) ...[ const SizedBox(height: 4), Text( 'Entrega: ${_dateFormatter.format(dueDate.toDate())}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), ), ], ], ), ), const SizedBox(width: 16), ElevatedButton( onPressed: onDonePressed, style: ElevatedButton.styleFrom( backgroundColor: isDone ? Colors.grey.shade300 : Colors.blue.withAlpha(25), foregroundColor: isDone ? Colors.grey.shade600 : Colors.blue.shade800, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), ), child: Text(isDone ? 'Deshacer' : 'Hecho'), ), ], ), ); }
  void _showAddTaskDialog(BuildContext context) { final TextEditingController taskController = TextEditingController(); final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds']; String? selectedCategory = 'General'; DateTime? selectedDueDate; showDialog( context: context, builder: (BuildContext context) { return StatefulBuilder( builder: (context, setDialogState) { return AlertDialog( title: const Text('Nueva Tarea'), content: SingleChildScrollView( child: Column( mainAxisSize: MainAxisSize.min, children: [ TextField( controller: taskController, decoration: const InputDecoration(hintText: "Descripción"), autofocus: true, ), const SizedBox(height: 20), DropdownButtonFormField<String>( initialValue: selectedCategory, decoration: const InputDecoration(labelText: 'Categoría'), items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(), onChanged: (val) => setDialogState(() => selectedCategory = val), validator: (v) => v == null ? 'Selecciona' : null, ), const SizedBox(height: 20), Row( children: [ Expanded( child: Text( selectedDueDate == null ? 'Sin fecha' : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}', style: TextStyle(color: Colors.grey.shade600), ), ), IconButton( icon: const Icon(Icons.calendar_today), onPressed: () async { final DateTime? picked = await showDatePicker( context: context, initialDate: selectedDueDate ?? DateTime.now(), firstDate: DateTime(DateTime.now().year - 1), lastDate: DateTime(DateTime.now().year + 5), ); if (picked != null) setDialogState(() => selectedDueDate = picked); }, ), if (selectedDueDate != null) IconButton( icon: const Icon(Icons.clear, size: 18), onPressed: () => setDialogState(() => selectedDueDate = null), ), ], ), ], ), ), actions: <Widget>[ TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()), TextButton( child: const Text('Añadir'), onPressed: () { if (taskController.text.isNotEmpty && selectedCategory != null) { String iconName = _getIconNameFromCategory(selectedCategory!); String colorName = _getColorNameFromCategory(selectedCategory!); Map<String, dynamic> taskData = { 'text': taskController.text, 'category': selectedCategory, 'iconName': iconName, 'colorName': colorName, 'done': false, 'createdAt': Timestamp.now(), if (selectedDueDate != null) 'dueDate': Timestamp.fromDate(selectedDueDate!), }; tasksCollection.add(taskData); Navigator.of(context).pop(); } }, ), ], ); }, ); }, ); }
  void _showTaskOptionsDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
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
                  _showEditTaskDialog(context, taskId, currentText, currentCategory, currentDueDate);
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
                    debugPrint('Eliminada');
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('"$currentText" eliminada')),
                    );
                  } catch (error) {
                    debugPrint('Error: $error');
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Error al eliminar')),
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
  ) {
    final TextEditingController taskController = TextEditingController(text: currentText);
    final List<String> categories = ['General', 'Estudios', 'Hogar', 'Meds'];
    String? selectedCategory = categories.contains(currentCategory) ? currentCategory : 'General';
    DateTime? selectedDueDate = currentDueDate?.toDate();

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
                            final DateTime? picked = await showDatePicker(
                              context: statefulContext,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime(DateTime.now().year - 1),
                              lastDate: DateTime(DateTime.now().year + 5),
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
                      'dueDate': selectedDueDate == null
                          ? FieldValue.delete()
                          : Timestamp.fromDate(selectedDueDate!),
                    };

                    try {
                      await tasksCollection.doc(taskId).update(updatedData);
                      debugPrint('Actualizada');
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
  IconData _getIconFromString(String iconName) { switch (iconName) { case 'menu_book': return Icons.menu_book; case 'cleaning_services': return Icons.cleaning_services; case 'medication': return Icons.medication; case 'task_alt': return Icons.task_alt; default: return Icons.task; } }
  Color _getColorFromString(String colorName) { switch (colorName) { case 'orange': return Colors.orange; case 'green': return Colors.green; case 'red': return Colors.red; case 'grey': return Colors.grey; default: return Colors.blue; } }
  String _getIconNameFromCategory(String category) { switch (category) { case 'Estudios': return 'menu_book'; case 'Hogar': return 'cleaning_services'; case 'Meds': return 'medication'; case 'General': default: return 'task_alt'; } }
  String _getColorNameFromCategory(String category) { switch (category) { case 'Estudios': return 'orange'; case 'Hogar': return 'green'; case 'Meds': return 'red'; case 'General': default: return 'grey'; } }

} // ¡FIN DE LA CLASE _HomeScreenState!
