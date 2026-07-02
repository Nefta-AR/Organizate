// ============================================================
// lib/features/onboarding/screens/feature_tour_screen.dart
// ============================================================
// Mini-tutorial de 5 diapositivas que se muestra una sola vez
// al finalizar el onboarding (WelcomeRewardScreen → FeatureTourScreen
// → HomeScreen).
//
// Cada slide tiene: ícono grande animado, título, descripción corta
// y un hint visual de cómo usar la función.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../tutor_dashboard/screens/home_screen.dart';

class FeatureTourScreen extends StatefulWidget {
  const FeatureTourScreen({super.key});

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<FeatureTourScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnim;
  late Animation<double> _iconScale;

  static const _slides = [
    _TourSlide(
      icon: '✅',
      color: Color(0xFF5B8ED6),
      bgColor: Color(0xFFEBF2FF),
      title: 'Organiza tus tareas',
      description:
          'Agrega tareas por categoría: Estudios, Hogar, Medicamentos o Foco. '
          'Marca las que completes y gana puntos.',
      hint: 'Toca  +  para crear tu primera tarea',
      hintIcon: Icons.add_circle_outline_rounded,
    ),
    _TourSlide(
      icon: '🖼️',
      color: Color(0xFF7C6FAD),
      bgColor: Color(0xFFF3EFFF),
      title: 'Habla con pictogramas',
      description:
          'Toca cualquier imagen y el teléfono hablará por ti. '
          'También puedes crear tus propios pictogramas con la cámara.',
      hint: 'Toca un pictograma → escucharás su voz',
      hintIcon: Icons.touch_app_rounded,
    ),
    _TourSlide(
      icon: '⏱️',
      color: Color(0xFFE8703A),
      bgColor: Color(0xFFFFF0E8),
      title: 'Mantén el foco',
      description:
          'El temporizador Pomodoro te ayuda a trabajar en bloques de tiempo '
          'con descansos. También hay un ejercicio de respiración guiada.',
      hint: 'Elige el tiempo y toca  ▶  para empezar',
      hintIcon: Icons.play_circle_outline_rounded,
    ),
    _TourSlide(
      icon: '✨',
      color: Color(0xFF7C6FAD),
      bgColor: Color(0xFFF3EFFF),
      title: 'Súper Experto IA',
      description:
          '¿Tienes una tarea muy difícil? El asistente de inteligencia artificial '
          'la divide en pasos pequeños y los agrega a tu lista.',
      hint: 'Toca el botón  ✨  en la pantalla de inicio',
      hintIcon: Icons.auto_fix_high_rounded,
    ),
    _TourSlide(
      icon: '💚',
      color: Color(0xFF6B8F71),
      bgColor: Color(0xFFEAF7EE),
      title: 'Conéctate con tu tutor',
      description:
          'Tu cuidador o docente puede supervisarte y ayudarte desde su propio '
          'teléfono. Pídele un código de 6 letras y vincúlense en Ajustes.',
      hint: 'Ajustes  →  Vinculación con tutor',
      hintIcon: Icons.link_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _iconScale = CurvedAnimation(parent: _iconAnim, curve: Curves.elasticOut);
    _iconAnim.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnim.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goHome();
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconAnim.reset();
    _iconAnim.forward();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: slide.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Botón Saltar ───────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goHome,
                child: Text(
                  'Saltar',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: slide.color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(
                  slide: _slides[i],
                  iconAnim: _iconScale,
                  isActive: i == _currentPage,
                ),
              ),
            ),

            // ── Indicadores de página ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? slide.color
                        : slide.color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // ── Botón principal ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: slide.color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isLast ? '¡Empecemos! 🚀' : 'Siguiente →',
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Página individual del slide ────────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _TourSlide slide;
  final Animation<double> iconAnim;
  final bool isActive;

  const _SlidePage({
    required this.slide,
    required this.iconAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Ícono grande animado ─────────────────────────────────────
          ScaleTransition(
            scale: iconAnim,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: slide.color.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(slide.icon, style: const TextStyle(fontSize: 60)),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // ── Título ───────────────────────────────────────────────────
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: slide.color,
            ),
          ),
          const SizedBox(height: 16),

          // ── Descripción ──────────────────────────────────────────────
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 1.55,
              color: const Color(0xFF3D3835).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 28),

          // ── Hint / tip visual ────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: slide.color.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(slide.hintIcon, color: slide.color, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    slide.hint,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: slide.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo de datos de cada slide ─────────────────────────────────────────────
class _TourSlide {
  final String icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String description;
  final String hint;
  final IconData hintIcon;

  const _TourSlide({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.description,
    required this.hint,
    required this.hintIcon,
  });
}
