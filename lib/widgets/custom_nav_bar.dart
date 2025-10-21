// lib/widgets/custom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // Hacemos que "Inicio" aparezca seleccionado por defecto.
      currentIndex: 0,
      
      // Esto es crucial para que se vean más de 3 íconos con sus colores.
      type: BottomNavigationBarType.fixed,
      
      // Color del texto cuando un ícono está seleccionado.
      selectedItemColor: Colors.blue.shade700,
      
      // Color del texto cuando un ícono NO está seleccionado.
      unselectedItemColor: Colors.grey.shade600,
      
      // Tamaño del texto.
      selectedFontSize: 12,
      unselectedFontSize: 12,
      
      // Fondo blanco para la barra.
      backgroundColor: Colors.white,
      
      // Quitamos la sombra superior por defecto para un look más limpio.
      elevation: 0, 

      // La lista de nuestros botones, ahora construidos con un método auxiliar.
      items: [
        // ¡Estos nombres de archivo coinciden con tu captura de pantalla!
        _buildNavItem('Inicio', 'assets/icons/Inicio.png'),
        _buildNavItem('Estudios', 'assets/icons/Estudios.png'),
        _buildNavItem('Hogar', 'assets/icons/Hogar.png'),
        _buildNavItem('Meds', 'assets/icons/Meds.png'),
        _buildNavItem('Foco', 'assets/icons/Foco.png'),
        _buildNavItem('Progreso', 'assets/icons/Progreso.png'),
      ],
    );
  }

  // --- MÉTODO AUXILIAR ---
  // Esta función nos ayuda a no repetir el mismo código 6 veces.
  BottomNavigationBarItem _buildNavItem(String label, String imagePath) {
    return BottomNavigationBarItem(
      label: label,
      // Usamos Image.asset para cargar tu archivo de imagen.
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0, top: 4.0), // Espacio vertical
        child: Image.asset(
          imagePath,
          width: 28,  // Ancho deseado para el ícono
          height: 28, // Alto deseado para el ícono
        ),
      ),
    );
  }
}