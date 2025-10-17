import 'package:flutter/material.dart';


/// Paleta y tema centralizados para mantener consistencia con el mockup
/// Azul (primario) + Verde agua (secundario), fondo blanco.
class AppColors {
  // Color primario (Azul) - Se usa para botones y elementos principales.
  static const primary = Color(0xFF1E88E5);

  // Color secundario (Verde agua) - Se usa para acentos y elementos secundarios.
  static const secondary = Color(0xFF1DE9B6);

  // Color de fondo general de las pantallas.
  static const background = Colors.white;
}


// Función que construye y devuelve el objeto ThemeData (la configuración del tema).
ThemeData appTheme() {
  // Creamos una base de tema usando las características de Material 3.
  final base = ThemeData(
    // Habilita las nuevas características de diseño de Material 3.
    useMaterial3: true,

    // Define el esquema de colores a partir de un color semilla (el primario).
    colorScheme: ColorScheme.fromSeed(
      // El color semilla a partir del cual se generan todos los tonos.
      seedColor: AppColors.primary,
      // Usamos un tema claro (light).
      brightness: Brightness.light,
    ).copyWith(
      // Forzamos los colores exactos definidos en AppColors.
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),

    // Define el color de fondo de todos los Scaffold (pantallas).
    scaffoldBackgroundColor: AppColors.background,
  );


  // Personalizamos la base con estilos adicionales.
  return base.copyWith(
    // Configuración global del texto.
    textTheme: base.textTheme.apply(
      // Color predeterminado para el texto de cuerpo.
      bodyColor: Colors.black87,
      // Color predeterminado para títulos y cabeceras.
      displayColor: Colors.black87,
    ),
    // Configuración global para todas las AppBars.
    appBarTheme: const AppBarTheme(
      // Fondo de la barra de navegación.
      backgroundColor: Colors.white,
      // Color del texto y los iconos dentro de la barra.
      foregroundColor: Colors.black87,
      // Elimina la sombra bajo la AppBar.
      elevation: 0,
      // Centra el título de la AppBar.
      centerTitle: true,
    ),
  );
}