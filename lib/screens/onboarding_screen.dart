// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
// Importamos la barra de navegación (aunque el mockup la tiene, se podría quitar en Onboarding).
import '../widgets/custom_nav_bar.dart';
// Importamos la siguiente pantalla (el Test Inicial).
import 'test_initial_screen.dart';

/// Pantalla de bienvenida (mockup) + CTA para ir al Test Inicial.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Agregamos la barra de navegación inferior.
      bottomNavigationBar: const CustomNavBar(),
      body: Center(
        child: Column(
          // Centra verticalmente el contenido.
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo/Isotipo simple en stack (azul + acento)
            Stack(
              alignment: Alignment.center,
              children: [
                // Contenedor de fondo con color secundario (Verde agua) con opacidad.
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    // CORRECCIÓN: Usamos .withOpacity(0.2) para la opacidad del fondo.
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                // Icono principal (en este caso un check box).
                Icon(
                  Icons.check_box_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                // Icono de acento (un rayo) posicionado arriba a la derecha.
                Positioned(
                  right: 15,
                  top: 15,
                  child: Icon(Icons.flash_on, size: 25, color: Colors.amber.shade400),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Título principal.
            const Text(
              'Simplicidad, motivación, y concentración,\nTodo en una sola app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            // Botón de Llamada a la Acción (CTA).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  // Navega a la pantalla del test y reemplaza la actual (para no poder volver).
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TestInitialScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  // Ancho máximo disponible (double.infinity).
                  minimumSize: const Size(double.infinity, 56),
                  // Color principal del tema.
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
            ),
            const SizedBox(height: 16),
            // Texto secundario debajo del botón.
            const Text(
              'Visual, amigable y sin sobrecarga',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
