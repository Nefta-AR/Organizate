// lib/screens/test_initial_screen.dart

// --- 1. IMPORTACIONES ---
// Herramientas necesarias para que la pantalla funcione.
import 'package:flutter/material.dart';
import '../widgets/custom_nav_bar.dart'; // La barra de navegación inferior.
import '../widgets/test_header.dart';   // El encabezado con los puntos.
import 'home_screen.dart';             // La pantalla a la que iremos al final.

// --- 2. WIDGET DE LA PANTALLA ---
// Usamos un StatefulWidget porque el contenido de la pantalla (el paso,
// las respuestas) cambiará según las acciones del usuario.
class TestInitialScreen extends StatefulWidget {
  const TestInitialScreen({super.key});

  @override
  State<TestInitialScreen> createState() => _TestInitialScreenState();
}

// --- 3. LÓGICA Y ESTADO DE LA PANTALLA ---
// Aquí es donde "vive" toda la información que puede cambiar.
class _TestInitialScreenState extends State<TestInitialScreen> {
  // -- A. Variables de Estado --

  // Controla en qué paso del test estamos.
  int _currentStep = 1;
  final int _totalSteps = 4;

  // Guarda el valor de la pregunta 1 (Slider).
  double _distractionLevel = 2.0;

  // Guarda las selecciones de la pregunta 2 (Recordatorios).
  final List<String> _reminderOptions = ['Vibración', 'Sonido suave', 'Notificación visual', 'Widget'];
  final List<bool> _selectedReminders = [false, false, false, false];

  // Guarda la selección de la pregunta 3 (Duración de metas).
  String _selectedGoalLength = 'Cortas (25-30 min)';
  final List<String> _goalOptions = ['Cortas (25-30 min)', 'Más largas (45-60 min)'];

// lib/screens/test_initial_screen.dart

// Reemplaza la lista _avatarOptions por esta:
final List<Map<String, String>> _avatarOptions = [
  {'name': 'Emoticon', 'image': 'assets/avatars/emoticon.png'},
  {'name': 'Zorro',    'image': 'assets/avatars/zorro.png'},
  {'name': 'Koala',    'image': 'assets/avatars/koala.png'}, // Ojo: es .jpg
  {'name': 'Panda',    'image': 'assets/avatars/panda.png'},
  {'name': 'Tigre',    'image': 'assets/avatars/tigre.png'}, // Ojo: es .jpg
  {'name': 'Rana',     'image': 'assets/avatars/rana.png'},
  {'name': 'Pinguino', 'image': 'assets/avatars/pinguino.png'},
  {'name': 'Unicornio','image': 'assets/avatars/unicornio.png'},
];
String _selectedAvatar = 'Emoticon'; // Cambiamos el valor por defecto

  // -- B. Funciones para Actualizar el Estado --
  // Estos métodos se llaman cuando el usuario interactúa con la pantalla.
  // Todos usan `setState` para decirle a Flutter que debe redibujar la pantalla.

