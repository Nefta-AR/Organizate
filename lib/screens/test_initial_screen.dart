// lib/screens/test_initial_screen.dart

import 'package:flutter/material.dart';
// Importamos los widgets necesarios.
import '../widgets/custom_nav_bar.dart'; // Asegúrate de que esta ruta sea correcta
import '../widgets/test_header.dart';   // Asegúrate de que esta ruta sea correcta
import 'home_screen.dart'; // Importamos la pantalla final.


/// Test inicial (4 pasos) con header gamificado y tarjetas de preguntas.
// StatefulWidget: Se usa porque el estado (paso actual, selecciones) cambia.
class TestInitialScreen extends StatefulWidget {
  const TestInitialScreen({super.key});
  @override
  State<TestInitialScreen> createState() => _TestInitialScreenState();
}

class _TestInitialScreenState extends State<TestInitialScreen> {
  // 1) Estado de navegación
  int _currentStep = 1; // Inicia en el paso 1.
  final int _totalSteps = 4; // Total de pasos.

  // 2) Pregunta 1 – Slider de distracción
  // El valor del slider, entre 1.0 (poca distracción) y 4.0 (mucha).
  double _distractionLevel = 2.0;

  // 3) Pregunta 2 – Selección múltiple
  final List<String> _reminderOptions = ['Vibración', 'Sonido suave', 'Notificación visual', 'Widget'];
  // Lista booleana para saber qué recordatorios ha seleccionado el usuario.
  final List<bool> _selectedReminders = [false, false, false, false];

  // 4) Pregunta 3 – Selección excluyente
  String _selectedGoalLength = 'Cortas (25-30 min)'; // Opción por defecto.
  final List<String> _goalOptions = ['Cortas (25-30 min)', 'Más largas (45-60 min)'];

// 5) Pregunta 4 – Avatar (excluyente)
final List<Map<String, dynamic>> _avatarOptions = [
  {'name': 'Neutrón', 'icon': Icons.scatter_plot, 'color': Colors.amber},
  {'name': 'Zorro',  'icon': Icons.pets, 'color': Colors.deepOrange},
  {'name': 'Koala',  'icon': Icons.park, 'color': Colors.grey},
  {'name': 'Panda',  'icon': Icons.spa, 'color': Colors.lightGreen},
];
  String _selectedAvatar = 'Neutrón'; // Opción por defecto.


  // --- Lógica de navegación del test ---

