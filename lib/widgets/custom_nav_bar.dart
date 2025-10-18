// lib/widgets/custom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // Colores para los íconos
      unselectedItemColor: Colors.grey.shade400,
      selectedItemColor: Colors.blueAccent,
      
      // Muestra solo el texto del ícono activo
      showUnselectedLabels: false,
      
      // Esto asegura que los colores que definimos en cada ícono se respeten
      type: BottomNavigationBarType.fixed,
      
      selectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), 
          label: 'Inicio',
          // Este es el ícono que se muestra cuando está activo, ¡con su color!
          activeIcon: Icon(Icons.home, color: Colors.blueAccent),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined), 
          label: 'Estudios',
          activeIcon: Icon(Icons.school, color: Colors.orange),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cottage_outlined), 
          label: 'Hogar',
          activeIcon: Icon(Icons.cottage, color: Colors.green),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined), 
          label: 'Meds',
          activeIcon: Icon(Icons.medication, color: Colors.redAccent),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.center_focus_strong_outlined), 
          label: 'Foco',
          activeIcon: Icon(Icons.center_focus_strong, color: Colors.purple),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_outline), 
          label: 'Progreso',
          activeIcon: Icon(Icons.star, color: Colors.amber),
        ),
      ],
    );
  }
}