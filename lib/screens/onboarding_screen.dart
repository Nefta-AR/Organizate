// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'test_initial_screen.dart'; // <-- CORREGIDO: Ruta directa

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( child: Padding( padding: const EdgeInsets.symmetric(horizontal: 40.0), child: Column( mainAxisSize: MainAxisSize.min, children: [
              // Asegúrate de tener tu logo en assets/images/logo.png y registrado en pubspec.yaml
              Image.asset( 'assets/images/logo.png', width: 150, height: 150, ),
              const SizedBox(height: 32),
              const Text('Organízate', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              const Text('Simplicidad, motivación...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => const TestInitialScreen()), ), // Navega al Test
                style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 56), backgroundColor: const Color(0xFF0099FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, ),
                child: const Text('Comenzar • Test inicial', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, )),
              ),
              const SizedBox(height: 16),
              const Text('Visual, amigable...', style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}