// ignore_for_file: deprecated_member_use
// ============================================================
// lib/core/theme/app_theme.dart
// ============================================================
// Tema visual de Simple — Prótesis Cognitiva Minimalista.
//
// ## Principios de diseño
//
//   · Carga cognitiva mínima: jerarquía clara, sin ruido visual.
//   · Cero sobreestimulación: paleta terapéutica, sombras etéreas.
//   · Amigable para TDAH/TEA: tipografía redondeada, bordes suaves,
//     espaciado generoso y retroalimentación visual predecible.
//
// ## Cómo se usa
//
//   MaterialApp(
//     theme: AppTheme.getTheme(),
//     ...
//   )
//
// ## Estructura del archivo
//
//   1. Paleta de colores (constantes estáticas públicas)
//   2. Radios de borde (radiusSmall/Medium/Large/XLarge)
//   3. Sombras (softShadow / mediumShadow)
//   4. Decoraciones reutilizables (cardDecoration, subtleDecoration, accentDecoration)
//   5. getTheme() → configura los 15+ temas de componentes M3
//   6. _buildColorScheme() → ColorScheme con todos los colores semánticos M3
//   7. _buildTextTheme() → TextTheme Nunito con 13 variantes tipográficas
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema visual de Simple — Prótesis Cognitiva Minimalista.
///
/// Principios de diseño:
///   · Carga cognitiva mínima: jerarquía clara, sin ruido visual.
///   · Cero sobreestimulación: paleta terapéutica, sombras etéreas.
///   · Amigable para TDAH/TEA: tipografía redondeada, bordes suaves,
///     espaciado generoso y retroalimentación visual predecible.
class AppTheme {
  AppTheme._(); // Constructor privado: esta clase solo expone constantes y métodos estáticos

  // ────────────────────────────────────────────────────────────────────────────
  // PALETA PRINCIPAL — 15 tokens de color semánticos
  //
  // Todos los tokens son `const` para que el compilador los pueda optimizar.
  // No usar Color() directamente en widgets; siempre usar los tokens de aquí
  // para mantener coherencia y facilitar un futuro modo oscuro.
  // ────────────────────────────────────────────────────────────────────────────

  /// Fondo general — crema muy cálida, evita la fatiga del blanco puro.
  /// El blanco puro (#FFFFFF) puede generar sobreestimulación en usuarios TEA/TDAH.
  static const Color warmCream = Color(0xFFF7F4F0);

  /// Superficie de cards y modales (blanco puro sobre fondo crema para contraste).
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Azul pastel calmante — primario de la app.
  /// Elegido por sus propiedades calmantes (estudios de cromoterapia en TEA).
  static const Color softBlue = Color(0xFF7BB3D0);

  /// Azul primario más saturado para hover / pressed (estados interactivos).
  static const Color softBlueDark = Color(0xFF5A9ABF);

  /// Contenedor de primario — tinte muy claro del azul (10% aprox.).
  /// Se usa como fondo de chips, indicadores de NavigationBar activo, etc.
  static const Color softBlueContainer = Color(0xFFDCEDF5);

  /// Verde salvia — secundario, evoca naturaleza y equilibrio emocional.
  static const Color sageGreen = Color(0xFF8FAF8C);

  /// Contenedor del secundario.
  static const Color sageGreenContainer = Color(0xFFDEEADB);

  /// Lavanda suave — terciario, creatividad y paz.
  static const Color softLavender = Color(0xFFB8A9C9);

  /// Contenedor del terciario.
  static const Color lavenderContainer = Color(0xFFEDE7F6);

  /// Texto principal — marrón cálido oscuro, nunca negro puro (#000000).
  /// El negro puro genera demasiado contraste con el fondo crema, cansando la vista.
  static const Color warmCharcoal = Color(0xFF3D3835);

  /// Texto de cuerpo — ligeramente más suave que el principal (menor contraste).
  static const Color softCharcoal = Color(0xFF4A4540);

  /// Texto secundario / hints — apagado, no distrae la atención principal.
  static const Color mutedText = Color(0xFF8C8580);

  /// Error — rosa suave, no rojo agresivo (#FF0000 sería sobreestimulante para TEA).
  static const Color errorMuted = Color(0xFFD97070);

  /// Borde principal — casi invisible, solo delimita sin añadir ruido visual.
  static const Color outlineSoft = Color(0xFFD4CFC8);

