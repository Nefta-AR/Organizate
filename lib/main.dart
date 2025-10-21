// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- ¡CAMBIO AQUÍ! ---
// 1. Importamos la nueva pantalla de bienvenida.
import 'package:organizate/screens/onboarding_screen.dart';
// (Ya no necesitamos importar test_initial_screen.dart aquí)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Organízate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      
      // --- ¡CAMBIO AQUÍ! ---
      // 2. Esta es ahora la primera pantalla que verá el usuario.
      home: const OnboardingScreen(),
    );
  }
}