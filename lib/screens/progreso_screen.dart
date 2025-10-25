import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Asegúrate que flutter pub add intl funcionó
import 'package:organizate/widgets/custom_nav_bar.dart'; // Verifica ruta
import 'package:organizate/screens/estudios_screen.dart';
import 'package:organizate/screens/hogar_screen.dart';
import 'package:organizate/screens/meds_screen.dart';
import 'package:organizate/screens/foco_screen.dart';

class ProgresoScreen extends StatelessWidget {
  const ProgresoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'), // <-- CAMBIA ESTO EN CADA ARCHIVO
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBar: const CustomNavBar(), // Mantenemos la barra abajo
      body: const Center(
        // Mensaje temporal
        child: Text('Pantalla de Progreso - Próximamente'),
      ),
    );
  }
}