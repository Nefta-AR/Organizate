import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/tda_focus/screens/foco_screen.dart';
import '../../features/tutor_dashboard/screens/home_screen.dart';
import '../../features/tutor_dashboard/screens/settings_screen.dart';
import '../../features/tda_focus/screens/tareas_screen.dart';
import '../../features/tea_board/screens/pantalla_paciente_tea.dart';

class CustomNavBar extends StatefulWidget {
  final int initialIndex;
  const CustomNavBar({super.key, this.initialIndex = 0});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  late int _currentIndex;
  String? _role;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) setState(() => _role = doc.data()?['role'] as String?);
  }

  bool get _isTea => _role == 'paciente_tea';

  Widget _screenForIndex(int index) => switch (index) {
        0 => const HomeScreen(),
        1 => const TareasScreen(),
        2 => _isTea ? const PantallaPacienteTEA() : const FocoScreen(),
        _ => const SettingsScreen(),
      };

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _screenForIndex(index),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue.shade700,
      unselectedItemColor: Colors.grey.shade500,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      elevation: 8,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded), label: 'Inicio'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.task_alt), label: 'Tareas'),
        BottomNavigationBarItem(
          icon: Icon(_isTea ? Icons.image_rounded : Icons.self_improvement),
          label: _isTea ? 'Pictogramas' : 'Foco',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded), label: 'Perfil'),
      ],
    );
  }
}
