// ============================================================
// lib/core/navigation/auth_gate.dart  —  Máquina de estados de navegación
// ============================================================
// Implementa tres niveles de decisión, cada uno reactivo a un stream:
//
//   Nivel 1 — AuthGate
//     └─ StreamBuilder<User?> sobre FirebaseAuth.authStateChanges()
//        • Spinner mientras carga
//        • LoginScreen si no hay sesión
//        • _UserOnboardingGate si hay sesión activa
//
//   Nivel 2 — _UserOnboardingGate
//     └─ StreamBuilder<DocumentSnapshot> sobre users/{uid}
//        • Spinner si el documento aún no existe
//        • RoleSelectionScreen si role == null o hasCompletedOnboarding == false
//        • ProfileSetupScreen si hasCompletedProfile == false Y name vacío
//        • RoleDispatcher en cualquier otro caso
//
//   Nivel 3 — RoleDispatcher
//     └─ switch(role):  'tutor' → TutorSupervisarScreen
//                       '_'     → HomeScreen
//
// El patrón de usar StreamBuilder en lugar de Navigator.push garantiza
// que cualquier cambio en Firestore (p. ej. el tutor activa una cuenta)
// se refleje inmediatamente sin que el usuario deba cerrar sesión.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:simple/features/tutor_dashboard/screens/home_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_supervise_screen.dart';
import 'package:simple/features/auth/screens/login_screen.dart';
import 'package:simple/features/auth/screens/privacy_consent_screen.dart';
import 'package:simple/features/auth/screens/role_selection_screen.dart';
import 'package:simple/features/auth/screens/profile_setup_screen.dart';
import 'package:simple/core/services/privacy_policy_service.dart';
import 'package:simple/core/services/push_notification_service.dart';

/// Nivel 1 — Verifica si hay sesión activa de Firebase Auth.
///
/// Se declara como StatefulWidget (no StatelessWidget) aunque no tiene estado
/// propio, para poder cachear el stream en initState y evitar que un rebuild
/// del padre cree un nuevo StreamBuilder desde cero.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Stream cacheado para que no se reinicie en cada rebuild.
  // authStateChanges() emite: null (sin sesión) o User (con sesión).
  late final Stream<User?> _authStream =
      FirebaseAuth.instance.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Estado inicial antes del primer evento: muestra spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Error inesperado en el stream de Auth (raro, pero posible en entornos sin red).
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error de autenticación')),
          );
        }
        final user = snapshot.data;
        // Sin sesión: muestra pantalla de login.
        if (user == null) return const LoginScreen();
        // Con sesión: delega al segundo nivel para verificar onboarding y perfil.
        return _UserOnboardingGate(user: user);
      },
    );
  }
}

/// Nivel 2 — Verifica el estado del documento Firestore del usuario.
///
/// Se separa de AuthGate para aislar los rebuilds: un cambio en el stream
/// de Auth (p. ej. token refresh) no reconstruye innecesariamente este widget
/// si el usuario sigue siendo el mismo.
class _UserOnboardingGate extends StatefulWidget {
  const _UserOnboardingGate({required this.user});
  final User user;

  @override
  State<_UserOnboardingGate> createState() => _UserOnboardingGateState();
}

class _UserOnboardingGateState extends State<_UserOnboardingGate> {
  static const Duration _pushTokenRetryCooldown = Duration(seconds: 30);

  bool _syncedPushToken = false;
  bool _syncingPushToken = false;
  DateTime? _lastPushTokenSyncAttempt;

  @override
  void didUpdateWidget(covariant _UserOnboardingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _syncedPushToken = false;
      _syncingPushToken = false;
      _lastPushTokenSyncAttempt = null;
    }
  }

  Future<void> _syncPushTokenOnce() async {
    if (_syncedPushToken || _syncingPushToken) return;

    final now = DateTime.now();
    final lastAttempt = _lastPushTokenSyncAttempt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < _pushTokenRetryCooldown) {
      return;
    }

    _lastPushTokenSyncAttempt = now;
    _syncingPushToken = true;
    try {
      await PushNotificationService.syncUserToken(widget.user);
      if (!mounted) return;
      setState(() {
        _syncedPushToken = true;
      });
    } catch (error) {
      debugPrint('[PUSH] No se pudo sincronizar token FCM: $error');
    } finally {
      if (mounted) {
        setState(() {
          _syncingPushToken = false;
        });
      } else {
        _syncingPushToken = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      // Escucha en tiempo real el documento del usuario para reaccionar
      // a cambios (rol asignado, perfil completado, etc.) sin reiniciar la app.
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // El documento aún no llegó o no existe: muestra spinner.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data()!;

        // Cumplimiento legal MVP: antes de entrar a la app, el usuario debe
        // aceptar la version vigente de la Politica de Privacidad.
        if (!PrivacyPolicyService.hasAcceptedCurrentPolicy(data)) {
          return const PrivacyConsentScreen();
        }

        // Privacidad por diseno: el token FCM se registra solo despues
        // de aceptar la Politica de Privacidad vigente.
        if (!_syncedPushToken && !_syncingPushToken) {
          _syncPushTokenOnce();
        }
        // Campo 'role' determina el flujo: null/vacío → selección de rol.
        final role = data['role'] as String?;

        if (role == null || role.isEmpty) {
          return const RoleSelectionScreen();
        }

        // Si no completó el onboarding (selección de rol), redirige aunque
        // tenga un rol en Firestore (puede ser un rol heredado de versión anterior).
        final hasOnboarded = data['hasCompletedOnboarding'] as bool? ?? false;
        if (!hasOnboarded) {
          return const RoleSelectionScreen();
        }

        // Si no tiene perfil completo y tampoco nombre, pide configurar el perfil.
        // La condición doble (hasCompletedProfile Y name vacío) maneja el caso
        // donde el campo existe pero el nombre quedó vacío por un error previo.
        final hasProfile = data['hasCompletedProfile'] as bool? ?? false;
        final hasName   = (data['name'] as String? ?? '').isNotEmpty;
        if (!hasProfile && !hasName) {
          return const ProfileSetupScreen();
        }

        // Todo en orden: despacha a la pantalla raíz según el rol.
        return RoleDispatcher(role: role);
      },
    );
  }
}

/// Nivel 3 — Selecciona el widget raíz según el rol Firestore del usuario.
///
/// Es StatelessWidget porque no necesita estado ni streams propios;
/// solo toma el rol ya resuelto y retorna el widget correspondiente.
class RoleDispatcher extends StatelessWidget {
  final String role;

  const RoleDispatcher({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // switch expression de Dart 3: retorna directamente sin break/return.
    return switch (role) {
      'tutor' => const TutorSupervisarScreen(), // Panel de supervisión del tutor
      _       => const HomeScreen(),            // Pantalla principal del usuario (rol 'usuario')
    };
  }
}
