import 'package:flutter/material.dart';

import '../../features/auth/screens/paciente_vinculacion_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String pacienteTea = '/paciente-tea';
  static const String vincularPaciente = '/vincular-paciente';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _fade(const OnboardingScreen(), settings);
      case home:
        return _fade(const HomeScreen(), settings);
      case pacienteTea:
        return _fade(const PantallaPacienteTEA(), settings);
      case vincularPaciente:
        return _fade(const PacienteVinculacionScreen(), settings);
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
