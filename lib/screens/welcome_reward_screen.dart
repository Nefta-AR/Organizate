// lib/screens/welcome_reward_screen.dart (Placeholder)
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Para navegar al Dashboard

class WelcomeRewardScreen extends StatelessWidget {
  const WelcomeRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding( // Añadido Padding para que no esté pegado a los bordes
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉 ¡Felicitaciones! 🎉',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), // Más grande
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24), // Más espacio
              const Text(
                'Has completado la configuración inicial y ganado tus primeros 1200 puntos.',
                style: TextStyle(fontSize: 18, color: Colors.black54, height: 1.5), // Mejor interlineado
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50), // Más espacio
              ElevatedButton(
                onPressed: () {
                  // Navega al HomeScreen reemplazando esta pantalla
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF0099FF), // Azul
                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), // Más padding
                   minimumSize: const Size(double.infinity, 56), // Ancho completo
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordes
                   elevation: 0,
                   textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                 ),
                child: const Text('Comenzar el día', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}