import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

// Paleta idéntica a login_screen.dart para coherencia visual total.
class _Palette {
  _Palette._();
  static const background = Color(0xFFF0F4F8);
  static const primary    = Color(0xFF607D8B);
  static const textDark   = Color(0xFF37474F);
  static const textMuted  = Color(0xFF78909C);
}

const double _kRadius = 20;

// ─────────────────────────────────────────────────────────────────────────────
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Guarda qué tarjeta está cargando; null = ninguna.
  String? _loadingRole;

  Future<void> _selectRole(String role) async {
    if (_loadingRole != null) return;
    setState(() => _loadingRole = role);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Sin usuario autenticado');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'role': role}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tu perfil. Intenta de nuevo.'),
        ),
      );
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

              // ── Encabezado ───────────────────────────────────────────────
              const Text(
                '¿Cómo usarás\nOrganízate hoy?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize  : 30,
                  fontWeight: FontWeight.bold,
                  color     : _Palette.primary,
                  height    : 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Elige tu perfil para personalizar\ntu experiencia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color   : _Palette.textMuted,
                  height  : 1.5,
                ),
              ),

              const Spacer(),

              // ── Tarjetas de rol ──────────────────────────────────────────
              _RoleCard(
                role       : 'estudiante',
                label      : 'Estudiante',
                description: 'Organiza tareas, horarios y estudios',
                icon       : Icons.school_rounded,
                cardColor  : const Color(0xFFEDF2F7),
                accentColor: const Color(0xFF7EA3BC),
                isLoading  : _loadingRole == 'estudiante',
                isDisabled : _loadingRole != null,
                onTap      : () => _selectRole('estudiante'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role       : 'cuidador',
                label      : 'Cuidador',
                description: 'Acompaña y supervisa\na quien cuidas',
                icon       : Icons.favorite_rounded,
                cardColor  : const Color(0xFFEEF5F1),
                accentColor: const Color(0xFF7DA88A),
                isLoading  : _loadingRole == 'cuidador',
                isDisabled : _loadingRole != null,
                onTap      : () => _selectRole('cuidador'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role       : 'paciente',
                label      : 'Paciente',
                description: 'Gestiona medicación,\ncitas y bienestar',
                icon       : Icons.accessibility_new_rounded,
                cardColor  : const Color(0xFFF1EEF6),
                accentColor: const Color(0xFF9B8DB2),
                isLoading  : _loadingRole == 'paciente',
                isDisabled : _loadingRole != null,
                onTap      : () => _selectRole('paciente'),
              ),

              const Spacer(),

              // ── Nota al pie ──────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de rol — widget privado para mantener el build legible.
// ─────────────────────────────────────────────────────────────────────────────
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

  final String       role;
  final String       label;
  final String       description;
  final IconData     icon;
  final Color        cardColor;
  final Color        accentColor;
  final bool         isLoading;
  final bool         isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity : isDisabled && !isLoading ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color       : cardColor,
        borderRadius: BorderRadius.circular(_kRadius),
        child: InkWell(
          onTap       : isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(_kRadius),
          child: Container(
            width  : double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // ── Icono con fondo ──────────────────────────────────────
                Container(
                  width : 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color       : accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color      : accentColor,
                          ),
                        )
                      : Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 20),

                // ── Texto ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize  : 18,
                          fontWeight: FontWeight.w700,
                          color     : accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color   : _Palette.textDark,
                          height  : 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Flecha ───────────────────────────────────────────────
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size : 16,
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
