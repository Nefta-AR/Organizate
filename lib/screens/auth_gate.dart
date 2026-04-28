import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:organizate/screens/home_screen.dart';
import 'package:organizate/screens/login_screen.dart';
import 'package:organizate/screens/onboarding_screen.dart';
import 'package:organizate/screens/role_selection_screen.dart';
import 'package:organizate/services/push_notification_service.dart';

/// Punto de entrada de navegación tras autenticación.
/// Úsalo como destino en pushAndRemoveUntil tanto en logout como post-login.
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
        final hasCompleted = data?['hasCompletedOnboarding'] == true;

        if (role == null || role.isEmpty) return const RoleSelectionScreen();
        return hasCompleted ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }
}
