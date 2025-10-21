// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'test_initial_screen.dart'; // Importamos la siguiente pantalla

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ¡ARREGLADO! ---
    // Quitamos la barra de navegación (bottomNavigationBar)
    // para que coincida 100% con el mockup.
    return Scaffold(
      body: Center(
        // Añadimos un padding lateral
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Centra verticalmente
            children: [
              
              // --- 1. ¡TU LOGO NUEVO! ---
              // Reemplazamos el Stack temporal por tu imagen.
              // Asegúrate de que la ruta sea correcta.
              Image.asset(
                'assets/images/Logo.png',
                width: 150, // Ajusta el tamaño como prefieras
                height: 150,
              ),
              const SizedBox(height: 32),

              // --- 2. TÍTULO "ORGANÍZATE" (¡Añadido!) ---
              const Text(
                'Organízate',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Color oscuro, como pediste
                ),
              ),
              const SizedBox(height: 16),

              // --- 3. SUBTÍTULO ---
              const Text(
                'Simplicidad, motivación, y concentración,\nTodo en una sola app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 40),

              // --- 4. BOTÓN DE INICIO ---
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TestInitialScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  // --- ¡COLOR CORREGIDO! ---
                  // Usamos el azul vibrante del mockup.
                  backgroundColor: const Color(0xFF0099FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Comenzar • Test inicial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- 5. TEXTO SECUNDARIO ---
              const Text(
                'Visual, amigable y sin sobrecarga',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}