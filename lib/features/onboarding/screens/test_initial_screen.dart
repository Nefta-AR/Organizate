// ============================================================
// lib/features/onboarding/screens/test_initial_screen.dart
// ============================================================
// Test de configuración inicial de 4 pasos para nuevos usuarios.
//
// ## Pasos del test
//
//   1. Nivel de distracción (Slider 1-4): ¿te distraes con facilidad?
//   2. Recordatorios preferidos (multi-select): vibración, sonido,
//      notificación visual, widget.
//   3. Duración de metas (radio): cortas (25-30 min) o largas (45-60 min).
//   4. Avatar inicial (cuadrícula 4x2): 8 opciones de personaje.
//
// ## Al completar el paso 4
//
//   [_goToNextStep] guarda en Firestore (merge:true):
//     - `hasCompletedOnboarding: true` → AuthGate no mostrará este test de nuevo.
//     - `avatar, distractionLevel, preferredReminders, goalLength` → prefs del usuario.
//     - `points: 1200` → recompensa de bienvenida.
//
//   Luego navega a WelcomeRewardScreen con pushReplacement (sin retorno al test).
//
// ## Ruta de llegada
//
//   AuthGate (hasCompletedOnboarding == false) → TestInitialScreen
//             → WelcomeRewardScreen → HomeScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/test_header.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../../tda_focus/screens/welcome_reward_screen.dart';

class TestInitialScreen extends StatefulWidget {
  const TestInitialScreen({super.key});

  @override
  State<TestInitialScreen> createState() => _TestInitialScreenState();
}

class _TestInitialScreenState extends State<TestInitialScreen> {
  // Paso actual del wizard (1-4). Controla qué pregunta se muestra.
  int _currentStep = 1;
  static const int _totalSteps = 4; // Total de preguntas del test

  // ── Estado del Paso 1: Nivel de distracción ───────────────────────────────
  // Slider discreto de 1.0 a 4.0 con 3 divisiones. 2.0 = nivel medio por defecto.
  double _distractionLevel = 2.0;

  // ── Estado del Paso 2: Tipos de recordatorio preferidos ──────────────────
  // Lista de opciones de recordatorio mostradas como tarjetas seleccionables
  final List<String> _reminderOptions = [
    'Vibración',
    'Sonido suave',
    'Notificación visual',
    'Widget',
  ];
  // Estado de selección de cada opción (multi-select, índice correlacionado con _reminderOptions)
  final List<bool> _selectedReminders = [false, false, false, false];

  // ── Estado del Paso 3: Duración de metas ─────────────────────────────────
  // Opción seleccionada actualmente (radio button, solo una a la vez)
  String _selectedGoalLength = 'Cortas (25-30 min)';
  // Las dos opciones disponibles para la duración del ciclo Pomodoro
  final List<String> _goalOptions = [
    'Cortas (25-30 min)',
    'Más largas (45-60 min)',
  ];

  // ── Estado del Paso 4: Selección de avatar ───────────────────────────────
  // 8 avatares disponibles: cada Map tiene label (visible), value (key en Firestore) e image (asset)
  final List<Map<String, String>> _avatarOptions = [
    {'label': 'Emoticon', 'value': 'emoticon',  'image': 'assets/avatars/emoticon.png'},
    {'label': 'Zorro',    'value': 'zorro',     'image': 'assets/avatars/zorro.png'},
    {'label': 'Koala',    'value': 'koala',     'image': 'assets/avatars/koala.png'},
    {'label': 'Panda',    'value': 'panda',     'image': 'assets/avatars/panda.png'},
    {'label': 'Tigre',    'value': 'tigre',     'image': 'assets/avatars/tigre.png'},
    {'label': 'Rana',     'value': 'rana',      'image': 'assets/avatars/rana.png'},
    {'label': 'Pinguino', 'value': 'pinguino',  'image': 'assets/avatars/pinguino.png'},
    {'label': 'Unicornio','value': 'unicornio', 'image': 'assets/avatars/unicornio.png'},
  ];
  // Avatar seleccionado actualmente (su 'value' se guarda en Firestore)
  String _selectedAvatar = 'emoticon';

  // ── Navegación del wizard ─────────────────────────────────────────────────

  /// Avanza al siguiente paso. Si ya estamos en el último paso, guarda en Firestore
  /// y navega a WelcomeRewardScreen.
  Future<void> _goToNextStep() async {
    // Si no es el último paso, solo incrementamos el contador de paso
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
      return;
    }

