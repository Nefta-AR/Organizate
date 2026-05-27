// lib/core/navigation/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:simple/features/tutor_dashboard/screens/home_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_supervise_screen.dart';
import 'package:simple/features/auth/screens/login_screen.dart';
import 'package:simple/features/auth/screens/role_selection_screen.dart';
import 'package:simple/features/auth/screens/profile_setup_screen.dart';
import 'package:simple/core/services/push_notification_service.dart';
import 'package:simple/core/services/kiosk_mode_service.dart';

/// Punto de entrada del árbol de widgets post-MaterialApp.
///
/// Implementa una máquina de estados de navegación de tres niveles:
///
///   1. [AuthGate]             → ¿hay sesión activa de Firebase?
///   2. [_UserOnboardingGate]  → ¿tiene rol y onboarding completados?
///   3. [RoleDispatcher]       → ¿qué pantalla corresponde al rol?
///
/// Cada nivel usa un StreamBuilder independiente para que los cambios
/// en Firebase Auth y Firestore disparen reconstrucciones aisladas.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
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

/// Segundo nivel: lee el documento Firestore del usuario y retorna el widget
/// correcto de forma declarativa. Al no usar Navigator, no interfiere con el
/// historial del browser en Flutter web.
class _UserOnboardingGate extends StatefulWidget {
  const _UserOnboardingGate({required this.user});
  final User user;

  @override
  State<_UserOnboardingGate> createState() => _UserOnboardingGateState();
}

class _UserOnboardingGateState extends State<_UserOnboardingGate> {
  bool _kioskActivated = false;

  @override
  void initState() {
    super.initState();
    PushNotificationService.syncUserToken(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data()!;
        final role = data['role'] as String?;

        if (role == null || role.isEmpty) {
          return const RoleSelectionScreen();
        }

        final hasOnboarded = data['hasCompletedOnboarding'] as bool? ?? false;
        if (!hasOnboarded) {
          return const RoleSelectionScreen();
        }

        final hasProfile = data['hasCompletedProfile'] as bool? ?? false;
        final hasName   = (data['name'] as String? ?? '').isNotEmpty;
        if (!hasProfile && !hasName) {
          return const ProfileSetupScreen();
        }

        // Activar kiosk mode automáticamente si está habilitado en Firestore
        // y aún no se activó en esta sesión.
        final kioskEnabled = data['kioskModeEnabled'] as bool? ?? false;
        if (kioskEnabled && !_kioskActivated && role != 'tutor') {
          _kioskActivated = true;
          KioskModeService.enable(userId: widget.user.uid);
        }

        return RoleDispatcher(role: role);
      },
    );
  }
}

/// Tercer nivel: despacha al widget raíz correspondiente al rol.
class RoleDispatcher extends StatelessWidget {
  final String role;

  const RoleDispatcher({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      'tutor' => const TutorSupervisarScreen(),
      _       => const HomeScreen(), // 'usuario'
    };
  }
}
