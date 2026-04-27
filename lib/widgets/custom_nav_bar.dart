// lib/widgets/custom_nav_bar.dart
import 'package:flutter/material.dart';
// Importa TODAS las pantallas
import 'package:organizate/screens/home_screen.dart';
import 'package:organizate/screens/estudios_screen.dart';
import 'package:organizate/screens/hogar_screen.dart';
import 'package:organizate/screens/meds_screen.dart';
import 'package:organizate/screens/foco_screen.dart';
import 'package:organizate/screens/progreso_screen.dart';

class CustomNavBar extends StatefulWidget {
  // (Opcional) Podemos pasar el índice activo inicial si es necesario
  final int initialIndex;
  const CustomNavBar({super.key, this.initialIndex = 0}); // Inicio por defecto

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  late int _currentIndex; // Guardará el índice del botón activo

  // Lista de las pantallas a las que navegaremos
  final List<Widget> _screens = const [
    HomeScreen(),
    EstudiosScreen(),
    HogarScreen(),
    MedsScreen(),
    FocoScreen(),
    ProgresoScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Usa el índice inicial
  }

  // Función que se llama CADA VEZ que se toca un ítem de la barra
  void _onItemTapped(int index) {
    // Si ya estamos en esa pantalla, no hacemos nada
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index; // Actualiza el ítem activo
    });

    // Navega a la pantalla correspondiente REEMPLAZANDO la actual
    // Esto evita acumular pantallas en el historial de navegación
    Navigator.pushReplacement(
      context,
      // Usamos PageRouteBuilder para quitar la animación de transición
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => _screens[index],
        transitionDuration: Duration.zero, // Sin animación
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex, // Le dice cuál ítem está activo
      onTap: _onItemTapped,       // Qué hacer al tocar un ítem
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue.shade700,
      unselectedItemColor: Colors.grey.shade600,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      backgroundColor: Colors.white,
      elevation: 5, // Sombra
      items: [ // Los ítems (igual que antes)
        _buildNavItem('Inicio', 'assets/icons/Inicio.png'),
        _buildNavItem('Estudios', 'assets/icons/Estudios.png'),
        _buildNavItem('Hogar', 'assets/icons/Hogar.png'),
        _buildNavItem('Meds', 'assets/icons/Meds.png'),
        _buildNavItem('Foco', 'assets/icons/Foco.png'),
        _buildNavItem('Progreso', 'assets/icons/Progreso.png'),
      ],
    );
  }

  // Método auxiliar (igual que antes)
  BottomNavigationBarItem _buildNavItem(String label, String imagePath) {
    // Podríamos añadir lógica aquí para mostrar un ícono diferente si está activo
    return BottomNavigationBarItem(
      label: label,
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
        child: Image.asset( imagePath, width: 28, height: 28,
          // Aplica color gris si NO está activo (opcional)
          // color: _currentIndex == _getIndexFromLabel(label) ? null : Colors.grey.shade400,
        ),
      ),
      // (Opcional) Ícono diferente cuando está activo
      // activeIcon: Padding(...)
    );
  }

   // (Opcional) Función auxiliar para obtener el índice basado en la etiqueta
   // int _getIndexFromLabel(String label) {
   //   switch(label){
   //     case 'Inicio': return 0;
   //     case 'Estudios': return 1;
   //     // ... y así sucesivamente
   //     default: return 0;
   //   }
   // }
}