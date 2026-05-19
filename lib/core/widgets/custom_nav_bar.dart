import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/tda_focus/screens/foco_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tutor_dashboard/screens/settings_screen.dart';
import '../../features/tda_focus/screens/tareas_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';

/// Barra de navegación inferior con tabs dinámicos según rol y configuración
/// del tutor.
///
/// ## Comportamiento por rol
///
/// - **TDAH / usuario_general**: tabs fijos (Inicio, Tareas, Foco, Perfil).
/// - **TEA**: tabs reactivos. El tutor puede habilitar o deshabilitar
///   individualmente la pestaña de Pictogramas y la de Foco desde el panel
///   de supervisión. Los cambios se reflejan en tiempo real sin reiniciar la app.
///
/// ## Fuentes de datos (dos streams paralelos)
///
///   1. `users/{uid}` → campo `role` para determinar el tipo de usuario.
///   2. `users/{uid}/pictogramSettings/_features` → campos `featurePictogramas`
///      y `featureFoco`, escritos por el tutor con acceso ya autorizado en reglas.
///
/// ## Manejo de índice fuera de rango
///
/// Cuando el número de tabs cambia (el tutor activa/desactiva una pestaña),
/// `_currentIndex` puede quedar fuera de los límites del nuevo `_entries`.
/// El `.clamp()` en `build()` evita el crash de [BottomNavigationBar] en ese caso.
class CustomNavBar extends StatefulWidget {
  final int initialIndex;
  const CustomNavBar({super.key, this.initialIndex = 0});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

/// Modelo de datos interno para cada entrada de la barra de navegación.
/// [builder] es una factory en lugar de una instancia de [Widget] para evitar
/// crear instancias de pantalla que nunca se muestran.
class _NavEntry {
  final IconData icon;
  final String label;
  final Widget Function() builder;
  const _NavEntry(this.icon, this.label, this.builder);
}

class _CustomNavBarState extends State<CustomNavBar> {
  late int _currentIndex;
  String? _role;
  bool _featurePictogramas = true;  // Default para TEA: pictogramas activos
  bool _featureFoco        = false; // Default para TEA: foco inactivo

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _featuresSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _listenSettings();
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    _featuresSub?.cancel();
    super.dispose();
  }

  void _listenSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Stream 1: rol del usuario (determina qué conjunto de tabs mostrar)
    _roleSub = userRef.snapshots().listen((snap) {
      if (!mounted) return;
      setState(() => _role = snap.data()?['role'] as String?);
    });

    // Stream 2: feature flags escritos por el tutor.
    // Se almacenan en pictogramSettings/_features porque esa subcolección
    // ya tiene permisos de escritura para el tutor en las reglas actuales,
    // sin necesitar un deploy adicional de reglas.
    _featuresSub = userRef
        .collection('pictogramSettings')
        .doc('_features')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data() ?? {};
      setState(() {
        _featurePictogramas = data['featurePictogramas'] as bool? ?? true;
        _featureFoco        = data['featureFoco']        as bool? ?? false;
      });
    });
  }

  bool get _isTea => _role == 'usuario_tea' || _role == 'paciente_tea';

  /// Construye la lista de tabs según el rol y los feature flags actuales.
  /// Para usuarios TDAH los tabs son fijos; para TEA son configurables.
  List<_NavEntry> get _entries {
    if (!_isTea) {
      return [
        _NavEntry(Icons.home_rounded,      'Inicio',  () => const HomeScreen()),
        _NavEntry(Icons.task_alt,           'Tareas',  () => const TareasScreen()),
        _NavEntry(Icons.self_improvement,   'Foco',    () => const FocoScreen()),
        _NavEntry(Icons.person_rounded,     'Perfil',  () => const SettingsScreen()),
      ];
    }
    return [
      _NavEntry(Icons.home_rounded,    'Inicio',      () => const HomeScreen()),
      _NavEntry(Icons.task_alt,         'Tareas',      () => const TareasScreen()),
      if (_featurePictogramas)
        _NavEntry(Icons.image_rounded,  'Pictogramas', () => const PantallaPacienteTEA()),
      if (_featureFoco)
        _NavEntry(Icons.self_improvement, 'Foco',      () => const FocoScreen()),
      _NavEntry(Icons.person_rounded,   'Perfil',      () => const SettingsScreen()),
    ];
  }

  void _onItemTapped(int index) {
    final entries = _entries;
    if (index == _currentIndex || index >= entries.length) return;
    setState(() => _currentIndex = index);
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
    // Protección contra índice fuera de rango cuando el tutor cambia los features
    final safeIndex = _currentIndex.clamp(0, entries.length - 1);

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
