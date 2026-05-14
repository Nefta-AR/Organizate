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

        if (role == null || role.isEmpty) return const RoleSelectionScreen();

        final hasProfile = data?['hasCompletedProfile'] as bool? ?? false;
        final hasName = (data?['name'] as String? ?? '').isNotEmpty;
        if (!hasProfile && !hasName) return const ProfileSetupScreen();

        return RoleDispatcher(role: role);
      },
    );
  }
}

class RoleDispatcher extends StatelessWidget {
  final String role;

  const RoleDispatcher({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      'tutor' => const TutorSupervisarScreen(),
      'paciente_tea' => const PantallaPacienteTEA(),
      _ => const HomeScreen(),
    };
  }
}
