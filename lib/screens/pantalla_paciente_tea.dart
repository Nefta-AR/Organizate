// lib/screens/pantalla_paciente_tea.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─── Modelo de datos ───────────────────────────────────────────────────────────

class _PictogramaData {
  final String svgAsset;
  final String label;
  final String ttsTexto;

  const _PictogramaData({
    required this.svgAsset,
    required this.label,
    required this.ttsTexto,
  });
}

// ─── Constantes de pictogramas ─────────────────────────────────────────────────

const _emergencias = [
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/ayuda.svg',
    label: 'AYUDA',
    ttsTexto: 'Necesito ayuda',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/alto.svg',
    label: 'ALTO',
    ttsTexto: 'Por favor, para',
  ),
];

const _pictogramasManana = [
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/cepillar-dientes.svg',
    label: 'DIENTES',
    ttsTexto: 'Debo cepillarme los dientes',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/colegio.svg',
    label: 'COLEGIO',
    ttsTexto: 'Es hora de ir al colegio',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/baño.svg',
    label: 'BAÑO',
    ttsTexto: 'Quiero ir al baño',
  ),
];

const _pictogramasTarde = [
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/almuerzo.svg',
    label: 'ALMUERZO',
    ttsTexto: 'Tengo hambre, quiero almorzar',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/calle.svg',
    label: 'CALLE',
    ttsTexto: 'Quiero salir a la calle',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/beber.svg',
    label: 'AGUA',
    ttsTexto: 'Tengo sed, quiero agua',
  ),
];

const _pictogramasNoche = [
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/casa.svg',
    label: 'CASA',
    ttsTexto: 'Quiero ir a casa',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/cansado.svg',
    label: 'CANSADO',
    ttsTexto: 'Estoy cansado',
  ),
  _PictogramaData(
    svgAsset: 'assets/images/pictogramas/baño.svg',
    label: 'BAÑO',
    ttsTexto: 'Quiero ir al baño',
  ),
];

// ─── Franjas horarias ──────────────────────────────────────────────────────────

enum _Franja { manana, tarde, noche }

// ─── Widget principal ──────────────────────────────────────────────────────────

class PantallaPacienteTEA extends StatefulWidget {
  const PantallaPacienteTEA({super.key});

  @override
  State<PantallaPacienteTEA> createState() => _PantallaPacienteTEAState();
}

class _PantallaPacienteTEAState extends State<PantallaPacienteTEA> {
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('es-ES');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _hablar(String texto) async {
    await _tts.stop();
    await _tts.speak(texto);
  }

  // ── Getters de franja ────────────────────────────────────────────────────────

  _Franja get _franjaActual {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return _Franja.manana;
    if (h >= 12 && h < 18) return _Franja.tarde;
    return _Franja.noche;
  }

  String get _saludo {
    switch (_franjaActual) {
      case _Franja.manana:
        return 'Buenos días';
      case _Franja.tarde:
        return 'Buenas tardes';
      case _Franja.noche:
        return 'Buenas noches';
    }
  }

  String get _tituloFranja {
    switch (_franjaActual) {
      case _Franja.manana:
        return 'Rutina de la Mañana';
      case _Franja.tarde:
        return 'Rutina de la Tarde';
      case _Franja.noche:
        return 'Rutina de la Noche';
    }
  }

  String get _iconoFranja {
    switch (_franjaActual) {
      case _Franja.manana:
        return '☀️';
      case _Franja.tarde:
        return '🌤️';
      case _Franja.noche:
        return '🌙';
    }
  }

  List<_PictogramaData> get _pictogramasDinamicos {
    switch (_franjaActual) {
      case _Franja.manana:
        return _pictogramasManana;
      case _Franja.tarde:
        return _pictogramasTarde;
      case _Franja.noche:
        return _pictogramasNoche;
    }
  }

  // surfaceVariant → crema cálida (mañana)
  // secondaryContainer → verde salvia (tarde)
  // tertiaryContainer → lavanda (noche)
  Color _tinteFranja(ColorScheme cs) {
    switch (_franjaActual) {
      case _Franja.manana:
        return cs.surfaceVariant;
      case _Franja.tarde:
        return cs.secondaryContainer;
      case _Franja.noche:
        return cs.tertiaryContainer;
    }
  }

  Color _accentFranja(ColorScheme cs) {
    switch (_franjaActual) {
      case _Franja.manana:
        return cs.primary;
      case _Franja.tarde:
        return cs.secondary;
      case _Franja.noche:
        return cs.tertiary;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_saludo),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── EMERGENCIAS (fija) ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'EMERGENCIAS',
                  style: tt.labelMedium?.copyWith(
                    color: cs.error,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: List.generate(_emergencias.length, (i) {
                  final p = _emergencias[i];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < _emergencias.length - 1 ? 12 : 0,
                      ),
                      child: _BotonPictograma(
                        data: p,
                        onTap: () => _hablar(p.ttsTexto),
                        isEmergency: true,
                        height: 130,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // ── RUTINA DINÁMICA (expandida) ───────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _tinteFranja(cs),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de sección
                      Row(
                        children: [
                          Text(
                            _iconoFranja,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _tituloFranja,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid de pictogramas
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                          children: _pictogramasDinamicos
                              .map(
                                (p) => _BotonPictograma(
                                  data: p,
                                  onTap: () => _hablar(p.ttsTexto),
                                  isEmergency: false,
                                  franjaAccent: _accentFranja(cs),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón / Tarjeta de pictograma ─────────────────────────────────────────────

class _BotonPictograma extends StatelessWidget {
  final _PictogramaData data;
  final VoidCallback onTap;
  final bool isEmergency;
  final double? height;

  // Solo se usa cuando isEmergency == false; se mapea a la franja activa.
  final Color? franjaAccent;

  const _BotonPictograma({
    required this.data,
    required this.onTap,
    required this.isEmergency,
    this.height,
    this.franjaAccent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Color accent = isEmergency ? cs.error : (franjaAccent ?? cs.primary);

    final bgColor = isEmergency ? cs.errorContainer : cs.surface;
    final borderColor = accent.withOpacity(0.22);
    final shadowColor = cs.shadow.withOpacity(0.05);
    final labelBg = accent.withOpacity(0.09);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SvgPicture.asset(
                  data.svgAsset,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Text(
                data.label,
                textAlign: TextAlign.center,
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.8,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