  // Avanza al siguiente paso.
  void _goToNextStep() {
    setState(() {
      if (_currentStep < _totalSteps) {
        _currentStep++;
      } else {
        // Al final del test, navega a la HomeScreen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  // Regresa al paso anterior.
  void _goToPreviousStep() {
    setState(() {
      if (_currentStep > 1) {
        _currentStep--;
      }
    });
  }

  // Actualiza el estado del slider (Pregunta 1).
  void _updateDistractionLevel(double value) {
    setState(() {
      _distractionLevel = value;
    });
  }

  // Actualiza el estado de los recordatorios (Pregunta 2).
  void _toggleReminder(int index) {
    setState(() {
      _selectedReminders[index] = !_selectedReminders[index];
    });
  }

  // Actualiza el estado del largo de metas (Pregunta 3).
  void _selectGoalLength(String value) {
    setState(() {
      _selectedGoalLength = value;
    });
  }

  // Actualiza el estado del avatar (Pregunta 4).
  void _selectAvatar(String value) {
    setState(() {
      _selectedAvatar = value;
    });
  }


  @override
  Widget build(BuildContext context) {
    // Definimos el widget a mostrar según el paso actual.
    final Widget currentQuestion;
    final String title;

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
        // Caso por defecto (no debería ocurrir).
        title = 'Error';
        currentQuestion = const Center(child: Text('Cargando...'));
        break;
    }

    return Scaffold(
      // La barra de navegación inferior, aunque no se usa en el mockup del test.
      bottomNavigationBar: const CustomNavBar(),

      // Utilizamos un AppBar personalizado para mostrar el TestHeader.
      appBar: AppBar(
        // Centramos el TestHeader en el AppBar.
        title: TestHeader(tokens: 1200, rewards: 5),
        // Agregamos un botón de cierre que vuelve a la pantalla anterior
        // o a Onboarding si es la primera vez.
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de progreso (1/4).
            _buildProgressCard(),
            const SizedBox(height: 24),

            // Título de la pregunta actual.
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Widget de la pregunta actual.
            Expanded(child: currentQuestion),

            const SizedBox(height: 20),
            // Botones de navegación.
            _buildBackNextRow(),
          ],
        ),
      ),
    );
  }

  // --- Widgets específicos de cada paso ---

  // 1) Pregunta 1: Slider
  Widget _buildDistractionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto de ayuda.
        const Text(
          'Mueve el deslizador para indicar tu nivel de distracción:',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // Slider (control deslizante).
        Slider(
          value: _distractionLevel,
          min: 1.0,
          max: 4.0,
          // Muestra el valor como un número entero.
          divisions: 3,
          label: _distractionLevel.round().toString(),
          onChanged: _updateDistractionLevel,
          // Color de la pista del slider.
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 10),

        // Etiquetas del slider.
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

  // 2) Pregunta 2: Selección múltiple (Recordatorios)
  Widget _buildReminderOptions() {
    return ListView.builder(
      itemCount: _reminderOptions.length,
      itemBuilder: (context, index) {
        final option = _reminderOptions[index];
        final isSelected = _selectedReminders[index];
        return GestureDetector(
          onTap: () => _toggleReminder(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco().copyWith(
              // Uso de .withOpacity() es correcto aquí.
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                    ),
                  ),
                ),
                // Ícono de check para indicar la selección.
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3) Pregunta 3: Selección excluyente (Largo de metas)
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
              // Uso de .withOpacity() es correcto aquí.
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                    ),
                  ),
                ),
                // Ícono de radio button para selección excluyente.
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 4) Pregunta 4: Avatar (Selección excluyente con ícono)
  Widget _buildAvatarOptions() {
    return GridView.builder(
      // Desactiva el scrolling ya que el Column exterior lo manejará.
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5, // Proporción de aspecto de los ítems.
      ),
      itemCount: _avatarOptions.length,
      itemBuilder: (context, index) {
        final option = _avatarOptions[index];
        final isSelected = _selectedAvatar == option['name'];

        // ✅ CORRECCIÓN: Conversión explícita para evitar advertencia de obsoleto.
        final Color optionColor = option['color'] as Color; 

        return GestureDetector(
          onTap: () => _selectAvatar(option['name']),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco().copyWith(
              // Uso correcto de .withOpacity() con el tipo Color garantizado.
              color: isSelected ? optionColor.withOpacity(0.1) : Colors.white, 
              border: isSelected
                  ? Border.all(color: optionColor, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono del avatar.
                Icon(
                  option['icon'] as IconData,
                  size: 32,
                  color: optionColor, // Usamos la variable local
                ),
                const SizedBox(height: 8),
                // Nombre del avatar.
                Text(
                  option['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // lib/screens/test_initial_screen.dart (reemplaza el método existente)

// Tarjeta de progreso (1/4) - ¡VERSIÓN MEJORADA!
Widget _buildProgressCard() {
  return Container(
    // Padding: Espacio interno para que el contenido no esté pegado a los bordes.
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    
    // Decoration: Aquí definimos la apariencia de la tarjeta.
    decoration: BoxDecoration(
      // Usamos un color azul claro, similar al mockup.
      color: const Color(0xFFE3F2FD), // Un tono de azul muy claro
      // Bordes redondeados para la tarjeta.
      borderRadius: BorderRadius.circular(12),
    ),
    
    child: Column(
      // Alinea todo el contenido a la izquierda.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la tarjeta.
        const Text(
          'Test inicial (rápido)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold, // Letra en negrita como en el mockup
            color: Colors.black87,
          ),
        ),
        
        // Espacio vertical pequeño.
        const SizedBox(height: 4),
        
        // Texto de ayuda.
        const Text(
          'Ayúdanos a adaptar la app a tu estilo. 1-2 minutos.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),

        // Espacio vertical más grande antes de la barra.
        const SizedBox(height: 8),

        // Barra de progreso.
        LinearProgressIndicator(
          // El valor se calcula dinámicamente: paso_actual / total_pasos.
          value: _currentStep / _totalSteps,
          
          // Color de fondo de la barra (la parte "vacía").
          backgroundColor: Colors.blue.withOpacity(0.2),
          
          // Color principal de la barra (la parte "llena").
          color: Colors.blue, // Un azul más vibrante
          
          // Grosor de la barra.
          minHeight: 8,
          
          // Hacemos que la barra de progreso también tenga bordes redondeados.
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ),
  );
}

  // Botoneras reutilizables (Atrás/Siguiente/Listo)
  Row _buildBackNextRow() {
    return Row(children: [
      // Botón Atrás (OutlinedButton).
      Expanded(child: _outlined('Atrás', _goToPreviousStep, disabled: _currentStep == 1)),
      const SizedBox(width: 10),

      // Botón Siguiente o Listo (ElevatedButton).
      Expanded(
        child: _filled(
            _currentStep < _totalSteps ? 'Siguiente' : 'Listo',
            _goToNextStep),
      ),
    ]);
  }

  // Widget auxiliar para OutlinedButton.
  OutlinedButton _outlined(String label, VoidCallback onPressed, {required bool disabled}) => OutlinedButton(
        onPressed: disabled ? null : onPressed, // Deshabilita si es el primer paso.
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: BorderSide(color: disabled ? Colors.grey.shade200 : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 16, 
          color: disabled ? Colors.grey : Colors.black87
        )),
      );

  // Widget auxiliar para ElevatedButton.
  ElevatedButton _filled(String label, VoidCallback onPressed) => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      );

  // Decoración común de tarjetas
  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // Uso de .withOpacity() es correcto aquí.
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5)],
      );
}