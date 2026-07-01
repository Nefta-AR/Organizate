// ============================================================
// lib/main.dart  —  Punto de entrada de la aplicación Simple
// ============================================================
// Orden de inicialización:
//   1. Flutter bindings
//   2. Firebase (Auth + Firestore + FCM + Storage)
//   3. Handler de mensajes FCM en background (debe registrarse ANTES del runApp)
//   4. Localización de fechas en español
//   5. Notificaciones locales (flutter_local_notifications)
//   6. Token FCM del dispositivo (PushNotificationService)
//   7. Árbol de widgets con MultiProvider + MaterialApp
// ============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/navigation/auth_gate.dart';
import 'core/services/notification_service.dart';
import 'features/tda_focus/services/pomodoro_service.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  // Garantiza que los bindings de Flutter estén listos antes de cualquier
  // llamada nativa (Firebase, plugins). Siempre debe ser la primera línea.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones generadas por flutterfire configure.
  // DefaultFirebaseOptions selecciona automáticamente la configuración
  // correcta según la plataforma (Android / iOS / Web).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registra el handler de mensajes FCM cuando la app está en background o
  // terminada. DEBE registrarse en el nivel top-level (fuera de cualquier
  // clase) y ANTES de runApp para que Firebase pueda invocarla en un isolate
  // separado sin contexto Flutter.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializa los símbolos de localización en español para que intl
  // pueda formatear fechas con nombres de días y meses en castellano.
  await initializeDateFormatting('es', null);

  // Configura el canal de notificaciones locales y solicita permiso al
  // usuario (necesario en iOS y Android 13+).
  await NotificationService.init();
  await NotificationService.requestPermissions();

  // Obtiene y almacena el token FCM del dispositivo en Firestore para
  // que Cloud Functions puedan enviar notificaciones push dirigidas.
  await PushNotificationService.initialize();

  // Envuelve la app en MultiProvider para inyectar PomodoroService
  // como ChangeNotifier accesible en todo el árbol de widgets.
  runApp(
    MultiProvider(
      providers: [
        // PomodoroService necesita existir durante toda la sesión para
        // que el temporizador persista al navegar entre pantallas.
        ChangeNotifierProvider<PomodoroService>(
          create: (_) => PomodoroService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget raíz de la aplicación. No contiene lógica de negocio —
/// solo configura el tema, localización y la ruta inicial (AuthGate).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta el banner rojo de "DEBUG" en la esquina de la pantalla.
      debugShowCheckedModeBanner: false,
      title: 'Simple',
      theme: ThemeData(
        // Paleta base generada desde el azul terapéutico principal.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        useMaterial3: true,
      ),
      // Delegados de localización: habilitan formatos de fecha, hora y
      // textos de Material/Cupertino en el locale activo.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Locales soportados. Flutter usará 'es' si el dispositivo está
      // configurado en español; 'en' como fallback.
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      // AuthGate actúa como punto de decisión de navegación:
      // muestra LoginScreen, OnboardingScreen o HomeScreen según el
      // estado de Firebase Auth y el documento Firestore del usuario.
      home: const AuthGate(),
    );
  }
}
