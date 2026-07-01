// ============================================================
// lib/core/router/app_router.dart  —  Rutas nombradas de la app
// ============================================================
// Define las 4 rutas con nombre que pueden ser invocadas con
// Navigator.pushNamed(context, AppRouter.home).
//
// Todas las rutas usan una transición FadeTransition de 200 ms
// en lugar del slide por defecto de MaterialPageRoute.
// Esto es deliberado: las transiciones suaves reducen la carga
// perceptual para usuarios con TEA y TDAH.
//
// IMPORTANTE: AuthGate NO usa este router. El despacho inicial
// (Login → Onboarding → Home/Tutor) ocurre dentro de AuthGate
// mediante StreamBuilder reactivo, no mediante rutas nombradas.
// ============================================================

import 'package:flutter/material.dart';

import '../../features/auth/screens/vinculacion_tutor_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';

class AppRouter {
  // Constantes de nombre de ruta para evitar strings mágicos dispersos en el código.
  static const String onboarding    = '/onboarding';       // Pantalla de bienvenida
  static const String home          = '/home';             // Pantalla principal del usuario
  static const String usuarioTea    = '/usuario-tea';      // Tablero AAC para TEA
  static const String vincularUsuario = '/vincular-usuario'; // Formulario de código de invitación

  /// Fábrica de rutas invocada por MaterialApp.onGenerateRoute.
  /// Retorna una ruta con FadeTransition o, si el nombre no existe,
  /// redirige a OnboardingScreen como fallback seguro.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _fade(const OnboardingScreen(), settings);
      case home:
        return _fade(const HomeScreen(), settings);
      case usuarioTea:
        return _fade(const PantallaUsuarioTEA(), settings);
      case vincularUsuario:
        return _fade(const VinculacionTutorScreen(), settings);
      default:
        // Ruta desconocida → regresa al onboarding en lugar de lanzar excepción.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );
    }
  }

  /// Construye un PageRouteBuilder con FadeTransition de 200 ms.
  ///
  /// [s] se pasa para preservar los argumentos de la ruta original
  /// (RouteSettings.arguments) al widget destino.
  static PageRoute _fade(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      // pageBuilder devuelve el widget sin animación propia; la animación
      // se aplica en transitionsBuilder.
      pageBuilder: (_, __, ___) => page,
      // FadeTransition usa el Animation<double> del router (0.0 → 1.0).
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
