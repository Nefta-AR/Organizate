// lib/router/app_router.dart
import 'package:flutter/material.dart';

// IMPORTA TUS PANTALLAS AQUÍ (ajusta las rutas reales de tus archivos)
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import '../features/progress/progress_screen.dart';

/// Clase que centraliza nombres y construcción de rutas.
/// Usamos constantes para evitar errores de escritura.
class AppRouter {
  // Nombres de rutas públicos y reutilizables
  static const String onboarding = '/onboarding';
  static const String home       = '/home';
  static const String tasks      = '/tasks';
  static const String pomodoro   = '/pomodoro';
  static const String progress   = '/progress';

  /// onGenerateRoute se invoca cada vez que haces pushNamed(...)
  /// Aquí decides qué pantalla construir según settings.name.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _fade(const OnboardingScreen(), settings);
      case home:
        return _fade(const HomeScreen(), settings);
      case tasks:
        return _slideLeft(const TasksScreen(), settings);
      case pomodoro:
        return _slideLeft(const PomodoroScreen(), settings);
      case progress:
        return _slideLeft(const ProgressScreen(), settings);

      default:
        // Ruta desconocida → fallback seguro
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
    }
  }

  // ====== Transiciones bonitas (opcionales) ======
  static PageRoute _fade(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  static PageRoute _slideLeft(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final offset = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(anim);
        return SlideTransition(position: offset, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

