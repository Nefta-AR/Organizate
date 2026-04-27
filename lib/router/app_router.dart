// lib/router/app_router.dart
import 'package:flutter/material.dart';

// --- ¡CORRECCIÓN! ---
// Importamos las pantallas desde sus rutas correctas en 'lib/screens/'
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';

// --- COMENTADOS ---
// Estas pantallas aún no existen, las activaremos cuando las creemos.
// import '../screens/tasks_screen.dart';
// import '../screens/pomodoro_screen.dart';
// import '../screens/progress_screen.dart';

class AppRouter {
  // Nombres de rutas públicos y reutilizables
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  
  // --- COMENTADOS ---
  // static const String tasks = '/tasks';
  // static const String pomodoro = '/pomodoro';
  // static const String progress = '/progress';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _fade(const OnboardingScreen(), settings);
      case home:
        return _fade(const HomeScreen(), settings);
      
      // --- RUTAS COMENTADAS ---
      // case tasks:
      //   return _slideLeft(const TasksScreen(), settings);
      // case pomodoro:
      //   return _slideLeft(const PomodoroScreen(), settings);
      // case progress:
      //   return _slideLeft(const ProgressScreen(), settings);

      default:
        // Ruta por defecto: Si no encuentra nada, envía al Onboarding.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );
    }
  }

  // Transición de Fade (esta sí la usamos)
  static PageRoute _fade(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  // --- COMENTADO ---
  // Esta transición no se usa por ahora, ya que comentamos las rutas que la usaban.
  // static PageRoute _slideLeft(Widget page, RouteSettings s) {
  //   return PageRouteBuilder(
  //     settings: s,
  //     pageBuilder: (_, __, ___) => page,
  //     transitionsBuilder: (_, anim, __, child) {
  //       const begin = Offset(1.0, 0.0);
  //       const end = Offset.zero;
  //       const curve = Curves.ease;
  //       final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  //       return SlideTransition(position: anim.drive(tween), child: child);
  //     },
  //     transitionDuration: const Duration(milliseconds: 200),
  //   );
  // }
}

