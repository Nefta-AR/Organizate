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
      // Sin AppBar: pantalla totalmente limpia para la bienvenida
      body: Center(
        // Center posiciona el Column en el centro exacto del viewport
        child: Padding(
          // 40 px horizontales para que el contenido no toque los bordes
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            // min evita que la Column ocupe toda la altura,
            // dejando que Center la coloque en el medio
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Logo ────────────────────────────────────────────
              Image.asset(
                'assets/images/Logo.png', // imagen local en el bundle de assets
                width: 150,               // ancho fijo para coherencia entre pantallas
                height: 150,              // alto fijo igual al ancho → cuadrado
              ),

              const SizedBox(height: 32), // separación entre logo y título

              // ── Nombre de la app ─────────────────────────────────
              const Text(
                'Simple',
                style: TextStyle(
                  fontSize: 32,                     // título grande y prominente
                  fontWeight: FontWeight.bold,       // negrita para impacto visual
                  color: Colors.black87,             // negro suave (no puro) para suavizar contraste
                ),
              ),

              const SizedBox(height: 16), // separación entre título y tagline

              // ── Tagline principal ────────────────────────────────
              const Text(
                'Simplicidad, motivación...',
                textAlign: TextAlign.center, // centrado cuando el texto ocupa varias líneas
                style: TextStyle(
                  fontSize: 16,        // tamaño de cuerpo de texto secundario
                  color: Colors.black54, // gris medio para jerarquía visual (menos prominente que el título)
                  height: 1.5,         // interlineado 1.5× para legibilidad (accesibilidad TEA/TDAH)
                ),
              ),

              const SizedBox(height: 40), // separación amplia antes del botón para respirar el layout

              // ── Botón principal ──────────────────────────────────
              ElevatedButton(
                // pushReplacement elimina OnboardingScreen del stack de navegación,
                // evitando que el usuario pueda volver a esta pantalla con "Atrás"
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TestInitialScreen(), // destino: wizard de configuración inicial
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56), // ancho completo y 56 px de alto (área táctil accesible)
                  backgroundColor: const Color(0xFF0099FF),     // azul primario de la app
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),    // bordes redondeados → estética amigable TEA
                  ),
                  elevation: 0, // sin sombra → apariencia plana coherente con Material 3
                ),
                child: const Text(
                  'Comenzar · Test inicial',
                  style: TextStyle(
                    fontSize: 18,              // texto grande para fácil lectura
                    fontWeight: FontWeight.bold, // negrita para que destaque sobre el fondo azul
                    color: Colors.white,        // blanco sobre azul → contraste WCAG AA
                  ),
                ),
              ),

              const SizedBox(height: 16), // separación entre botón y texto secundario

              // ── Texto de apoyo inferior ──────────────────────────
              const Text(
                'Visual, amigable...',
                style: TextStyle(
                  fontSize: 14,          // tamaño pequeño para indicar que es texto de apoyo
                  color: Colors.black54, // gris medio para no competir con el botón
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
