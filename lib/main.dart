// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:organizate/screens/onboarding_screen.dart'; // Tu pantalla de inicio

// --- ¡NUEVO! Importa el paquete intl ---
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- ¡NUEVO! Inicializa el formato de fecha para español ---
  // El 'es' es suficiente si tu sistema operativo ya maneja 'es_ES'
  // Si no, puedes probar con 'es_ES'.
  await initializeDateFormatting('es', null);
  // --- FIN NUEVO ---

  runApp(const MyApp()); // Ejecuta la app DESPUÉS de inicializar
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
      home: const OnboardingScreen(),
    );
  }
}