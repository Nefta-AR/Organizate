// main.dart

// --- 1. IMPORTACIONES ---
// Estas son las "cajas de herramientas" que necesitamos para que el archivo funcione.

// Importa el paquete principal de Flutter para poder usar los widgets de Material Design (botones, texto, etc.).
import 'package:flutter/material.dart';

// Importa el paquete principal de Firebase para poder inicializar la conexión.
import 'package:firebase_core/firebase_core.dart';

// Importa el archivo que se generó automáticamente con las "llaves" de tu proyecto de Firebase.
import 'firebase_options.dart';

// ¡ESTA ES LA LÍNEA MÁS IMPORTANTE!
// Importa el archivo de tu pantalla del Test Inicial para que `main.dart` sepa que existe.
// Asegúrate de que el nombre del archivo y la ruta ('screens/test_initial_screen.dart') sean correctos.
import 'package:organizate/screens/test_initial_screen.dart';


// --- 2. FUNCIÓN PRINCIPAL ---
// Esta es la puerta de entrada de TODA tu aplicación. Es lo primero que se ejecuta.
Future<void> main() async {

  // Esta línea es obligatoria. Se asegura de que Flutter esté listo para funcionar
  // antes de intentar conectar con servicios externos como Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Esta es la línea que conecta tu app con tu proyecto de Firebase en la nube.
  // La palabra 'await' hace que la app espere a que la conexión se complete antes de continuar.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Una vez que Firebase está conectado, esta línea le dice a Flutter que empiece
  // a dibujar la aplicación en la pantalla, ejecutando el widget `MyApp`.
  runApp(const MyApp());
}


// --- 3. WIDGET RAÍZ DE LA APLICACIÓN ---
// `MyApp` es el widget principal que contiene toda tu aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // El método `build` es el que se encarga de dibujar la interfaz.
  @override
  Widget build(BuildContext context) {

    // `MaterialApp` es el widget que le da a tu aplicación el estilo estándar de
    // Android (Material Design). Aquí configuras cosas generales.
    return MaterialApp(
      // Quita la molesta cinta de "DEBUG" que aparece en la esquina superior derecha.
      debugShowCheckedModeBanner: false,

      // El título de tu aplicación (se usa en el administrador de tareas del teléfono).
      title: 'Organízate',

      // Aquí podrías configurar los colores y temas de toda tu app. Por ahora lo dejamos simple.
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // --- ¡AQUÍ ESTÁ LA MAGIA! ---
      // La propiedad `home` define cuál será la PRIMERA pantalla que el usuario verá.
      // En lugar de un simple texto, ahora le estamos diciendo que la pantalla de inicio
      // debe ser el widget `TestInitialScreen` que tú creaste.
      home: const TestInitialScreen(),
    );
  }
}