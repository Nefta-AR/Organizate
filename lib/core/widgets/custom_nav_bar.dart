// ============================================================
// lib/core/widgets/custom_nav_bar.dart
// ============================================================
// Barra de navegación inferior dinámica con feature flags.
//
// Características:
//   - Lee los flags de activación desde Firestore en tiempo real
//     (`pictogramSettings/_features`), por lo que se actualiza
//     automáticamente cuando el tutor activa/desactiva pestañas.
//   - Usa NavScreen enum en lugar de índice numérico para identificar
//     la pantalla activa: esto es robusto si el número de tabs cambia.
//   - Si la pantalla activa es desactivada por el tutor, redirige
//     automáticamente al primer tab disponible.
//   - La transición entre tabs usa Duration.zero (sin animación)
//     para usuarios con sensibilidad a movimientos.
// ============================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/tda_focus/screens/foco_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tutor_dashboard/screens/settings_screen.dart';
import '../../features/tda_focus/screens/tareas_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';

/// Identificador semántico de la pantalla activa en la barra de navegación.
/// Usar un enum en lugar de un índice numérico evita que el índice quede
/// desincronizado cuando el número de tabs cambia dinámicamente.
enum NavScreen { inicio, tareas, pictogramas, foco, perfil }

/// Barra de navegación inferior con tabs configurables mediante feature flags.
///
/// Recibe [screen] para saber cuál tab está activo en la pantalla que la contiene.
/// Los tabs disponibles se calculan dinámicamente en cada build a partir de
/// los feature flags en Firestore, por lo que pueden cambiar en tiempo real.
class CustomNavBar extends StatefulWidget {
  final NavScreen screen;
  const CustomNavBar({super.key, this.screen = NavScreen.inicio});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

/// Modelo interno de una entrada de la barra de navegación.
/// [builder] es una factory function que crea el widget de la pantalla destino.
class _NavEntry {
  final NavScreen screen;
  final IconData icon;
  final String label;
  final Widget Function() builder; // Lazy: no crea el widget hasta que se navega
  const _NavEntry(this.screen, this.icon, this.label, this.builder);
}

class _CustomNavBarState extends State<CustomNavBar> {
  // La pantalla activa puede cambiar si el tutor desactiva el tab actual.
  late NavScreen _currentScreen;

  // Feature flags con valores por defecto seguros.
  // Pictogramas está desactivado por defecto (opt-in para usuarios TEA).
  bool _featureInicio      = true;
  bool _featureTareas      = true;
  bool _featurePictogramas = false; // Desactivado por defecto
  bool _featureFoco        = true;
  bool _featurePerfil      = true;

  // Suscripción al stream de Firestore; se cancela en dispose().
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _featuresSub;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.screen;
    _listenSettings(); // Inicia la escucha de feature flags en Firestore
  }

  @override
  void dispose() {
    // IMPORTANTE: cancelar la suscripción para evitar memory leaks.
    _featuresSub?.cancel();
    super.dispose();
  }

  /// Suscribe al documento `pictogramSettings/_features` del usuario actual.
  ///
  /// Este documento es editable tanto por el usuario como por el tutor vinculado
  /// (las reglas de Firestore permiten ambos). Por eso se usa como punto central
  /// de configuración de feature flags sin necesitar un deploy de reglas adicional.
  void _listenSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    _featuresSub = userRef
        .collection('pictogramSettings')
        .doc('_features')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data() ?? {};
      setState(() {
        // Lee cada flag con fallback al valor por defecto si no existe en Firestore.
        _featureInicio      = data['featureInicio']      as bool? ?? true;
        _featureTareas      = data['featureTareas']      as bool? ?? true;
        _featurePictogramas = data['featurePictogramas'] as bool? ?? false;
        _featureFoco        = data['featureFoco']        as bool? ?? true;
        _featurePerfil      = data['featurePerfil']      as bool? ?? true;
      });

      // Si el tutor desactivó la pantalla activa actual, redirige al primer
      // tab disponible para evitar que el usuario quede "atrapado" en un tab inexistente.
      final entries = _entries;
      if (entries.isNotEmpty &&
          !entries.any((e) => e.screen == _currentScreen)) {
        final first = entries.first;
        setState(() => _currentScreen = first.screen);
        // addPostFrameCallback para navegar fuera del setState (evita errores de build).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => first.builder(),
              transitionDuration:        Duration.zero, // Sin animación de transición
              reverseTransitionDuration: Duration.zero,
            ),
          );
        });
      }
    });
  }

  /// Lista de entries activas calculada a partir de los feature flags actuales.
  /// Se recalcula en cada build, lo que garantiza que refleja el estado actual.
  List<_NavEntry> get _entries => [
    if (_featureInicio)
      _NavEntry(NavScreen.inicio,      Icons.home_rounded,     'Inicio',      () => const HomeScreen()),
    if (_featureTareas)
      _NavEntry(NavScreen.tareas,      Icons.task_alt,         'Tareas',      () => const TareasScreen()),
    if (_featurePictogramas)
      _NavEntry(NavScreen.pictogramas, Icons.image_rounded,    'Pictogramas', () => const PantallaUsuarioTEA()),
    if (_featureFoco)
      _NavEntry(NavScreen.foco,        Icons.self_improvement, 'Foco',        () => const FocoScreen()),
    if (_featurePerfil)
      _NavEntry(NavScreen.perfil,      Icons.person_rounded,   'Perfil',      () => const SettingsScreen()),
  ];

  /// Busca el índice de [screen] en [entries]. Retorna 0 si no se encuentra
  /// (pantalla desactivada o índice inválido).
  int _indexOf(NavScreen screen, List<_NavEntry> entries) {
    final idx = entries.indexWhere((e) => e.screen == screen);
    return idx < 0 ? 0 : idx;
  }

  /// Maneja el tap en un tab: si ya está activo lo ignora; si no, navega.
  ///
  /// Usa Navigator.pushReplacement sin animación para dar la sensación de
  /// tabs estáticos (no hay slide ni fade entre pantallas).
  void _onItemTapped(int index) {
    final entries = _entries;
    if (index >= entries.length) return;
    final target = entries[index].screen;
    if (target == _currentScreen) return; // Mismo tab → no navegar
    setState(() => _currentScreen = target);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => entries[index].builder(),
        transitionDuration:        Duration.zero, // Cambio instantáneo entre tabs
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries   = _entries;
    // Si solo hay un tab activo (o ninguno), la barra no tiene sentido.
    // Se muestra un SizedBox vacío para no romper el layout del Scaffold.
    if (entries.length < 2) return const SizedBox.shrink();

    // Calcula el índice actual de forma segura.
    final safeIndex = _indexOf(_currentScreen, entries);

    return BottomNavigationBar(
      currentIndex:        safeIndex,
      onTap:               _onItemTapped,
      type:                BottomNavigationBarType.fixed, // Todos los items siempre visibles
      selectedItemColor:   Colors.blue.shade700,
      unselectedItemColor: Colors.grey.shade500,
      selectedFontSize:    12,
      unselectedFontSize:  12,
      backgroundColor:     Colors.white,
      elevation:           8,
      // Genera los BottomNavigationBarItem a partir de la lista dinámica de entries.
      items: entries
          .map((e) => BottomNavigationBarItem(icon: Icon(e.icon), label: e.label))
          .toList(),
    );
  }
}