    // Último paso: mostramos un spinner no dismissible mientras guardamos
    showDialog(
      context: context,
      barrierDismissible: false, // El usuario no puede cerrar el spinner manualmente
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Referencia al documento del usuario autenticado actual
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      // Construimos la lista de recordatorios seleccionados por el usuario
      // Usamos un for collection con guard para filtrar los no seleccionados
      final selectedReminderNames = <String>[
        for (int i = 0; i < _selectedReminders.length; i++)
          if (_selectedReminders[i]) _reminderOptions[i],
      ];

      // Guardamos todas las preferencias con merge:true para no sobreescribir
      // otros campos del documento (ej: fcmTokens, role, etc.)
      await userDocRef.set({
        'hasCompletedOnboarding': true,            // Marca el test como completado
        'avatar':                 _selectedAvatar,  // Identificador del avatar elegido
        'distractionLevel':       _distractionLevel.round(), // 1-4, entero
        'preferredReminders':     selectedReminderNames,     // Lista de nombres de recordatorio
        'goalLength':             _selectedGoalLength,        // '25-30 min' o '45-60 min'
        'points':                 1200,            // Recompensa de bienvenida
      }, SetOptions(merge: true));

      // Éxito: cerramos el spinner y navegamos a la pantalla de recompensa
      if (mounted) {
        Navigator.of(context).pop(); // Cierra el diálogo spinner
        Navigator.pushReplacement(
          context,
          // pushReplacement: evita que el usuario vuelva al test con el botón Atrás
          MaterialPageRoute(builder: (_) => const WelcomeRewardScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Cierra el spinner aunque haya error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar. Intenta de nuevo.')),
        );
      }
    }
  }

  /// Retrocede al paso anterior. No hace nada si ya estamos en el paso 1.
  void _goToPreviousStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  // ── Callbacks de actualización de estado (paso a paso) ────────────────────

  /// Actualiza el nivel de distracción al mover el Slider.
  void _updateDistractionLevel(double v) =>
      setState(() => _distractionLevel = v);

  /// Alterna la selección del recordatorio en el índice [i].
  void _toggleReminder(int i) =>
      setState(() => _selectedReminders[i] = !_selectedReminders[i]);

  /// Establece la duración de meta seleccionada.
  void _selectGoalLength(String v) => setState(() => _selectedGoalLength = v);

  /// Establece el avatar seleccionado (por su 'value').
  void _selectAvatar(String v) => setState(() => _selectedAvatar = v);

  // ── Build principal ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Usamos el patrón de desestructuración de registros de Dart 3.
    // Cada paso devuelve un tuple (título, widget de contenido).
    final (String title, Widget question) = switch (_currentStep) {
      1 => ('¿Te distraes con facilidad?', _buildDistractionSlider()),
      2 => ('¿Qué recordatorios prefieres?', _buildReminderOptions()),
      3 => ('¿Metas cortas o largas?', _buildGoalOptions()),
      4 => ('Elige un avatar inicial', _buildAvatarOptions()),
      _ => ('Error', const Center(child: Text('Cargando...'))),
    };

    return Scaffold(
      appBar: AppBar(
        // AppHeader muestra el nombre de la app y contadores de gamificación
        title: const AppHeader(tokens: 1200, rewards: 5),
        // El botón de cierre permite saltar el test (AuthGate redirigirá de nuevo si aplica)
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.maybePop(context), // maybePop: no falla si no hay ruta anterior
        ),
      ),
      bottomNavigationBar: const CustomNavBar(), // Barra de navegación persistente
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta de progreso: barra lineal que muestra el avance en los 4 pasos
            _buildProgressCard(),
            const SizedBox(height: 24),

            // Título de la pregunta actual (alineado a la izquierda)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Contenido de la pregunta (ocupa el espacio disponible)
            Expanded(child: question),

