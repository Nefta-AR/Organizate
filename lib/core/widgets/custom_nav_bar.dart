import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/tda_focus/screens/foco_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tutor_dashboard/screens/settings_screen.dart';
import '../../features/tda_focus/screens/tareas_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';
/// Identifica qué pantalla está actualmente activa en la barra de navegación.
/// Usar una identidad semántica en lugar de un índice numérico evita
/// que el índice quede desincronizado cuando el número de tabs cambia
/// dinámicamente (el tutor activa/desactiva pestañas).
enum NavScreen { inicio, tareas, pictogramas, foco, perfil }

/// Barra de navegación inferior con tabs configurables mediante feature flags.
///
/// Todos los usuarios (rol `usuario`) comparten la misma lógica reactiva:
/// las pestañas Pictogramas y Foco se activan o desactivan desde el documento
/// `users/{uid}/pictogramSettings/_features` — el propio usuario lo controla
/// desde Ajustes si no tiene tutor vinculado; si tiene tutor, solo el tutor
/// puede modificarlo desde su panel de supervisión.
///
/// ## Fuentes de datos (dos streams paralelos)
///   1. `users/{uid}` → campo `role` (solo para discriminar si es tutor)
///   2. `users/{uid}/pictogramSettings/_features` → flags de pestañas
///
/// ## Corrección de índice
/// En lugar de `initialIndex: int`, el widget recibe `screen: NavScreen`.
/// El índice real se calcula en cada `build()` buscando la entrada cuya
/// pantalla coincide, lo que lo hace robusto ante cambios en el número de tabs.
class CustomNavBar extends StatefulWidget {
  final NavScreen screen;
  const CustomNavBar({super.key, this.screen = NavScreen.inicio});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _NavEntry {
  final NavScreen screen;
  final IconData icon;
  final String label;
  final Widget Function() builder;
  const _NavEntry(this.screen, this.icon, this.label, this.builder);
}

class _CustomNavBarState extends State<CustomNavBar> {
  late NavScreen _currentScreen;
  bool _featurePictogramas = false; // opt-in: desactivado por defecto
  bool _featureFoco        = true;  // activo por defecto

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _featuresSub;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.screen;
    _listenSettings();
  }

  @override
  void dispose() {
    _featuresSub?.cancel();
    super.dispose();
  }

  void _listenSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Los flags se leen desde pictogramSettings/_features porque esa
    // subcolección tiene permisos de escritura tanto para el dueño (usuario)
    // como para el tutor vinculado, sin necesitar un deploy de reglas adicional.
    _featuresSub = userRef
        .collection('pictogramSettings')
        .doc('_features')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data() ?? {};
      setState(() {
        _featurePictogramas = data['featurePictogramas'] as bool? ?? false;
        _featureFoco        = data['featureFoco']        as bool? ?? true;
      });
    });
  }

  List<_NavEntry> get _entries => [
    _NavEntry(NavScreen.inicio,      Icons.home_rounded,      'Inicio',      () => const HomeScreen()),
    _NavEntry(NavScreen.tareas,      Icons.task_alt,          'Tareas',      () => const TareasScreen()),
    if (_featurePictogramas)
      _NavEntry(NavScreen.pictogramas, Icons.image_rounded,   'Pictogramas', () => const PantallaPacienteTEA()),
    if (_featureFoco)
      _NavEntry(NavScreen.foco,      Icons.self_improvement,  'Foco',        () => const FocoScreen()),
    _NavEntry(NavScreen.perfil,      Icons.person_rounded,    'Perfil',      () => const SettingsScreen()),
  ];

  /// Busca el índice de la pantalla activa en la lista actual de entries.
  /// Si la pantalla no existe (fue desactivada por el tutor), vuelve a 0.
  int _indexOf(NavScreen screen, List<_NavEntry> entries) {
    final idx = entries.indexWhere((e) => e.screen == screen);
    return idx < 0 ? 0 : idx;
  }

  void _onItemTapped(int index) {
    final entries = _entries;
    if (index >= entries.length) return;
    final target = entries[index].screen;
    if (target == _currentScreen) return;
    setState(() => _currentScreen = target);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => entries[index].builder(),
        transitionDuration:        Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries   = _entries;
    final safeIndex = _indexOf(_currentScreen, entries);

    return BottomNavigationBar(
      currentIndex:        safeIndex,
      onTap:               _onItemTapped,
      type:                BottomNavigationBarType.fixed,
      selectedItemColor:   Colors.blue.shade700,
      unselectedItemColor: Colors.grey.shade500,
      selectedFontSize:    12,
      unselectedFontSize:  12,
      backgroundColor:     Colors.white,
      elevation:           8,
      items: entries
          .map((e) => BottomNavigationBarItem(icon: Icon(e.icon), label: e.label))
          .toList(),
    );
  }
}
