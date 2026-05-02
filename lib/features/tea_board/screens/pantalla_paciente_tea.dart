// lib/screens/pantalla_paciente_tea.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  List<_PictogramaData> get _pictogramasDinamicos {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 12) return _pictogramasManana;
    if (hora >= 12 && hora < 19) return _pictogramasTarde;
    return _pictogramasNoche;
  }

  String get _tituloFranja {
    final hora = DateTime.now().hour;
    if (hora >= 6 && hora < 12) return 'Buenos días';
    if (hora >= 12 && hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _tituloFranja,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'EMERGENCIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCC3333),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Row(
                children: _emergencias
                    .map((p) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _BotonPictograma(
                              data: p,
                              onTap: () => _hablar(p.ttsTexto),
                              accentColor: const Color(0xFFE53935),
                              height: 130,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFDDDDD8), thickness: 1),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'QUIERO...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: _pictogramasDinamicos
                      .map((p) => _BotonPictograma(
                            data: p,
                            onTap: () => _hablar(p.ttsTexto),
                            accentColor: const Color(0xFF1976D2),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonPictograma extends StatelessWidget {
  final _PictogramaData data;
  final VoidCallback onTap;
  final Color accentColor;
  final double? height;

  const _BotonPictograma({
    required this.data,
    required this.onTap,
    required this.accentColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                  placeholderBuilder: (_) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                data.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
