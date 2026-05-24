// lib/core/navigation/auth_gate.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:simple/features/tutor_dashboard/screens/home_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_supervise_screen.dart';
import 'package:simple/features/auth/screens/login_screen.dart';
import 'package:simple/features/auth/screens/role_selection_screen.dart';
import 'package:simple/features/auth/screens/profile_setup_screen.dart';
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

/// Segundo nivel del gate: espera el documento Firestore del usuario y
/// navega imperativamente a la pantalla correcta una única vez.
///
/// Usa una suscripción directa al stream (no StreamBuilder) para evitar
/// que los eventos rápidos del stream durante el registro causen parpadeo
/// de pantallas. El widget siempre muestra un spinner; la navegación se
/// dispara desde el callback del stream, no desde build().
///
/// También sincroniza el token FCM al montarse.
class _UserOnboardingGate extends StatefulWidget {
  const _UserOnboardingGate({required this.user});
  final User user;

  @override
  State<_UserOnboardingGate> createState() => _UserOnboardingGateState();
}

class _UserOnboardingGateState extends State<_UserOnboardingGate> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  // Evita navegar más de una vez aunque el stream emita varios eventos.
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    PushNotificationService.syncUserToken(widget.user);
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen(_onDoc);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onDoc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted || _navigating) return;

    // Doc aún no existe (write en curso tras registro) — esperar.
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final role = data['role'] as String?;

    final Widget destination;
    if (role == null || role.isEmpty) {
      destination = const RoleSelectionScreen();
    } else {
      final hasOnboarded = data['hasCompletedOnboarding'] as bool? ?? false;
      if (!hasOnboarded) {
        // El usuario aún no ha elegido su rol (recién registrado).
        destination = const RoleSelectionScreen();
      } else {
        final hasProfile = data['hasCompletedProfile'] as bool? ?? false;
        final hasName   = (data['name'] as String? ?? '').isNotEmpty;
        if (!hasProfile && !hasName) {
          destination = const ProfileSetupScreen();
        } else {
          destination = RoleDispatcher(role: role);
        }
      }
    }

    _navigating = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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
