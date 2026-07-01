// ============================================================
// lib/features/tda_focus/screens/welcome_reward_screen.dart
// ============================================================
// Pantalla de bienvenida que se muestra al finalizar el onboarding.
//
// Presenta:
//   - Mensaje de felicitaciones con animación de confetti (emoji).
//   - Confirmación de que el usuario ganó 1200 puntos iniciales
//     (los puntos se guardan en Firestore desde TestInitialScreen).
//   - Botón que navega a HomeScreen con pushReplacement para
//     que el usuario no pueda volver al flujo de onboarding.
//
// Ruta de llegada: TestInitialScreen → WelcomeRewardScreen → HomeScreen
// ============================================================

import 'package:flutter/material.dart';
import '../../tutor_dashboard/screens/home_screen.dart';

/// Pantalla de recompensa al completar el onboarding inicial.
class WelcomeRewardScreen extends StatelessWidget {
  const WelcomeRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mensaje principal de felicitaciones
              const Text(
                '🎉 ¡Felicitaciones! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Explicación del puntaje ganado durante el test inicial
              const Text(
                'Has completado la configuración inicial y ganado tus primeros 1200 puntos.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 18, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 50),
              // Botón de acción principal → reemplaza la pila de navegación
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0099FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Comenzar el día',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
