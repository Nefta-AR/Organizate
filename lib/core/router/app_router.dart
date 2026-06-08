import 'package:flutter/material.dart';

import '../../features/auth/screens/vinculacion_tutor_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String usuarioTea = '/usuario-tea';
  static const String vincularUsuario = '/vincular-usuario';

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
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );
    }
  }

  static PageRoute _fade(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
