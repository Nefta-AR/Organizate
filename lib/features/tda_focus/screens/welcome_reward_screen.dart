// lib/screens/welcome_reward_screen.dart

import 'package:flutter/material.dart';
import '../../tutor_dashboard/screens/home_screen.dart';

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
              const Text(
                '🎉 ¡Felicitaciones! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Has completado la configuración inicial y ganado tus primeros 1200 puntos.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 18, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 50),
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
