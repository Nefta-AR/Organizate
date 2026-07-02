// ============================================================
// lib/core/widgets/celebration_overlay.dart
// ============================================================
// Celebración visual al completar una tarea.
// Sin paquetes externos — usa CustomPainter + AudioPlayer
// (audioplayers ya está en el proyecto).
//
// Uso:
//   CelebrationOverlay.show(context);   // dispara todo
// ============================================================

import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CelebrationOverlay {
  /// Dispara confeti, sonido y vibración. Fire-and-forget.
  static void show(BuildContext context, {String message = '¡Tarea completada! 🎉'}) {
    // Sonido
    _playSound();
    // Vibración (patrón corto-largo-corto = celebración)
    HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationWidget(
        message: message,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static void _playSound() {
    try {
      final player = AudioPlayer();
      player.play(AssetSource('sounds/bell.mp3')).then((_) {
        // Libera el player cuando termina de reproducir
        Future.delayed(const Duration(seconds: 3), player.dispose);
      });
    } catch (_) {
      // Si el sonido falla, la celebración visual sigue igual
    }
  }
}

// ─── Widget principal de la celebración ───────────────────────────────────────

class _CelebrationWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDone;

  const _CelebrationWidget({required this.message, required this.onDone});

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with TickerProviderStateMixin {
  // Animación del confeti (2.4 s)
  late final AnimationController _confettiCtrl;
  // Animación del badge del mensaje (aparece, espera, desaparece)
  late final AnimationController _badgeCtrl;
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeOpacity;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_badgeCtrl);

    _badgeOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_badgeCtrl);

    _confettiCtrl.forward();
    _badgeCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _particles = List.generate(55, (_) => _Particle.random(size));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // ── Confeti ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_particles, _confettiCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),
          // ── Badge del mensaje ───────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _badgeCtrl,
              builder: (_, __) => Opacity(
                opacity: _badgeOpacity.value,
                child: Transform.scale(
                  scale: _badgeScale.value,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8F71),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x336B8F71),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Partícula de confeti ─────────────────────────────────────────────────────

class _Particle {
  final double x;       // posición horizontal inicial
  final double speedY;  // velocidad vertical (pixeles en 1.0 de animación)
  final double driftX;  // desplazamiento horizontal total
  final double size;
  final Color color;
  final double rotation;
  final double rotSpeed;
  final bool isCircle;  // alterna entre cuadrado y círculo

  static final _rng = Random();
  static const _colors = [
    Color(0xFF5B8ED6), // azul
    Color(0xFF6B8F71), // verde
    Color(0xFF7C6FAD), // morado
    Color(0xFFE8703A), // naranja
    Color(0xFFD97070), // rosa
    Color(0xFFFFD700), // dorado
    Color(0xFF4FC3F7), // celeste
  ];

  const _Particle({
    required this.x,
    required this.speedY,
    required this.driftX,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotSpeed,
    required this.isCircle,
  });

  factory _Particle.random(Size screen) => _Particle(
        x: _rng.nextDouble() * screen.width,
        speedY: screen.height * (0.55 + _rng.nextDouble() * 0.55),
        driftX: (_rng.nextDouble() - 0.5) * 120,
        size: 7 + _rng.nextDouble() * 8,
        color: _colors[_rng.nextInt(_colors.length)],
        rotation: _rng.nextDouble() * pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * pi * 6,
        isCircle: _rng.nextBool(),
      );
}

// ─── Painter del confeti ──────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0.0 → 1.0

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final y = -18.0 + p.speedY * t;
      final x = p.x + p.driftX * t;

      // Aparece gradualmente al inicio (primeros 15 % de la animación)
      // y desvanece al final (últimos 25 %)
      double alpha = 1.0;
      if (t < 0.15) alpha = t / 0.15;
      if (t > 0.75) alpha = 1.0 - ((t - 0.75) / 0.25);
      alpha = alpha.clamp(0.0, 1.0);

      if (y > size.height + p.size || alpha <= 0) continue;

      paint.color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotSpeed * t);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
