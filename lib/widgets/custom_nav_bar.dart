import 'package:flutter/material.dart';


/// Clase auxiliar de modelo. SE DEFINE AQUÍ UNA SOLA VEZ.
class _Item {
  final String label;
  final IconData icon;
  final Color color;
  const _Item(this.label, this.icon, this.color);
}

/// Barra de navegación inferior personalizada.
class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomNavBar({super.key, this.currentIndex = 0, this.onTap});

static const _items = <_Item>[
  _Item('Inicio',   Icons.home_outlined,        Color(0xFF1E88E5)),
  _Item('Estudios', Icons.book_outlined,        Color(0xFF7E57C2)),
  _Item('Hogar',    Icons.house_outlined,       Color(0xFF26A69A)),
  _Item('Meds',     Icons.medication_outlined,  Color(0xFFEF5350)),
  _Item('Foco',     Icons.lightbulb_outline,    Color(0xFFFFC107)),
  _Item('Progreso', Icons.emoji_events_outlined,Color(0xFFFFA726)),
];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: _items.map((e) {
        return BottomNavigationBarItem(
          icon: _TintedIcon(e.icon, e.color, selected: false),
          activeIcon: _TintedIcon(e.icon, e.color, selected: true),
          label: e.label,
        );
      }).toList(),
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }
}

// Widget auxiliar para aplicar el color y opacidad
class _TintedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  const _TintedIcon(this.icon, this.color, {required this.selected});

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN FINAL DE SINTAXIS: withOpacity(0.55)
    final c = selected ? color : color.withOpacity(0.55);
    return Icon(icon, color: c, size: 24);
  }
}