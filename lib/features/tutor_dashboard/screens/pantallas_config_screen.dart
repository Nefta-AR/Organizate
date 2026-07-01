// ============================================================
// lib/features/tutor_dashboard/screens/pantallas_config_screen.dart
// ============================================================
// Pantalla de configuración de pestañas visibles (feature flags) para el usuario.
//
// Lee y escribe el documento `users/{uid}/pictogramSettings/_features`.
// El usuario puede activar/desactivar las pestañas de su barra de navegación.
//
// ## Reglas de bloqueo
//
//   - Si el usuario tiene tutor vinculado: todos los switches se muestran
//     bloqueados (solo el tutor puede modificarlos desde su panel).
//     Se muestra un mensaje explicativo con ícono de candado.
//   - Siempre debe quedar al menos 1 pestaña activa: el guard() inline
//     deshabilita el switch de la última pestaña activa.
//
// ## Doble StreamBuilder
//
//   Outer → [AuthService.getLinkedTutorStream] para detectar si hay tutor.
//   Inner → featuresRef.snapshots() para los valores actuales de los flags.
//   Esto evita reads redundantes: solo escucha lo que necesita.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple/core/services/auth_service.dart';

// ── Paleta de colores interna ─────────────────────────────────────────────────
// Tonos azul-gris (blue-grey) para diferenciar visualmente de otras pantallas.
class _Palette {
  _Palette._(); // Constructor privado: clase de constantes no instanciable
  static const background = Color(0xFFF4F6F8); // Gris muy claro para el Scaffold
  static const primary    = Color(0xFF607D8B); // Blue-grey 600
  static const surface    = Colors.white;       // Fondo de tarjetas
  static const textDark   = Color(0xFF37474F); // Texto principal oscuro
  static const textMuted  = Color(0xFF78909C); // Texto secundario gris
  static const accent     = Color(0xFF7EA3BC); // Azul más vivo para el aviso de tutor
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
    // UID del usuario autenticado actualmente
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Referencia al documento de feature flags en la subcolección pictogramSettings.
    // CustomNavBar lee este mismo documento para decidir qué pestañas mostrar.
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

