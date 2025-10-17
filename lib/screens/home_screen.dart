// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
// Importamos el servicio para leer el nombre guardado.
import '../services/user_prefs.dart';
// Importamos la barra de navegación personalizada.
import '../widgets/custom_nav_bar.dart';

// Función para generar un saludo basado en la hora del día.
String greetingForNow(DateTime now) {
  final h = now.hour;
  // 5 am a 11:59 am
  if (h >= 5 && h < 12) return 'Buenos días';
  // 12 pm a 6:59 pm
  if (h >= 12 && h < 19) return 'Buenas tardes';
  // 7 pm a 4:59 am
  return 'Buenas noches';
}

/// Pantalla principal de la aplicación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Función asíncrona para cargar el nombre del usuario de las preferencias.
  Future<String> _loadName() async {
    final name = await UserPrefs.getName();
    // Si no hay nombre guardado, usa 'Invitado'.
    return (name == null || name.isEmpty) ? 'Invitado' : name;
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el saludo del momento.
    final saludo = greetingForNow(DateTime.now());

    return Scaffold(
      // AppBar simple con el título de la aplicación.
      appBar: AppBar(title: const Text('Organízate')),
      // Añadimos la barra de navegación inferior.
      bottomNavigationBar: const CustomNavBar(),

      // FutureBuilder espera a que el Future (_loadName) termine
      // antes de construir su contenido (para obtener el nombre).
      body: FutureBuilder<String>(
        future: _loadName(),
        builder: (context, snap) {
          // Si los datos no han llegado (está cargando), muestra un indicador.
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Obtenemos el nombre guardado.
          final nombre = snap.data!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo con el nombre y un emoji.
                Text('$saludo, $nombre 👋',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),

                // Mensaje secundario.
                Text('Listo para enfocarte hoy?',
                    // CORRECCIÓN: Usamos .withOpacity(0.6) para la opacidad.
                    style: TextStyle(color: Colors.black.withOpacity(0.6))),

                const SizedBox(height: 24),
                // Espacio para tu contenido de tarjetas, acciones, etc.
                const Expanded(child: SizedBox()),
              ],
            ),
          );
        },
      ),
    );
  }
}
