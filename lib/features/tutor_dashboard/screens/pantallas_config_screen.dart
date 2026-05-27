import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple/core/services/auth_service.dart';
import 'package:simple/core/services/kiosk_mode_service.dart';

class _Palette {
  _Palette._();
  static const background = Color(0xFFF4F6F8);
  static const primary    = Color(0xFF607D8B);
  static const surface    = Colors.white;
  static const textDark   = Color(0xFF37474F);
  static const textMuted  = Color(0xFF78909C);
  static const accent     = Color(0xFF7EA3BC);
}

/// Pantalla de selección de pestañas visibles para el usuario.
///
/// Lee y escribe `users/{uid}/pictogramSettings/_features`.
/// Siempre debe quedar al menos una pestaña activa.
/// Si el usuario tiene tutor vinculado todos los switches se muestran
/// bloqueados — solo el tutor puede modificarlos desde su panel.
class PantallasConfigScreen extends StatelessWidget {
  const PantallasConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final featuresRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pictogramSettings')
        .doc('_features');

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        elevation: 0,
        title: const Text(
          'Personalización',
          style: TextStyle(
              color: _Palette.primary, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: _Palette.primary),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: AuthService.getLinkedTutorStream(),
        builder: (context, tutorSnap) {
          final hasTutor = tutorSnap.data != null;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: featuresRef.snapshots(),
            builder: (context, featSnap) {
              final data   = featSnap.data?.data() ?? {};
              final inicio = data['featureInicio']      as bool? ?? true;
              final tareas = data['featureTareas']      as bool? ?? true;
              final picto  = data['featurePictogramas'] as bool? ?? false;
              final foco   = data['featureFoco']        as bool? ?? true;
              final perfil = data['featurePerfil']      as bool? ?? true;

              final activeCount =
                  [inicio, tareas, picto, foco, perfil].where((v) => v).length;

              // Devuelve null (switch deshabilitado) si hay tutor o si esta
              // pestaña es la última activa.
              VoidCallback? guard(bool value, VoidCallback fn) =>
                  (hasTutor || (value && activeCount <= 1)) ? null : fn;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  const Text(
                    'Elige qué pestañas quieres ver en la app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Debe haber al menos una pestaña activa.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                  if (hasTutor) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _Palette.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 16,
                              color:
                                  _Palette.accent.withValues(alpha: 0.85)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tu tutor gestiona esta configuración',
                              style: TextStyle(
                                  fontSize: 13, color: _Palette.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _TabTile(
                    icon: Icons.home_rounded,
                    color: Colors.blue,
                    title: 'Inicio',
                    subtitle: 'Pantalla principal con resumen y motivación',
                    value: inicio,
                    locked: hasTutor || (inicio && activeCount <= 1),
                    onToggle: guard(
                      inicio,
                      () => featuresRef.set(
                        {'featureInicio': !inicio},
                        SetOptions(merge: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TabTile(
                    icon: Icons.task_alt,
                    color: Colors.green,
                    title: 'Tareas',
                    subtitle: 'Gestión de tareas y recordatorios',
                    value: tareas,
                    locked: hasTutor || (tareas && activeCount <= 1),
                    onToggle: guard(
                      tareas,
                      () => featuresRef.set(
                        {'featureTareas': !tareas},
                        SetOptions(merge: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TabTile(
                    icon: Icons.image_rounded,
                    color: Colors.purple,
                    title: 'Pictogramas',
                    subtitle: 'Tablero de comunicación aumentativa',
                    value: picto,
                    locked: hasTutor || (picto && activeCount <= 1),
                    onToggle: guard(
                      picto,
                      () => featuresRef.set(
                        {'featurePictogramas': !picto},
                        SetOptions(merge: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TabTile(
                    icon: Icons.self_improvement,
                    color: Colors.deepOrange,
                    title: 'Foco',
                    subtitle: 'Temporizador Pomodoro y respiración guiada',
                    value: foco,
                    locked: hasTutor || (foco && activeCount <= 1),
                    onToggle: guard(
                      foco,
                      () => featuresRef.set(
                        {'featureFoco': !foco},
                        SetOptions(merge: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TabTile(
                    icon: Icons.person_rounded,
                    color: _Palette.primary,
                    title: 'Perfil',
                    subtitle: 'Configuración y estadísticas personales',
                    value: perfil,
                    locked: hasTutor || (perfil && activeCount <= 1),
                    onToggle: guard(
                      perfil,
                      () => featuresRef.set(
                        {'featurePerfil': !perfil},
                        SetOptions(merge: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  StreamBuilder<bool>(
                    stream: KioskModeService.streamEnabled(),
                    builder: (context, kioskSnap) {
                      final kioskEnabled = kioskSnap.data ?? false;
                      return _KioskTile(
                        value: kioskEnabled,
                        locked: hasTutor,
                        onToggle: hasTutor
                            ? null
                            : () => kioskEnabled
                                ? KioskModeService.disable()
                                : _showKioskConfirmation(context),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TabTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool locked;
  final VoidCallback? onToggle;

  const _TabTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.locked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final active = value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active && !locked
              ? color.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: active && !locked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 0.12 : 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: active ? color : Colors.grey.shade400, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: active ? _Palette.textDark : Colors.grey.shade500,
          ),
        ),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
        trailing: locked
            ? Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: active ? Colors.green.shade400 : Colors.grey.shade400,
                size: 22,
              )
            : Switch.adaptive(
                value: active,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
                activeThumbColor: color,
              ),
      ),
    );
  }
}

/// Diálogo de confirmación para activar el modo Kiosk.
Future<void> _showKioskConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.phone_android_rounded, color: Colors.deepOrange),
          SizedBox(width: 8),
          Text('Modo Kiosk'),
        ],
      ),
      content: const Text(
        'Se bloqueará la navegación fuera de la app. '
        'No podrás usar el botón de inicio ni cambiar de aplicación. '
        'Para salir necesitarás el PIN de tu tutor.',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Activar'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await KioskModeService.enable();
  }
}

/// Tile para el toggle de Kiosk Mode.
class _KioskTile extends StatelessWidget {
  final bool value;
  final bool locked;
  final VoidCallback? onToggle;

  const _KioskTile({
    required this.value,
    required this.locked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value && !locked
              ? Colors.deepOrange.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: value && !locked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: value ? 0.12 : 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phone_android_rounded,
            color: value ? Colors.deepOrange : Colors.grey.shade400,
            size: 22,
          ),
        ),
        title: Text(
          'Modo Kiosk',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? _Palette.textDark : Colors.grey.shade500,
          ),
        ),
        subtitle: Text(
          'Bloquea la app para evitar salir accidentalmente',
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade500, height: 1.4),
        ),
        trailing: locked
            ? Icon(
                value
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: value ? Colors.green.shade400 : Colors.grey.shade400,
                size: 22,
              )
            : Switch.adaptive(
                value: value,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
                activeThumbColor: Colors.deepOrange,
              ),
      ),
    );
  }
}