      // ── StreamBuilder exterior: detecta si hay tutor vinculado ─────────────
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: AuthService.getLinkedTutorStream(),
        builder: (context, tutorSnap) {
          // hasTutor = true si el stream devuelve datos (el Map del tutor)
          final hasTutor = tutorSnap.data != null;

          // ── StreamBuilder interior: feature flags actuales ──────────────────
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: featuresRef.snapshots(),
            builder: (context, featSnap) {
              // Leemos cada feature flag con defaults seguros.
              // Pictogramas está desactivado por defecto (interfaz más avanzada).
              final data   = featSnap.data?.data() ?? {};
              final inicio = data['featureInicio']      as bool? ?? true;
              final tareas = data['featureTareas']      as bool? ?? true;
              final picto  = data['featurePictogramas'] as bool? ?? false;
              final foco   = data['featureFoco']        as bool? ?? true;
              final perfil = data['featurePerfil']      as bool? ?? true;

              // Contamos las pestañas activas para aplicar la regla mínimo-1
              final activeCount =
                  [inicio, tareas, picto, foco, perfil].where((v) => v).length;

              // guard(): función inline que retorna:
              //   null   → switch deshabilitado (no se puede cambiar)
              //   fn     → callback que escribe en Firestore al tocar el switch
              //
              // Se deshabilita si:
              //   - hasTutor: el tutor controla los flags remotamente
              //   - value == true && activeCount <= 1: sería la última activa
              VoidCallback? guard(bool value, VoidCallback fn) =>
                  (hasTutor || (value && activeCount <= 1)) ? null : fn;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  // Título explicativo de la pantalla
                  const Text(
                    'Elige qué pestañas quieres ver en la app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtítulo con la regla del mínimo de 1 pestaña
                  Text(
                    'Debe haber al menos una pestaña activa.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),

                  // Banner de bloqueo: solo visible si hay tutor vinculado
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
                          // Icono de candado para indicar que está bloqueado
                          Icon(Icons.lock_outline_rounded,
                              size: 16,
                              color: _Palette.accent.withValues(alpha: 0.85)),
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

                  // ── Pestaña "Inicio" ────────────────────────────────────────
                  // guard() devuelve null si hasTutor o si es la última activa
                  _TabTile(
                    icon: Icons.home_rounded,
                    color: Colors.blue,
                    title: 'Inicio',
                    subtitle: 'Pantalla principal con resumen y motivación',
                    value: inicio,
                    locked: hasTutor || (inicio && activeCount <= 1),
                    // Al activar: escribe featureInicio: true en Firestore
                    // Al desactivar: escribe featureInicio: false
                    onToggle: guard(
                      inicio,
                      () => featuresRef.set(
                        {'featureInicio': !inicio},
                        SetOptions(merge: true), // merge: true preserva los demás flags
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Pestaña "Tareas" ────────────────────────────────────────
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

                  // ── Pestaña "Pictogramas" (CAA) ─────────────────────────────
                  // Desactivada por defecto (interfaz avanzada para usuarios TEA)
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

                  // ── Pestaña "Foco" (Pomodoro) ───────────────────────────────
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

                  // ── Pestaña "Perfil" ────────────────────────────────────────
                  _TabTile(
                    icon: Icons.person_rounded,
                    color: _Palette.primary, // Blue-grey para consistencia con el AppBar
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Widget de tarjeta de pestaña con switch ───────────────────────────────────
// Muestra el icono, título, subtítulo y el control del feature flag.
// Se anima suavemente cuando cambia entre activo/inactivo.

class _TabTile extends StatelessWidget {
  // Icono representativo de la pestaña
  final IconData icon;

  // Color temático de la pestaña (se aplica al icono y al borde activo)
  final Color color;

  // Nombre de la pestaña
  final String title;

  // Descripción breve de qué contiene la pestaña
  final String subtitle;

  // Estado actual del feature flag
  final bool value;

  // true si el switch debe mostrarse como candado (no interactivo)
  final bool locked;

  // Callback al tocar el switch; null si está deshabilitado
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
    final active = value; // Alias local para legibilidad

    // AnimatedContainer: transiciona suavemente el borde cuando cambia active
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // Borde coloreado si está activo y no está bloqueado; gris si no
          color: active && !locked
              ? color.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          // Borde más grueso cuando está activo para más énfasis visual
          width: active && !locked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06), // Sombra muy sutil
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

        // Icono dentro de un círculo coloreado con opacidad
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            // Fondo del círculo más opaco si está activo
            color: color.withValues(alpha: active ? 0.12 : 0.06),
            shape: BoxShape.circle,
          ),
          // Icono gris si está inactivo, color temático si está activo
          child: Icon(icon,
              color: active ? color : Colors.grey.shade400, size: 22),
        ),

        // Título gris si inactivo, oscuro si activo
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: active ? _Palette.textDark : Colors.grey.shade500,
          ),
        ),

        // Descripción siempre en gris
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500, height: 1.4)),

        // Trailing: candado/check si locked, Switch interactivo si no
        trailing: locked
            // Si está bloqueado: icono estático (check verde o candado gris)
            ? Icon(
                active
                    ? Icons.check_circle_rounded  // Activo pero no editable
                    : Icons.lock_outline_rounded,  // Inactivo y no editable
                color: active ? Colors.green.shade400 : Colors.grey.shade400,
                size: 22,
              )
            // Si no está bloqueado: Switch adaptativo (iOS/Android)
            : Switch.adaptive(
                value: active,
                // onChanged es null si onToggle es null (última pestaña activa)
                onChanged: onToggle == null ? null : (_) => onToggle!(),
                activeThumbColor: color, // El pulgar del switch adopta el color temático
              ),
      ),
    );
  }
}
