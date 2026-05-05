// ignore_for_file: deprecated_member_use
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
  AppTheme._();

  // ────────────────────────────────────────────────────────────────────────────
  // PALETA PRINCIPAL
  // ────────────────────────────────────────────────────────────────────────────

  /// Fondo general — crema muy cálida, evita la fatiga del blanco puro.
  static const Color warmCream = Color(0xFFF7F4F0);

  /// Superficie de cards y modales.
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Azul pastel calmante — primario de la app.
  static const Color softBlue = Color(0xFF7BB3D0);

  /// Azul primario más saturado para hover / pressed.
  static const Color softBlueDark = Color(0xFF5A9ABF);

  /// Contenedor de primario — tinte muy claro del azul.
  static const Color softBlueContainer = Color(0xFFDCEDF5);

  /// Verde salvia — secundario, evoca naturaleza y equilibrio.
  static const Color sageGreen = Color(0xFF8FAF8C);

  /// Contenedor del secundario.
  static const Color sageGreenContainer = Color(0xFFDEEADB);

  /// Lavanda suave — terciario, creatividad y paz.
  static const Color softLavender = Color(0xFFB8A9C9);

  /// Contenedor del terciario.
  static const Color lavenderContainer = Color(0xFFEDE7F6);

  /// Texto principal — marrón cálido oscuro, nunca negro puro.
  static const Color warmCharcoal = Color(0xFF3D3835);

  /// Texto de cuerpo — ligeramente más suave que el principal.
  static const Color softCharcoal = Color(0xFF4A4540);

  /// Texto secundario / hints — apagado, no distrae.
  static const Color mutedText = Color(0xFF8C8580);

  /// Error — rosa suave, no rojo agresivo.
  static const Color errorMuted = Color(0xFFD97070);

  /// Borde principal — casi invisible, solo delimita.
  static const Color outlineSoft = Color(0xFFD4CFC8);

  /// Borde variante — para estados normales de inputs.
  static const Color outlineVariant = Color(0xFFE8E4DE);

  /// Superficie variante — fondos de inputs y chips.
  static const Color surfaceVariant = Color(0xFFF0EDE8);

  // ────────────────────────────────────────────────────────────────────────────
  // RADIOS DE BORDE — Soft UI: sin esquinas duras
  // ────────────────────────────────────────────────────────────────────────────

  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // ────────────────────────────────────────────────────────────────────────────
  // SOMBRAS — etéreas, difuminadas, sin dureza
  // ────────────────────────────────────────────────────────────────────────────

  /// Sombra mínima para cards en reposo.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: warmCharcoal.withOpacity(0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: warmCharcoal.withOpacity(0.03),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Sombra media para modales o cards elevadas.
  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: warmCharcoal.withOpacity(0.10),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // ────────────────────────────────────────────────────────────────────────────
  // DECORACIONES REUTILIZABLES
  // ────────────────────────────────────────────────────────────────────────────

  /// Decoración estándar de card con radio grande y sombra suave.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: softShadow,
      );

  /// Decoración sutil para contenedores secundarios (sin sombra).
  static BoxDecoration get subtleDecoration => BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(radiusMedium),
      );

  /// Decoración de accent container (fondo tintado del primario).
  static BoxDecoration get accentDecoration => BoxDecoration(
        color: softBlueContainer,
        borderRadius: BorderRadius.circular(radiusMedium),
      );

  // ────────────────────────────────────────────────────────────────────────────
  // PUNTO DE ENTRADA PÚBLICO
  // ────────────────────────────────────────────────────────────────────────────

  /// Retorna el [ThemeData] completo listo para `MaterialApp.theme`.
  static ThemeData getTheme() {
    final colorScheme = _buildColorScheme();
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: warmCream,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: warmCream,
        foregroundColor: warmCharcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: warmCharcoal,
          letterSpacing: 0.1,
        ),
        iconTheme: const IconThemeData(color: warmCharcoal, size: 24),
        actionsIconTheme: const IconThemeData(color: softCharcoal, size: 24),
      ),

      // ── Cards ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),

      // ── ElevatedButton ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: outlineSoft,
          disabledForegroundColor: mutedText,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── FilledButton ─────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: softBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: softBlue,
          disabledForegroundColor: mutedText,
          side: const BorderSide(color: softBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── TextButton ───────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: softBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── InputDecoration ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: outlineVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: softBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorMuted, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorMuted, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          color: mutedText,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.nunito(
          color: softCharcoal,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.nunito(
          color: softBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: GoogleFonts.nunito(
          color: errorMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
      ),

      // ── NavigationBar (M3) ───────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        indicatorColor: softBlueContainer,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: softBlueDark, size: 24);
          }
          return const IconThemeData(color: mutedText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: softBlueDark,
            );
          }
          return GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: mutedText,
          );
        }),
      ),

      // ── BottomNavigationBar (legacy) ─────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: softBlue,
        unselectedItemColor: mutedText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: softBlueContainer,
        disabledColor: outlineVariant,
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: softCharcoal,
        ),
        side: const BorderSide(color: outlineVariant, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: warmCharcoal,
          letterSpacing: 0.1,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: softCharcoal,
          height: 1.65,
        ),
      ),

      // ── BottomSheet ──────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        modalBackgroundColor: surfaceWhite,
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusXLarge),
            topRight: Radius.circular(radiusXLarge),
          ),
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: warmCharcoal,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: warmCream,
        ),
        actionTextColor: softBlueContainer,
      ),

      // ── FloatingActionButton ─────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: softBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        splashColor: softBlueDark.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: warmCharcoal,
        ),
        subtitleTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mutedText,
          height: 1.5,
        ),
        iconColor: mutedText,
      ),

      // ── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return softBlue;
          return mutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return softBlueContainer;
          return outlineVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return softBlue;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: outlineSoft, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      // ── Radio ─────────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return softBlue;
          return mutedText;
        }),
      ),

      // ── ProgressIndicator ────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: softBlue,
        linearTrackColor: softBlueContainer,
        circularTrackColor: softBlueContainer,
        linearMinHeight: 6,
      ),

      // ── Slider ───────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: softBlue,
        inactiveTrackColor: softBlueContainer,
        thumbColor: softBlue,
        overlayColor: softBlue.withOpacity(0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),

      // ── TabBar ───────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: softBlueDark,
        unselectedLabelColor: mutedText,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: softBlueContainer,
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        labelStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: warmCharcoal.withOpacity(0.88),
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: warmCream,
        ),
      ),

      // ── PopupMenu ─────────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceWhite,
        elevation: 4,
        shadowColor: warmCharcoal.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: warmCharcoal,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // COLOR SCHEME — Material 3
  // ────────────────────────────────────────────────────────────────────────────

  static ColorScheme _buildColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,

      // Primario — Azul pastel calmante
      primary: softBlue,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: softBlueContainer,
      onPrimaryContainer: Color(0xFF1A4A6B),

      // Secundario — Verde salvia
      secondary: sageGreen,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: sageGreenContainer,
      onSecondaryContainer: Color(0xFF1C3D1A),

      // Terciario — Lavanda suave
      tertiary: softLavender,
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: lavenderContainer,
      onTertiaryContainer: Color(0xFF3A2D5C),

      // Error — rosa suave, sin agresividad
      error: errorMuted,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFBE9E9),
      onErrorContainer: Color(0xFF7A2020),

      // Superficies
      surface: surfaceWhite,
      onSurface: softCharcoal,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: Color(0xFF6B6560),

      // Bordes y misc
      outline: outlineSoft,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: warmCharcoal,
      onInverseSurface: warmCream,
      inversePrimary: Color(0xFFADD3E8),
      surfaceTint: softBlue,

      // Background (alias de surface en M3)
      background: warmCream,
      onBackground: warmCharcoal,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TEXT THEME — Nunito: redondeada, amigable, alta legibilidad
  // ────────────────────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // ── Display — pantallas de bienvenida, onboarding ──────────────────────
      displayLarge: GoogleFonts.nunito(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        color: warmCharcoal,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        color: warmCharcoal,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: warmCharcoal,
        height: 1.22,
      ),

      // ── Headline — títulos de sección principales ──────────────────────────
      headlineLarge: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: warmCharcoal,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: warmCharcoal,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: warmCharcoal,
        height: 1.33,
      ),

      // ── Title — cards, drawers, listas ────────────────────────────────────
      titleLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: warmCharcoal,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: warmCharcoal,
        height: 1.50,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: warmCharcoal,
        height: 1.43,
      ),

      // ── Body — texto de lectura principal, line-height amplio ─────────────
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: softCharcoal,
        height: 1.75,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: softCharcoal,
        height: 1.71,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: mutedText,
        height: 1.67,
      ),

      // ── Label — botones, chips, badges ────────────────────────────────────
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: warmCharcoal,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: softCharcoal,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: mutedText,
        height: 1.45,
      ),
    );
  }
}