  /// Borde variante — para estados normales de inputs (más visible que outlineSoft).
  static const Color outlineVariant = Color(0xFFE8E4DE);

  /// Superficie variante — fondos de inputs y chips (ligeramente más oscuro que warmCream).
  static const Color surfaceVariant = Color(0xFFF0EDE8);

  // ────────────────────────────────────────────────────────────────────────────
  // RADIOS DE BORDE — Soft UI: sin esquinas duras
  //
  // Los bordes redondeados reducen la percepción de "amenaza" visual,
  // lo que facilita la interacción en usuarios con TDAH/TEA.
  // La escala sigue una progresión de 12 → 16 → 24 → 32.
  // ────────────────────────────────────────────────────────────────────────────

  static const double radiusSmall  = 12.0; // Chips, checkboxes, tooltips
  static const double radiusMedium = 16.0; // Inputs, cards pequeñas, list tiles
  static const double radiusLarge  = 24.0; // Cards principales, botones
  static const double radiusXLarge = 32.0; // Dialogs, bottom sheets (muy redondeados)

  // ────────────────────────────────────────────────────────────────────────────
  // SOMBRAS — etéreas, difuminadas, sin dureza
  //
  // Las sombras nítidas generan "ruido" visual. Se prefieren sombras
  // con blurRadius alto y opacidad baja para dar profundidad sutil.
  // ────────────────────────────────────────────────────────────────────────────