  void _goToNextStep() {
    setState(() {
      if (_currentStep < _totalSteps) {
        _currentStep++;
      } else {
        // Si es el último paso, navega a la pantalla principal.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  void _goToPreviousStep() {
    setState(() {
      if (_currentStep > 1) {
        _currentStep--;
      }
    });
  }

  void _updateDistractionLevel(double value) {
    setState(() {
      _distractionLevel = value;
    });
  }

  void _toggleReminder(int index) {
    setState(() {
      _selectedReminders[index] = !_selectedReminders[index];
    });
  }

  void _selectGoalLength(String value) {
    setState(() {
      _selectedGoalLength = value;
    });
  }

  void _selectAvatar(String value) {
    setState(() {
      _selectedAvatar = value;
    });
  }

  // --- 4. CONSTRUCCIÓN DE LA INTERFAZ (UI) ---
  // El método `build` es el corazón visual del widget.
  @override
  Widget build(BuildContext context) {
    // Variable para guardar el widget de la pregunta actual.
    Widget currentQuestion;
    // Variable para guardar el título de la pregunta actual.
    String title;

    // Un `switch` para decidir qué pregunta y título mostrar según el `_currentStep`.
    switch (_currentStep) {
      case 1:
        title = 'Cuando estudias o haces tareas, ¿te distraes con facilidad?';
        currentQuestion = _buildDistractionSlider();
        break;
      case 2:
        title = '¿Qué tipo de recordatorios prefieres?';
        currentQuestion = _buildReminderOptions();
        break;
      case 3:
        title = '¿Prefieres metas diarias cortas o sesiones largas?';
        currentQuestion = _buildGoalOptions();
        break;
      case 4:
        title = 'Elige un avatar inicial';
        currentQuestion = _buildAvatarOptions();
        break;
      default:
        title = 'Error';
        currentQuestion = const Center(child: Text('Cargando...'));
        break;
    }

    // `Scaffold` es el esqueleto principal de la pantalla.
    return Scaffold(
      appBar: AppBar(
        title: TestHeader(tokens: 1200, rewards: 5),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // La barra de navegación que creamos en un archivo separado.
      bottomNavigationBar: const CustomNavBar(),
      // El cuerpo principal de la pantalla.
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Tarjeta de progreso.
            _buildProgressCard(),
            const SizedBox(height: 24),

            // 2. Título de la pregunta.
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 3. Widget de la pregunta actual (ocupa el espacio expandido).
            Expanded(child: currentQuestion),

            // 4. Botones de navegación.
            _buildBackNextRow(),
          ],
        ),
      ),
    );
  }

  // --- 5. MÉTODOS AUXILIARES PARA CONSTRUIR WIDGETS ---
  // Dividimos la UI en métodos más pequeños para que sea más fácil de leer.

  // Widget para la tarjeta de progreso.
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test inicial (rápido)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ayúdanos a adaptar la app a tu estilo. 1-2 minutos.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _currentStep / _totalSteps,
            backgroundColor: Colors.blue.withOpacity(0.2),
            color: Colors.blueAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // Widget para la pregunta 1: Slider con emojis.
  Widget _buildDistractionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mueve el deslizador para indicar tu nivel de distracción:',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🙂', style: TextStyle(fontSize: 30)),
              Text('😐', style: TextStyle(fontSize: 30)),
              Text('🤯', style: TextStyle(fontSize: 30)),
              Text('🛸', style: TextStyle(fontSize: 30)),
            ],
          ),
        ),
        Slider(
          value: _distractionLevel,
          min: 1.0,
          max: 4.0,
          divisions: 3,
          label: _distractionLevel.round().toString(),
          onChanged: _updateDistractionLevel,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Muy poca', style: TextStyle(fontSize: 14)),
            Text('Mucha', style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  // Widget para la pregunta 2: Opciones de recordatorios.
  Widget _buildReminderOptions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(_reminderOptions.length, (index) {
            final option = _reminderOptions[index];
            final isSelected = _selectedReminders[index];
            return GestureDetector(
              onTap: () => _toggleReminder(index),
              child: Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: isSelected ? Colors.amber.shade700 : Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blueAccent : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // Widget para la pregunta 3: Duración de metas.
  Widget _buildGoalOptions() {
    return Column(
      children: _goalOptions.map((option) {
        final isSelected = _selectedGoalLength == option;
        return GestureDetector(
          onTap: () => _selectGoalLength(option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco().copyWith(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget para la pregunta 4: Selección de avatar.
// lib/screens/test_initial_screen.dart

// Reemplaza el método _buildAvatarOptions completo por este:
Widget _buildAvatarOptions() {
  return GridView.builder(
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4, // 4 avatares por fila
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: _avatarOptions.length,
    itemBuilder: (context, index) {
      final option = _avatarOptions[index]!;
      final isSelected = _selectedAvatar == option['name'];
      return GestureDetector(
        onTap: () => _selectAvatar(option['name']!),
        child: Container(
          padding: const EdgeInsets.all(8), // Un poco de espacio interno
          decoration: _cardDeco().copyWith(
            color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
              width: 2.5, // Un borde más grueso al seleccionar
            ),
          ),
          // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
          // Usamos Image.asset para cargar tu archivo de imagen.
          child: Image.asset(
            option['image']!,
          ),
        ),
      );
    },
  );
}
  
  // Widget para la fila de botones "Atrás" y "Siguiente".
  Row _buildBackNextRow() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(child: _outlined('Atrás', _goToPreviousStep)),
        if (_currentStep > 1)
          const SizedBox(width: 16),
        Expanded(
          child: _filled(
            _currentStep < _totalSteps ? 'Siguiente' : 'Listo',
            _goToNextStep
          ),
        ),
      ],
    );
  }

  // Estilo para el botón delineado ("Atrás").
  Widget _outlined(String label, VoidCallback onPressed) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
  );

  // Estilo para el botón con relleno ("Siguiente").
  Widget _filled(String label, VoidCallback onPressed) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: const Color(0xFF0099FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  // Estilo base para las tarjetas de selección.
  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 5,
      )
    ],
  );
}