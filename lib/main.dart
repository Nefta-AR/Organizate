// Importa los paquetes necesarios
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Este archivo lo generó flutterfire

// La función principal, ahora es asíncrona para esperar a Firebase
Future<void> main() async {
  // Asegúrate de que los widgets de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase usando las opciones de la plataforma actual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Para quitar la cinta de "Debug"
      title: 'Organízate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Por ahora, mostraremos una pantalla de bienvenida simple
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Organízate'),
          backgroundColor: Colors.lightBlue,
        ),
        body: const Center(
          child: Text(
            '¡App conectada a Firebase!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}