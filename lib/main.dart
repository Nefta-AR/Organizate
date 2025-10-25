// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Añade Firestore aquí
import 'firebase_options.dart';
import 'package:organizate/screens/onboarding_screen.dart';
import 'package:organizate/screens/home_screen.dart'; // <-- Añade HomeScreen aquí
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);

  // --- ¡NUEVA LÓGICA DE INICIO! ---
  Widget initialScreen; // Variable para decidir qué pantalla mostrar

  try {
    // Referencia a tu documento de usuario
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc('neftali_user')
        .get();

    // Revisa si el documento existe y si has completado el onboarding
    if (userDoc.exists && (userDoc.data() as Map<String, dynamic>?)?['hasCompletedOnboarding'] == true) {
      // Si ya completaste, ve directo al HomeScreen
      initialScreen = const HomeScreen();
    } else {
      // Si no, empieza por el Onboarding
      initialScreen = const OnboardingScreen();
    }
  } catch (e) {
    // Si hay error leyendo Firestore (ej. sin conexión la primera vez),
    // muestra el Onboarding por seguridad.
    print("Error al verificar onboarding: $e");
    initialScreen = const OnboardingScreen();
  }
  // --- FIN NUEVA LÓGICA ---

  // Ejecuta la app con la pantalla inicial decidida
  runApp(MyApp(initialScreen: initialScreen)); // <-- Pasa la pantalla inicial a MyApp
}

class MyApp extends StatelessWidget {
  // --- NUEVO: Recibe la pantalla inicial ---
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});
  // --- FIN NUEVO ---

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Organízate',
      theme: ThemeData( /* ... tu tema ... */ ),
      // --- ¡CAMBIO! Usa la pantalla inicial que decidimos en main() ---
      home: initialScreen,
    );
  }
}