// lib/core/navigation/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:simple/features/tutor_dashboard/screens/home_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_supervise_screen.dart';
import 'package:simple/features/auth/screens/login_screen.dart';
import 'package:simple/features/auth/screens/role_selection_screen.dart';
import 'package:simple/features/auth/screens/profile_setup_screen.dart';
import 'package:simple/features/tea_board/screens/pantalla_paciente_tea.dart';
import 'package:simple/core/services/push_notification_service.dart';

/// Punto de entrada del árbol de widgets post-MaterialApp.
///
/// Implementa una máquina de estados de navegación de tres niveles:
///
///   1. [AuthGate]             → ¿hay sesión activa de Firebase?
///   2. [_UserOnboardingGate]  → ¿tiene rol y perfil configurados?
///   3. [RoleDispatcher]       → ¿qué pantalla corresponde al rol?
///
/// Cada nivel usa un [StreamBuilder] independiente para que los cambios
/// en Firebase Auth y en Firestore disparen reconstrucciones aisladas
/// sin reiniciar el árbol completo.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // authStateChanges emite null al logout y User al login/token-refresh
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error de autenticación')),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return _UserOnboardingGate(user: user);
      },
    );
  }
}

/// Segundo nivel del gate: verifica que el usuario tenga rol y perfil
/// antes de enviarlo a su pantalla definitiva.
///
/// El stream se abre sobre el documento del usuario en Firestore para
/// reaccionar en tiempo real si el tutor cambia el rol o si el usuario
/// completa el setup de perfil desde otro dispositivo.
///
/// También sincroniza el token FCM al montarse, lo que garantiza que
/// las notificaciones push estén vinculadas al dispositivo actual.
class _UserOnboardingGate extends StatefulWidget {
  const _UserOnboardingGate({required this.user});
  final User user;

  @override
  State<_UserOnboardingGate> createState() => _UserOnboardingGateState();
}

class _UserOnboardingGateState extends State<_UserOnboardingGate> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream;

  @override
  void initState() {
    super.initState();
    // Sincroniza el token FCM del dispositivo actual. Se hace aquí y no en
    // main() para tener acceso al uid del usuario ya autenticado.
    PushNotificationService.syncUserToken(widget.user);
    _userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error al cargar usuario')),
          );
        }
        final data = snapshot.data?.data();
        final role = data?['role'] as String?;

        // Sin rol → el usuario acaba de registrarse con Google o hay un
        // documento corrupto. Forzar selección de rol.
        if (role == null || role.isEmpty) return const RoleSelectionScreen();

        // Sin nombre → el usuario no completó el setup de perfil.
        // `hasCompletedProfile` es la fuente de verdad; `name` es el fallback
        // por si el campo booleano no existe en documentos antiguos.
        final hasProfile = data?['hasCompletedProfile'] as bool? ?? false;
        final hasName = (data?['name'] as String? ?? '').isNotEmpty;
        if (!hasProfile && !hasName) return const ProfileSetupScreen();

        return RoleDispatcher(role: role);
      },
    );
  }
}

/// Tercer nivel: despacha al widget raíz correspondiente al rol.
///
/// Usa un `switch` exhaustivo para que agregar un nuevo rol en el futuro
/// produzca un warning del compilador si no se maneja el caso.
/// Los roles legacy (`paciente_tea`) se mantienen como alias temporales
/// hasta que todos los usuarios migren automáticamente via [AuthService].
class RoleDispatcher extends StatelessWidget {
  final String role;

  const RoleDispatcher({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      'tutor'        => const TutorSupervisarScreen(),
      'usuario_tea'  => const PantallaPacienteTEA(),
      'paciente_tea' => const PantallaPacienteTEA(), // alias legacy → migrar vía AuthService
      _              => const HomeScreen(),           // tutor_tdah, usuario_general, usuario_tdah
    };
  }
}