            // Fila de botones Atrás / Siguiente en la parte inferior
            _buildBackNextRow(),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de progreso con barra lineal ──────────────────────────────────

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Azul muy claro (Material Blue 50)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test inicial (rápido)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ayúdanos a adaptar la app a tu estilo. 1-2 minutos.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          // Barra de progreso: _currentStep / _totalSteps (0.25 → 0.50 → 0.75 → 1.0)
          LinearProgressIndicator(
            value: _currentStep / _totalSteps,
            backgroundColor: Colors.blue.withAlpha(51), // 20% de opacidad
            color: Colors.blueAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // ── Paso 1: Slider de nivel de distracción ────────────────────────────────

  Widget _buildDistractionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mueve el deslizador...',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        // Emojis como etiquetas visuales de los 4 niveles del slider
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🙂', style: TextStyle(fontSize: 30)), // Nivel 1: poca distracción
              Text('😐', style: TextStyle(fontSize: 30)), // Nivel 2: media
              Text('🤯', style: TextStyle(fontSize: 30)), // Nivel 3: alta
              Text('🛸', style: TextStyle(fontSize: 30)), // Nivel 4: extrema
            ],
          ),
        ),
        // Slider de 1 a 4 con 3 divisiones (4 posiciones discretas)
        Slider(
          value:     _distractionLevel,
          min:       1.0,
          max:       4.0,
          divisions: 3, // Divide en 4 posiciones: 1, 2, 3, 4
          label:     _distractionLevel.round().toString(), // Tooltip con el valor actual
          onChanged: _updateDistractionLevel,
        ),
        // Etiquetas extremas del slider
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Muy poca', style: TextStyle(fontSize: 14)),
            Text('Mucha',    style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  // ── Paso 2: Selector múltiple de tipos de recordatorio ────────────────────

  Widget _buildReminderOptions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos el ancho de cada tarjeta para 2 columnas con 16px de separación
        final itemWidth = (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing:    16, // Separación horizontal entre tarjetas
          runSpacing: 16, // Separación vertical entre filas
          children: List.generate(_reminderOptions.length, (index) {
            final isSelected = _selectedReminders[index]; // ¿Está esta opción seleccionada?
            return GestureDetector(
              onTap: () => _toggleReminder(index), // Alterna la selección al tocar
              child: Container(
                width:   itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                decoration: BoxDecoration(
                  // Fondo azul claro cuando está seleccionado, blanco cuando no
                  color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // Borde azul al seleccionar, gris suave al no estar seleccionado
                    color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      // Ícono más intenso cuando está seleccionado
                      color: isSelected ? Colors.amber.shade700 : Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _reminderOptions[index], // Nombre del tipo de recordatorio
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color:      isSelected ? Colors.blueAccent : Colors.black87,
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

  // ── Paso 3: Radio buttons de duración de meta ─────────────────────────────

  Widget _buildGoalOptions() {
    return Column(
      children: _goalOptions.map((option) {
        final isSelected = _selectedGoalLength == option; // ¿Es la opción actualmente elegida?
        return GestureDetector(
          onTap: () => _selectGoalLength(option), // Selecciona esta opción
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco().copyWith(
              // Fondo levemente azul cuando está seleccionada
              color: isSelected
                  ? Theme.of(context).primaryColor.withAlpha(25) // 10% de opacidad
                  : Colors.white,
              border: Border.all(
                // Borde del color primario al seleccionar, gris al no seleccionar
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize:   16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                // Ícono de radio button (lleno o vacío según selección)
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Paso 4: Cuadrícula de avatares 4x2 ───────────────────────────────────

  Widget _buildAvatarOptions() {
    return GridView.builder(
      // NeverScrollableScrollPhysics: el scroll lo maneja el Column exterior
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   4,  // 4 columnas → 4x2 para los 8 avatares
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
      ),
      itemCount: _avatarOptions.length,
      itemBuilder: (context, index) {
        final option     = _avatarOptions[index];
        final isSelected = _selectedAvatar == option['value']; // ¿Es el avatar elegido?
        return GestureDetector(
          onTap: () => _selectAvatar(option['value']!), // Selecciona este avatar
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: _cardDeco().copyWith(
              // Fondo azul translúcido cuando está seleccionado
              color: isSelected ? Colors.blue.withAlpha(38) : Colors.white, // ~15% opacidad
              border: Border.all(
                // Borde azul acento y más grueso al seleccionar
                color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                width: 2.5, // Borde más grueso que en otras tarjetas (feedback visual fuerte)
              ),
            ),
            // Imagen del avatar (PNG en assets/avatars/)
            child: Image.asset(option['image']!),
          ),
        );
      },
    );
  }

  // ── Fila de botones Atrás / Siguiente ─────────────────────────────────────

  Row _buildBackNextRow() {
    return Row(
      children: [
        // El botón "Atrás" solo aparece desde el paso 2 en adelante
        if (_currentStep > 1) ...[
          Expanded(child: _outlined('Atrás', _goToPreviousStep)),
          const SizedBox(width: 16),
        ],
        // El botón principal dice "Siguiente" hasta el último paso, donde dice "Listo"
        Expanded(
          child: _filled(
            _currentStep < _totalSteps ? 'Siguiente' : 'Listo',
            _goToNextStep,
          ),
        ),
      ],
    );
  }

  // ── Helpers de botones ────────────────────────────────────────────────────

  /// Botón con borde (estilo outlined) para la acción secundaria (Atrás).
  Widget _outlined(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side:    BorderSide(color: Colors.grey.shade300),
        shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  /// Botón relleno azul para la acción principal (Siguiente / Listo).
  Widget _filled(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding:         const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF0099FF), // Azul primario de la app
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation:       0, // Sin sombra para apariencia flat
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // ── Decoración base de tarjetas ───────────────────────────────────────────

  /// BoxDecoration base para las tarjetas de opciones (pasos 3 y 4).
  /// Se extiende con copyWith en cada uso para personalizar color y borde.
  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color:       Colors.grey.withAlpha(25), // Sombra muy suave (10% opacidad)
          spreadRadius: 1,
          blurRadius:   5,
        ),
      ],
    );
  }
}