  /// Sombra mínima para cards en reposo (2 capas para naturalidad).
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color:       warmCharcoal.withOpacity(0.06), // 6% de opacidad: casi invisible
          blurRadius:  20,  // Muy difuminada
          spreadRadius: 0,
          offset: const Offset(0, 4), // Solo hacia abajo (efecto de elevación natural)
        ),
        BoxShadow(
          color:       warmCharcoal.withOpacity(0.03), // 3% de opacidad: subliminal
          blurRadius:  6,
          spreadRadius: 0,
          offset: const Offset(0, 1), // Capa fina adicional para borde inferior suave
        ),
      ];

  /// Sombra media para modales o cards elevadas (más profundidad que softShadow).
  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color:       warmCharcoal.withOpacity(0.10), // 10% → visible pero no agresiva
          blurRadius:  32,
          spreadRadius: 0,
          offset: const Offset(0, 8), // Mayor desplazamiento = mayor elevación percibida
        ),
      ];

  // ────────────────────────────────────────────────────────────────────────────
  // DECORACIONES REUTILIZABLES
  //
  // Getters en lugar de const: usan softShadow y mediumShadow que no son const.
  // Se usan directamente en los widgets para evitar repetición.
  // ────────────────────────────────────────────────────────────────────────────

  /// Decoración estándar de card con radio grande y sombra suave.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color:        surfaceWhite,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow:    softShadow,
      );

  /// Decoración sutil para contenedores secundarios (sin sombra, solo fondo).
  static BoxDecoration get subtleDecoration => BoxDecoration(
        color:        surfaceVariant,
        borderRadius: BorderRadius.circular(radiusMedium),
      );

  /// Decoración de accent container (fondo tintado del primario).
  /// Usado para secciones de información destacada dentro de cards.
  static BoxDecoration get accentDecoration => BoxDecoration(
        color:        softBlueContainer,
        borderRadius: BorderRadius.circular(radiusMedium),
      );

  // ────────────────────────────────────────────────────────────────────────────
  // PUNTO DE ENTRADA PÚBLICO
  // ────────────────────────────────────────────────────────────────────────────

  /// Retorna el [ThemeData] completo listo para `MaterialApp.theme`.
  ///
  /// Configura 15 sub-temas de componentes Material 3.
  static ThemeData getTheme() {
    final colorScheme = _buildColorScheme(); // 20 tokens semánticos de color M3
    final textTheme   = _buildTextTheme();   // 13 variantes tipográficas Nunito

    return ThemeData(
      useMaterial3: true, // Activa Material Design 3 (esquinas redondeadas, tokens semánticos)
      colorScheme:  colorScheme,
      textTheme:    textTheme,
      scaffoldBackgroundColor: warmCream, // Fondo crema en todas las pantallas

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:         warmCream,   // Mismo fondo que el scaffold (sin contraste abrupto)
        foregroundColor:         warmCharcoal,
        elevation:               0,           // Sin sombra (flat design)
        scrolledUnderElevation:  0,           // Sin elevación al hacer scroll (evita ruido)
        centerTitle:             true,        // Título siempre centrado para uniformidad
        surfaceTintColor:        Colors.transparent, // Desactiva el tinte de color en M3
        titleTextStyle: GoogleFonts.nunito(
          fontSize:      20,
          fontWeight:    FontWeight.w700, // Bold para jerarquía clara
          color:         warmCharcoal,
          letterSpacing: 0.1,
        ),
        iconTheme:        const IconThemeData(color: warmCharcoal, size: 24),
        actionsIconTheme: const IconThemeData(color: softCharcoal, size: 24),
      ),

      // ── Cards ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:           surfaceWhite,
        elevation:       0,                    // Sin sombra intrínseca (se usa boxShadow)
        shadowColor:     Colors.transparent,   // Elimina la sombra Material predeterminada
        surfaceTintColor: Colors.transparent,  // Sin tinte de color en M3
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge), // 24px: muy redondeado
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),

      // ── ElevatedButton ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:         softBlue,     // Azul primario como fondo
          foregroundColor:         Colors.white, // Texto blanco sobre azul
          disabledBackgroundColor: outlineSoft,  // Gris suave cuando deshabilitado
          disabledForegroundColor: mutedText,    // Texto apagado cuando deshabilitado
          elevation:               0,   // Sin sombra (contrario al nombre, es flat)
          shadowColor:             Colors.transparent,
          padding:     const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 52), // Área táctil mínima de 52px (accesibilidad)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge), // 24px
          ),
          textStyle: GoogleFonts.nunito(
            fontSize:      16,
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── FilledButton (variante rellena de M3) ─────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: softBlue,
          foregroundColor: Colors.white,
          padding:         const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize:     const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize:      16,
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:         softBlue,  // Texto e ícono en azul primario
          disabledForegroundColor: mutedText,
          side: const BorderSide(color: softBlue, width: 1.5), // Borde azul siempre visible
          padding:     const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize:      16,
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── TextButton (acción terciaria: links, cancelar) ───────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: softBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize:      15,
            fontWeight:    FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── InputDecoration (TextField, TextFormField) ───────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,               // Fondo relleno (más visible que un input en blanco)
        fillColor:      surfaceVariant,     // Fondo ligeramente grisáceo para inputs
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide:   BorderSide.none,   // Sin borde por defecto (usan estado específico)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide:   const BorderSide(color: outlineVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide:   const BorderSide(color: softBlue, width: 1.5), // Azul al enfocar
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide:   const BorderSide(color: errorMuted, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide:   const BorderSide(color: errorMuted, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          color:      mutedText,
          fontSize:   15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.nunito(
          color:      softCharcoal,
          fontSize:   14,
          fontWeight: FontWeight.w500,
        ),
        // Label flotante cuando el input está en foco (sobre el borde)
        floatingLabelStyle: GoogleFonts.nunito(
          color:      softBlue,   // Azul primario para indicar el campo activo
          fontSize:   13,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: GoogleFonts.nunito(
          color:      errorMuted,
          fontSize:   12,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: mutedText, // Íconos dentro del input en color apagado
        suffixIconColor: mutedText,
      ),

      // ── NavigationBar (M3 — barra inferior) ─────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        indicatorColor:  softBlueContainer, // Pastilla azul clara alrededor del ítem activo
        surfaceTintColor: Colors.transparent,
        shadowColor:     Colors.transparent,
        elevation:       0,
        // Ícono del ítem activo vs inactivo
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: softBlueDark, size: 24); // Azul oscuro al activar
          }
          return const IconThemeData(color: mutedText, size: 24); // Apagado cuando inactivo
        }),
        // Etiqueta del ítem activo vs inactivo.
        // 11pt (no 12) para que la etiqueta más larga ("Pictogramas") quepa
        // en una sola línea con 5 destinos en pantallas de 360dp.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.nunito(
              fontSize:   11,
              fontWeight: FontWeight.w700, // Bold al seleccionar
              color:      softBlueDark,
            );
          }
          return GoogleFonts.nunito(
            fontSize:   11,
            fontWeight: FontWeight.w400, // Regular cuando inactivo
            color:      mutedText,
          );
        }),
      ),

      // ── BottomNavigationBar (API legacy — usado en pantallas antiguas) ─────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:  surfaceWhite,
        selectedItemColor: softBlue,
        unselectedItemColor: mutedText,
        elevation:        0,
        type: BottomNavigationBarType.fixed, // Fixed: los ítems no se desplazan al seleccionar
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // ── Chip (FilterChip, ChoiceChip, InputChip) ─────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,     // Fondo por defecto (no seleccionado)
        selectedColor:   softBlueContainer,  // Fondo azul al seleccionar
        disabledColor:   outlineVariant,
        labelStyle: GoogleFonts.nunito(
          fontSize:   13,
          fontWeight: FontWeight.w500,
          color:      softCharcoal,
        ),
        side: const BorderSide(color: outlineVariant, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall), // 12px: redondeado pero no pill
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── AlertDialog / SimpleDialog ───────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  surfaceWhite,
        elevation:        0, // Sin sombra M2; la sombra del scrim basta
        shadowColor:      Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge), // 32px: muy redondeado para modales
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize:      20,
          fontWeight:    FontWeight.w700,
          color:         warmCharcoal,
          letterSpacing: 0.1,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize:   15,
          fontWeight: FontWeight.w400,
          color:      softCharcoal,
          height:     1.65, // line-height generoso para lectura cómoda
        ),
      ),

      // ── BottomSheet (showModalBottomSheet) ───────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:      surfaceWhite,
        modalBackgroundColor: surfaceWhite,
        elevation:       0,
        modalElevation:  0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          // Solo las esquinas superiores redondeadas (sale desde abajo)
          borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(radiusXLarge), // 32px
            topRight: Radius.circular(radiusXLarge),
          ),
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: warmCharcoal, // Fondo oscuro (contrasta bien con warmCream)
        elevation:       0,
        behavior:        SnackBarBehavior.floating, // Flotante sobre el contenido
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize:   14,
          fontWeight: FontWeight.w500,
          color:      warmCream, // Texto crema sobre fondo oscuro (contraste > 4.5:1)
        ),
        actionTextColor: softBlueContainer, // Azul claro para la acción (visible sobre oscuro)
      ),

      // ── FloatingActionButton ─────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: softBlue,
        foregroundColor: Colors.white,
        elevation:       2,   // Leve elevación (diferencia del contenido flat)
        focusElevation:  4,
        hoverElevation:  4,
        splashColor:     softBlueDark.withOpacity(0.3), // Efecto ripple en tono oscuro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge), // 24px: casi pill
        ),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent, // Sin fondo propio (usa el del contenedor)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.nunito(
          fontSize:   16,
          fontWeight: FontWeight.w600,
          color:      warmCharcoal,
        ),
        subtitleTextStyle: GoogleFonts.nunito(
          fontSize:   14,
          fontWeight: FontWeight.w400,
          color:      mutedText,
          height:     1.5, // line-height cómodo para subtítulos
        ),
        iconColor: mutedText, // Íconos en color apagado por defecto
      ),

      // ── Switch (SwitchListTile, Switch) ──────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          // Pulgar: azul primario al activar, gris apagado al desactivar
          if (states.contains(WidgetState.selected)) return softBlue;
          return mutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          // Track: contenedor de primario al activar, gris suave al desactivar
          if (states.contains(WidgetState.selected)) return softBlueContainer;
          return outlineVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent), // Sin borde en el track
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          // Relleno azul al marcar, transparente al desmarcar
          if (states.contains(WidgetState.selected)) return softBlue;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white), // Tilde blanca sobre fondo azul
        side:  const BorderSide(color: outlineSoft, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // Ligeramente redondeado
        ),
      ),

      // ── Radio (RadioListTile) ─────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return softBlue;
          return mutedText;
        }),
      ),

      // ── LinearProgressIndicator / CircularProgressIndicator ─────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:              softBlue,          // Color de la barra/aro en progreso
        linearTrackColor:   softBlueContainer, // Fondo de la barra lineal (no rellenado)
        circularTrackColor: softBlueContainer, // Fondo del aro circular
        linearMinHeight:    6,                 // 6px de altura: visible pero no dominante
      ),

      // ── Slider ───────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor:   softBlue,           // Segmento seleccionado del track
        inactiveTrackColor: softBlueContainer,  // Segmento no seleccionado del track
        thumbColor:         softBlue,           // Pulgar del slider
        overlayColor:       softBlue.withOpacity(0.12), // Efecto ripple alrededor del pulgar
        trackHeight:        4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12), // Pulgar grande para accesibilidad táctil
      ),

      // ── TabBar ───────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:           softBlueDark, // Etiqueta activa en azul oscuro
        unselectedLabelColor: mutedText,
        dividerColor:         Colors.transparent, // Sin línea separadora inferior
        indicatorSize:        TabBarIndicatorSize.tab, // Indicador ocupa todo el ancho del tab
        indicator: BoxDecoration(
          color:        softBlueContainer,             // Pastilla azul como indicador (no subrayado)
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        labelStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
      ),

      // ── Divider ───────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     outlineVariant, // Gris muy suave para no dominar la pantalla
        thickness: 1,
        space:     1, // Sin espacio adicional vertical (el caller controla el padding)
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:        warmCharcoal.withOpacity(0.88), // Casi opaco para legibilidad
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: GoogleFonts.nunito(
          fontSize:   13,
          fontWeight: FontWeight.w400,
          color:      warmCream, // Texto claro sobre fondo oscuro
        ),
      ),

      // ── PopupMenuButton ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color:           surfaceWhite,
        elevation:       4, // Leve sombra para separar el menú del fondo
        shadowColor:     warmCharcoal.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize:   15,
          fontWeight: FontWeight.w500,
          color:      warmCharcoal,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // COLOR SCHEME — Material 3 (20 tokens semánticos)
  //
  // Los tokens siguen la convención M3: primary/onPrimary, secondary/onSecondary,
  // tertiary/onTertiary, error/onError, surface/onSurface, etc.
  // El prefijo `on` indica el color del texto/ícono sobre esa superficie.
  // ────────────────────────────────────────────────────────────────────────────

  static ColorScheme _buildColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light, // Solo modo claro (no soporta dark mode aún)

      // Primario — Azul pastel calmante (CTA, links, active states)
      primary:          softBlue,
      onPrimary:        Color(0xFFFFFFFF),          // Texto blanco sobre azul pastel
      primaryContainer: softBlueContainer,           // Chip selected, NavigationBar indicator
      onPrimaryContainer: Color(0xFF1A4A6B),         // Texto oscuro sobre contenedor claro

      // Secundario — Verde salvia (acciones secundarias, badges)
      secondary:          sageGreen,
      onSecondary:        Color(0xFFFFFFFF),
      secondaryContainer: sageGreenContainer,
      onSecondaryContainer: Color(0xFF1C3D1A),

      // Terciario — Lavanda (tinte de noche, emociones, elementos decorativos)
      tertiary:          softLavender,
      onTertiary:        Color(0xFFFFFFFF),
      tertiaryContainer: lavenderContainer,
      onTertiaryContainer: Color(0xFF3A2D5C),

      // Error — rosa suave, sin agresividad (mensajes de error, campos inválidos)
      error:          errorMuted,
      onError:        Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFBE9E9),       // Fondo tenue para mensajes de error
      onErrorContainer: Color(0xFF7A2020),      // Texto rojo oscuro sobre error container

      // Superficies — base de la UI
      surface:          surfaceWhite,
      onSurface:        softCharcoal,
      surfaceVariant:   surfaceVariant,         // Fondo de inputs y chips
      onSurfaceVariant: Color(0xFF6B6560),      // Texto sobre surfaceVariant

      // Bordes y elementos de contorno
      outline:        outlineSoft,
      outlineVariant: outlineVariant,

      // Sombras y scrims (overlay de modales)
      shadow: Color(0xFF000000),
      scrim:  Color(0xFF000000),

      // Superficies inversas (SnackBars, tooltips)
      inverseSurface:  warmCharcoal, // Fondo oscuro para SnackBars
      onInverseSurface: warmCream,   // Texto claro sobre fondo oscuro
      inversePrimary:  Color(0xFFADD3E8), // Azul más claro para modo inverso

      // surfaceTint: color de M3 para el "material tint" (no se usa porque se desactiva)
      surfaceTint: softBlue,

      // Background (alias de surface en M3 — deprecated en M3 pero mantenido por compatibilidad)
      background:   warmCream,
      onBackground: warmCharcoal,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TEXT THEME — Nunito: redondeada, amigable, alta legibilidad
  //
  // Nunito fue elegida porque:
  //   · Sus formas redondeadas son más fáciles de procesar para usuarios con TDAH.
  //   · Sus terminaciones no serif reducen el esfuerzo de decodificación.
  //   · Tiene un amplio rango de pesos (300-900) para jerarquía clara.
  //   · Alta legibilidad a tamaños pequeños (body, labels).
  //
  // La escala de tamaños sigue el Type Scale de Material 3:
  //   Display: 57/45/36 · Headline: 32/28/24 · Title: 22/16/14
  //   Body: 16/14/12   · Label: 14/12/11
  // ────────────────────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // ── Display — pantallas de bienvenida, onboarding (texto héroe) ────────
      displayLarge: GoogleFonts.nunito(
        fontSize:      57,
        fontWeight:    FontWeight.w300,  // Light: impacto visual a gran tamaño
        letterSpacing: -0.25,            // Tracking negativo para tamaños grandes (M3 spec)
        color:         warmCharcoal,
        height:        1.12,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize:      45,
        fontWeight:    FontWeight.w300,
        letterSpacing: 0,
        color:         warmCharcoal,
        height:        1.16,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize:      36,
        fontWeight:    FontWeight.w400,  // Regular: un poco más de peso que display grande
        letterSpacing: 0,
        color:         warmCharcoal,
        height:        1.22,
      ),

      // ── Headline — títulos de sección principales ──────────────────────────
      headlineLarge: GoogleFonts.nunito(
        fontSize:      32,
        fontWeight:    FontWeight.w700, // Bold: jerarquía fuerte
        letterSpacing: 0,
        color:         warmCharcoal,
        height:        1.25,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize:      28,
        fontWeight:    FontWeight.w700,
        letterSpacing: 0,
        color:         warmCharcoal,
        height:        1.29,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize:      24,
        fontWeight:    FontWeight.w600, // SemiBold: ligeramente menos que headline mayor
        letterSpacing: 0,
        color:         warmCharcoal,
        height:        1.33,
      ),

      // ── Title — cards, drawers, listas ────────────────────────────────────
      titleLarge: GoogleFonts.nunito(
        fontSize:      22,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0,
        color:         warmCharcoal,
        height:        1.27,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize:      16,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0.15, // Tracking leve para legibilidad en listas
        color:         warmCharcoal,
        height:        1.50,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize:      14,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0.1,
        color:         warmCharcoal,
        height:        1.43,
      ),

      // ── Body — texto de lectura principal ─────────────────────────────────
      // line-height (height) amplio (≥1.5) para facilitar el seguimiento de línea
      // en usuarios con TDAH (reduce "salto de línea" accidental al leer).
      bodyLarge: GoogleFonts.nunito(
        fontSize:      16,
        fontWeight:    FontWeight.w400,
        letterSpacing: 0.5,
        color:         softCharcoal, // Ligeramente más suave que warmCharcoal
        height:        1.75,         // 28px line-height para 16px font (muy generoso)
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize:      14,
        fontWeight:    FontWeight.w400,
        letterSpacing: 0.25,
        color:         softCharcoal,
        height:        1.71,         // ~24px line-height para 14px font
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize:      12,
        fontWeight:    FontWeight.w400,
        letterSpacing: 0.4,
        color:         mutedText,    // Apagado: texto terciario, ayudas, hints
        height:        1.67,
      ),

      // ── Label — botones, chips, badges ────────────────────────────────────
      // Labels son bold (w700/w600/w500) porque aparecen en elementos interactivos
      // donde necesitan ser distinguibles con un solo golpe de vista.
      labelLarge: GoogleFonts.nunito(
        fontSize:      14,
        fontWeight:    FontWeight.w700, // Bold para botones
        letterSpacing: 0.1,
        color:         warmCharcoal,
        height:        1.43,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize:      12,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0.5, // Tracking alto en tamaños pequeños mejora legibilidad
        color:         softCharcoal,
        height:        1.33,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize:      11,
        fontWeight:    FontWeight.w500, // Medium: visible pero no dominante a 11px
        letterSpacing: 0.5,
        color:         mutedText,
        height:        1.45,
      ),
    );
  }
}
