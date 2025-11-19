// lib/screens/test_initial_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_nav_bar.dart'; // Asegúrate que la ruta sea correcta
import '../widgets/test_header.dart'; // Asegúrate que la ruta sea correcta
import 'welcome_reward_screen.dart'; // Importamos la pantalla de bienvenida

class TestInitialScreen extends StatefulWidget {
  const TestInitialScreen({super.key});

  @override
  State<TestInitialScreen> createState() => _TestInitialScreenState();
}

class _TestInitialScreenState extends State<TestInitialScreen> {
  // --- Variables de Estado (CORRECTAS para ESTA pantalla) ---
  int _currentStep = 1;
  final int _totalSteps = 4;
  double _distractionLevel = 2.0;
  final List<String> _reminderOptions = ['Vibración', 'Sonido suave', 'Notificación visual', 'Widget'];
  final List<bool> _selectedReminders = [false, false, false, false];
  String _selectedGoalLength = 'Cortas (25-30 min)';
  final List<String> _goalOptions = ['Cortas (25-30 min)', 'Más largas (45-60 min)'];
  final List<Map<String, String>> _avatarOptions = [
    {'label': 'Emoticon', 'value': 'emoticon', 'image': 'assets/avatars/emoticon.png'},
    {'label': 'Zorro', 'value': 'zorro', 'image': 'assets/avatars/zorro.png'},
    {'label': 'Koala', 'value': 'koala', 'image': 'assets/avatars/koala.png'},
    {'label': 'Panda', 'value': 'panda', 'image': 'assets/avatars/panda.png'},
    {'label': 'Tigre', 'value': 'tigre', 'image': 'assets/avatars/tigre.png'},
    {'label': 'Rana', 'value': 'rana', 'image': 'assets/avatars/rana.png'},
    {'label': 'Pinguino', 'value': 'pinguino', 'image': 'assets/avatars/pinguino.png'},
    {'label': 'Unicornio', 'value': 'unicornio', 'image': 'assets/avatars/unicornio.png'},
  ];
  String _selectedAvatar = 'emoticon';

