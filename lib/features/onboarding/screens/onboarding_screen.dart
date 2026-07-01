// ============================================================
// lib/features/onboarding/screens/onboarding_screen.dart
// ============================================================
// Pantalla de bienvenida inicial (splash de primer uso).
//
// Es la primera pantalla que ve el usuario al completar el
// registro pero antes de configurar su perfil. Muestra:
//   - Logo de la app.
//   - Nombre "Simple".
//   - Tagline motivacional.
//   - Botón que lanza el test inicial de configuración.
//
// Ruta: AuthGate → OnboardingScreen → TestInitialScreen
// ============================================================

import 'package:flutter/material.dart';
import 'test_initial_screen.dart';

/// Pantalla de bienvenida para nuevos usuarios (primer uso).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo de la app
              Image.asset('assets/images/Logo.png', width: 150, height: 150),
              const SizedBox(height: 32),
              // Nombre de la app
              const Text(
                'Simple',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Tagline principal
              const Text(
                'Simplicidad, motivación...',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 40),
              // Botón de inicio → reemplaza la navegación para que no haya "Atrás"
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TestInitialScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF0099FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Comenzar · Test inicial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Texto secundario debajo del botón
              const Text(
                'Visual, amigable...',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
