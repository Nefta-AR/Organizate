// ============================================================
// lib/features/auth/screens/role_selection_screen.dart
// ============================================================
// Pantalla de selección de rol: el usuario elige entre "Usuario"
// o "Tutor" la primera vez que entra a la app (o cuando su rol
// es null/vacío en Firestore).
//
// Flujo:
//   1. El usuario toca una tarjeta (_RoleCard).
//   2. _selectRole() llama a AuthService.setRole() para escribir
//      el rol en Firestore y marca hasCompletedOnboarding: true.
//   3. Se limpia el stack de navegación y se redirige a AuthGate,
//      que ahora re-evalúa el rol y navega a la pantalla correcta.
//
// Por qué se hace pushAndRemoveUntil a AuthGate en lugar de
// simplemente dejar que el StreamBuilder de AuthGate reaccione:
// RoleSelectionScreen está ENCIMA de AuthGate en el stack, así que
// aunque AuthGate se reconstruya debajo, el usuario seguiría viendo
// esta pantalla. Limpiar el stack garantiza que AuthGate esté visible.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple/core/navigation/auth_gate.dart';
import 'package:simple/core/services/auth_service.dart';

/// Paleta de colores interna de esta pantalla.
class _Palette {
  _Palette._();
  static const background = Color(0xFFF0F4F8); // Fondo azul-gris muy claro
  static const primary    = Color(0xFF607D8B); // Gris azulado principal
  static const textDark   = Color(0xFF37474F); // Texto oscuro
  static const textMuted  = Color(0xFF78909C); // Texto secundario gris
}

/// Radio estándar de bordes redondeados para tarjetas de rol.
const double _kRadius = 20;

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Almacena el rol que se está cargando para mostrar el spinner en esa tarjeta
  // y deshabilitar la otra tarjeta mientras dura la operación async.
  String? _loadingRole;

  /// Guarda el rol seleccionado en Firestore y redirige al AuthGate.
  Future<void> _selectRole(String role) async {
    // Evita doble tap si ya hay una operación en curso.
    if (_loadingRole != null) return;
    setState(() => _loadingRole = role);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Sin usuario autenticado');

      // Convierte el string del rol al enum UserRole para type-safety.
      final userRole = role == 'tutor' ? UserRole.tutor : UserRole.usuario;

      // Escribe el campo 'role' en el documento Firestore del usuario.
      await AuthService.setRole(userRole);

      // Marca el onboarding como completado para que AuthGate no vuelva a
      // mostrar esta pantalla en próximos inicios de sesión.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'hasCompletedOnboarding': true}, SetOptions(merge: true));

      // Limpia el stack completo y pone AuthGate como nueva raíz.
      // AuthGate detectará el nuevo rol via su StreamBuilder y navegará
      // a HomeScreen (usuario) o TutorSupervisarScreen (tutor).
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false, // Elimina TODAS las rutas previas
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tu perfil. Intenta de nuevo.'),
        ),
      );
      // Resetea para permitir reintentar.
      setState(() => _loadingRole = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // ── Título ───────────────────────────────────────────────
              const Text(
                '¿Cómo usarás\nSimple hoy?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _Palette.primary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Elige tu perfil para personalizar\ntu experiencia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _Palette.textMuted,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // ── Tarjeta "Usuario" ─────────────────────────────────────
              _RoleCard(
                role: 'usuario',
                label: 'Usuario',
                description:
                    'Organiza tu día, tareas y bienestar.\nPersonaliza tus pestañas desde Ajustes.',
                icon: Icons.person_rounded,
                cardColor: const Color(0xFFEDF2F7),   // Azul muy claro
                accentColor: const Color(0xFF7EA3BC), // Azul medio
                isLoading: _loadingRole == 'usuario', // Spinner si se está guardando este rol
                isDisabled: _loadingRole != null,     // Deshabilitado si se guarda el otro rol
                onTap: () => _selectRole('usuario'),
              ),
              const SizedBox(height: 16),

              // ── Tarjeta "Tutor" ───────────────────────────────────────
              _RoleCard(
                role: 'tutor',
                label: 'Tutor',
                description: 'Acompaña y supervisa\na quien cuidas',
                icon: Icons.favorite_rounded,
                cardColor: const Color(0xFFEEF5F1),   // Verde muy claro
                accentColor: const Color(0xFF7DA88A), // Verde medio
                isLoading: _loadingRole == 'tutor',
                isDisabled: _loadingRole != null,
                onTap: () => _selectRole('tutor'),
              ),
              const Spacer(),

              // ── Nota informativa al pie ──────────────────────────────
              const Text(
                'Puedes cambiarlo más adelante en Ajustes.',
                style: TextStyle(fontSize: 12, color: _Palette.textMuted),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de selección de rol con animaciones de opacidad y estado de carga.
///
/// Muestra un spinner en el ícono cuando [isLoading] es true, y reduce la
/// opacidad a 45% cuando está [isDisabled] pero no está cargando (la otra
/// tarjeta está siendo procesada).
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.cardColor,
    required this.accentColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final String role;
  final String label;
  final String description;
  final IconData icon;
  final Color cardColor;   // Color de fondo de la tarjeta
  final Color accentColor; // Color del ícono y texto del título
  final bool isLoading;    // True: muestra spinner en lugar del ícono
  final bool isDisabled;   // True: ignora taps (pero sigue visible)
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      // La tarjeta no activa se vuelve semitransparente durante la carga de la otra.
      opacity: isDisabled && !isLoading ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(_kRadius),
        child: InkWell(
          // Ripple effect; null deshabilita el tap.
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(_kRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              // Borde sutil del color de acento para dar identidad a la tarjeta.
              border: Border.all(
                color: accentColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // ── Ícono / Spinner ───────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    // Fondo traslúcido del color de acento.
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // Muestra spinner durante la carga, ícono en reposo.
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: accentColor,
                          ),
                        )
                      : Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 20),

                // ── Texto ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _Palette.textDark,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Flecha indicadora ────────────────────────────────
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accentColor.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