  // --- Funciones de Navegación y Guardado (CORRECTAS para ESTA pantalla) ---
  void _goToNextStep() async {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      showDialog( context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()), );
      try {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
        List<String> selectedReminderNames = [];
        for (int i = 0; i < _selectedReminders.length; i++) {
          if (_selectedReminders[i]) selectedReminderNames.add(_reminderOptions[i]);
        }
        final testResults = {
          'hasCompletedOnboarding': true, 'avatar': _selectedAvatar,
          'distractionLevel': _distractionLevel.round(),
          'preferredReminders': selectedReminderNames, 'goalLength': _selectedGoalLength,
          'points': 1200, // Puntos iniciales
        };
        await userDocRef.set(testResults, SetOptions(merge: true));
        debugPrint('Resultados del test guardados!');

        if (mounted) {
           Navigator.of(context).pop(); // Cierra loading
           Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => const WelcomeRewardScreen()), ); // Navega a Bienvenida
        }
      } catch (e) {
        debugPrint('Error al guardar: $e');
        if (mounted) {
            Navigator.of(context).pop(); // Cierra loading
            ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error al guardar. Intenta de nuevo.')) );
        }
      }
    }
  }

  void _goToPreviousStep() { setState(() { if (_currentStep > 1) _currentStep--; }); }
  void _updateDistractionLevel(double v) { setState(() => _distractionLevel = v); }
  void _toggleReminder(int i) { setState(() => _selectedReminders[i] = !_selectedReminders[i]); }
  void _selectGoalLength(String v) { setState(() => _selectedGoalLength = v); }
  void _selectAvatar(String v) { setState(() => _selectedAvatar = v); }

  // --- Build Principal ---
  @override
  Widget build(BuildContext context) {
    Widget currentQuestion; String title;
    switch (_currentStep) {
      case 1: title = '¿Te distraes con facilidad?'; currentQuestion = _buildDistractionSlider(); break;
      case 2: title = '¿Qué recordatorios prefieres?'; currentQuestion = _buildReminderOptions(); break;
      case 3: title = '¿Metas cortas o largas?'; currentQuestion = _buildGoalOptions(); break;
      case 4: title = 'Elige un avatar inicial'; currentQuestion = _buildAvatarOptions(); break;
      default: title = 'Error'; currentQuestion = const Center(child: Text('Cargando...')); break;
    }

    return Scaffold(
      appBar: AppBar( title: const TestHeader(tokens: 1200, rewards: 5), leading: IconButton( icon: const Icon(Icons.close), onPressed: () => Navigator.maybePop(context), ), ),
      bottomNavigationBar: const CustomNavBar(),
      body: Padding( // <-- Padding CORRECTO
        padding: const EdgeInsets.all(20.0), // <-- Con 'padding:'
        child: Column( children: [
            _buildProgressCard(),
            const SizedBox(height: 24),
            Align( alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Expanded(child: currentQuestion),
            _buildBackNextRow(), // <-- Llamada correcta
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES para UI (CORREGIDOS Y COMPLETOS) ---

  Widget _buildProgressCard() {
    return Container( padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration( color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text('Test inicial (rápido)', style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), const Text('Ayúdanos a adaptar la app a tu estilo. 1-2 minutos.', style: TextStyle(fontSize: 14, color: Colors.black54)), const SizedBox(height: 8), LinearProgressIndicator( value: _currentStep / _totalSteps, backgroundColor: Colors.blue.withAlpha(51), color: Colors.blueAccent, minHeight: 8, borderRadius: BorderRadius.circular(4), ), ], ), );
  }

  Widget _buildDistractionSlider() {
     return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text( 'Mueve el deslizador...', style: TextStyle(fontSize: 16, color: Colors.black54), ), const SizedBox(height: 16), const Padding( padding: EdgeInsets.symmetric(horizontal: 8.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text('🙂', style: TextStyle(fontSize: 30)), Text('😐', style: TextStyle(fontSize: 30)), Text('🤯', style: TextStyle(fontSize: 30)), Text('🛸', style: TextStyle(fontSize: 30)), ], ), ), Slider( value: _distractionLevel, min: 1.0, max: 4.0, divisions: 3, label: _distractionLevel.round().toString(), onChanged: _updateDistractionLevel, ), const Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text('Muy poca', style: TextStyle(fontSize: 14)), Text('Mucha', style: TextStyle(fontSize: 14)), ], ), ], );
  }

  Widget _buildReminderOptions() {
     return LayoutBuilder( builder: (context, constraints) { final itemWidth = (constraints.maxWidth - 16) / 2; return Wrap( spacing: 16, runSpacing: 16, children: List.generate(_reminderOptions.length, (index) { final option = _reminderOptions[index]; final isSelected = _selectedReminders[index]; return GestureDetector( onTap: () => _toggleReminder(index), child: Container( width: itemWidth, padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12), decoration: BoxDecoration( color: isSelected ? const Color(0xFFE3F2FD) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all( color: isSelected ? Colors.blueAccent : Colors.grey.shade200, width: 1.5, ), ), child: Column( children: [ Icon( Icons.notifications_outlined, color: isSelected ? Colors.amber.shade700 : Colors.amber, size: 28, ), const SizedBox(height: 12), Text( option, textAlign: TextAlign.center, style: TextStyle( fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blueAccent : Colors.black87, ), ), ], ), ), ); }), ); }, );
   }

  Widget _buildGoalOptions() {
    return Column( children: _goalOptions.map((option) { final isSelected = _selectedGoalLength == option; return GestureDetector( onTap: () => _selectGoalLength(option), child: Container( margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: _cardDeco().copyWith( color: isSelected ? Theme.of(context).primaryColor.withAlpha(25) : Colors.white, border: Border.all( color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200, width: 1.5, ), ), child: Row( children: [ Expanded( child: Text( option, style: TextStyle( fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, ), ), ), Icon( isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300, ), ], ), ), ); }).toList(), );
  }

  // --- CORREGIDO: Faltaban los parámetros obligatorios ---
  Widget _buildAvatarOptions() {
   return GridView.builder(
     physics: const NeverScrollableScrollPhysics(),
     // --- CORREGIDO ---
     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
       crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
     ),
     itemCount: _avatarOptions.length,
     // --- CORREGIDO ---
     itemBuilder: (context, index) {
       final option = _avatarOptions[index]; // No necesita '!' si la lista está bien definida
       final isSelected = _selectedAvatar == option['value'];
       return GestureDetector(
         onTap: () => _selectAvatar(option['value']!), // '!' aquí es seguro si name siempre existe
         child: Container(
           padding: const EdgeInsets.all(8),
           decoration: _cardDeco().copyWith(
             color: isSelected ? Colors.blue.withAlpha(38) : Colors.white,
             border: Border.all( color: isSelected ? Colors.blueAccent : Colors.grey.shade200, width: 2.5, ),
           ),
           child: Image.asset( option['image']!, ), // '!' aquí es seguro si image siempre existe
         ),
       );
     },
   );
 }

  // --- Métodos de botones y cardDeco (AHORA ESTÁN DENTRO) ---
  Row _buildBackNextRow() {
    return Row( children: [ if (_currentStep > 1) Expanded(child: _outlined('Atrás', _goToPreviousStep)), if (_currentStep > 1) const SizedBox(width: 16), Expanded( child: _filled( _currentStep < _totalSteps ? 'Siguiente' : 'Listo', _goToNextStep ), ), ], );
  }

  Widget _outlined(String label, VoidCallback onPressed) {
    return OutlinedButton( onPressed: onPressed, style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ), child: Text( label, style: const TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54, ), ), );
  }

  Widget _filled(String label, VoidCallback onPressed) {
    return ElevatedButton( onPressed: onPressed, style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF0099FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, ), child: Text( label, style: const TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, ), ), );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow( color: Colors.grey.withAlpha(25), spreadRadius: 1, blurRadius: 5, ) ], );
  }
} // ¡FIN DE LA CLASE _TestInitialScreenState!
