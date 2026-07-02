// ============================================================
// lib/features/tea_board/screens/pictogram_crop_page.dart
// ============================================================
// Cropper Flutter puro que reemplaza image_cropper (UCrop nativo).
//
// UCrop no respetaba el SafeArea del dispositivo: el botón ✓ quedaba
// oculto bajo la status bar y el slider de zoom chocaba con la barra
// de navegación. Aquí el SafeArea envuelve todo el layout.
//
// Interacción:
//   - Arrastrar → reposicionar la imagen dentro del cuadro
//   - Pellizcar → zoom (1× – 4×)
//   - "Usar esta foto" → recorta los píxeles con dart:ui → File PNG 512×512
//
// La imagen siempre LLENA el cuadro (escala "cover") para que no haya
// bordes negros en los laterales.
// ============================================================
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PictogramCropPage extends StatefulWidget {
  final File imageFile;

  const PictogramCropPage({super.key, required this.imageFile});

  /// Abre el cropper a pantalla completa.
  /// Retorna el [File] recortado (PNG 512×512) o null si el usuario canceló.
  static Future<File?> show(BuildContext context, File imageFile) {
    return Navigator.of(context).push<File?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PictogramCropPage(imageFile: imageFile),
      ),
    );
  }

  @override
  State<PictogramCropPage> createState() => _PictogramCropPageState();
}

class _PictogramCropPageState extends State<PictogramCropPage> {
  ui.Image? _srcImage;
  bool _loading = true;
  bool _saving  = false;

  // Estado de pan y zoom que el usuario controla con gestos
  Offset _pan  = Offset.zero;
  double _zoom = 1.0;

  Offset? _lastFocalPoint;
  double  _zoomAtGestureStart = 1.0;

  static const double _minZoom = 1.0;
  static const double _maxZoom = 4.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _srcImage?.dispose();
    super.dispose();
  }

  // ── Carga de imagen en dart:ui ────────────────────────────────────────────

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _srcImage = frame.image;
        _loading  = false;
      });
    }
  }

  // ── Gestos ────────────────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _lastFocalPoint     = d.localFocalPoint;
    _zoomAtGestureStart = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, double cropSide) {
    if (_srcImage == null) return;
    setState(() {
      // Zoom: se aplica sobre el zoom al inicio del gesto
      _zoom = (_zoomAtGestureStart * d.scale).clamp(_minZoom, _maxZoom);

      // Pan: acumula el desplazamiento del punto focal
      if (_lastFocalPoint != null) {
        _pan += d.localFocalPoint - _lastFocalPoint!;
      }
      _lastFocalPoint = d.localFocalPoint;

      // Limita el pan para que la imagen no deje bordes vacíos
      _clampPan(cropSide);
    });
  }

  // Escala "cover": la imagen siempre llena el cuadrado de recorte.
  // max(...) en vez de min(...) garantiza que al menos una dimensión
  // llene el cuadrado exactamente y la otra lo sobrepase.
  double _baseScale(double cropSide) {
    if (_srcImage == null) return 1.0;
    return max(
      cropSide / _srcImage!.width,
      cropSide / _srcImage!.height,
    );
  }

  void _clampPan(double cropSide) {
    if (_srcImage == null) return;
    final base   = _baseScale(cropSide);
    final dispW  = _srcImage!.width  * base * _zoom;
    final dispH  = _srcImage!.height * base * _zoom;
    final maxX   = max(0.0, (dispW - cropSide) / 2);
    final maxY   = max(0.0, (dispH - cropSide) / 2);
    _pan = Offset(
      _pan.dx.clamp(-maxX, maxX),
      _pan.dy.clamp(-maxY, maxY),
    );
  }

  // ── Recorte y guardado ────────────────────────────────────────────────────

  Future<void> _confirm(double cropSide) async {
    if (_srcImage == null) return;
    setState(() => _saving = true);

    try {
      final imgW  = _srcImage!.width.toDouble();
      final imgH  = _srcImage!.height.toDouble();
      final base  = _baseScale(cropSide);
      final total = base * _zoom;

      // Esquina superior-izquierda de la imagen en coordenadas de display
      final imgLeft = (cropSide - imgW * total) / 2 + _pan.dx;
      final imgTop  = (cropSide - imgH * total) / 2 + _pan.dy;

      // Rectángulo de recorte en píxeles de la imagen original
      final srcX    = (-imgLeft / total).clamp(0.0, imgW - 1.0).toDouble();
      final srcY    = (-imgTop  / total).clamp(0.0, imgH - 1.0).toDouble();
      final srcSize = (cropSide / total)
          .clamp(1.0, min(imgW - srcX, imgH - srcY))
          .toDouble();

      // Renderizar a 512×512 usando dart:ui
      const outSize = 512.0;
      final recorder = ui.PictureRecorder();
      Canvas(recorder, const Rect.fromLTWH(0, 0, outSize, outSize))
          .drawImageRect(
            _srcImage!,
            Rect.fromLTWH(srcX, srcY, srcSize, srcSize),
            const Rect.fromLTWH(0, 0, outSize, outSize),
            Paint()..filterQuality = FilterQuality.high,
          );

      final croppedImg = await recorder.endRecording()
          .toImage(outSize.toInt(), outSize.toInt());
      final byteData = await croppedImg.toByteData(
          format: ui.ImageByteFormat.png);
      croppedImg.dispose();

      final dir  = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/picto_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      if (mounted) Navigator.of(context).pop(file);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo recortar. Intenta de nuevo.')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    // El cuadro de recorte ocupa todo el ancho disponible,
    // dejando espacio para la barra superior, el hint y el botón.
    final cropSide = min(
      mq.size.width - 24.0,
      mq.size.height - mq.padding.top - mq.padding.bottom - 176.0,
    ).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            // ── Barra superior ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(null),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Encuadrar pictograma',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // Espacio simétrico al botón Cancelar (~90 px)
                  const SizedBox(width: 90),
                ],
              ),
            ),

            // ── Cuadro de recorte ──────────────────────────────────
            Expanded(
              child: Center(
                child: _loading || _srcImage == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart:  _onScaleStart,
                        onScaleUpdate: (d) => _onScaleUpdate(d, cropSide),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width:  cropSide,
                            height: cropSide,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                // Imagen de fondo (pan + zoom)
                                painter: _ImagePainter(
                                  image: _srcImage!,
                                  pan:   _pan,
                                  zoom:  _zoom,
                                ),
                                // Cuadrícula superpuesta (foregroundPainter)
                                foregroundPainter: _GridPainter(),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // ── Indicación gestual ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_with_rounded,
                      color: Colors.white38, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'Arrastra · Pellizca para hacer zoom',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Botón confirmar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_saving || _loading)
                      ? null
                      : () => _confirm(cropSide),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8ED6),
                    disabledBackgroundColor:
                        const Color(0xFF5B8ED6).withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 24),
                  label: Text(
                    _saving ? 'Procesando...' : 'Usar esta foto',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painter: imagen con cobertura total (sin bordes negros) ─────────────────

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final Offset   pan;
  final double   zoom;

  const _ImagePainter({
    required this.image,
    required this.pan,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imgW  = image.width.toDouble();
    final imgH  = image.height.toDouble();
    // "cover": escala mínima que garantiza que la imagen llene el cuadrado
    final base  = max(size.width / imgW, size.height / imgH);
    final scale = base * zoom;
    final left  = (size.width  - imgW * scale) / 2 + pan.dx;
    final top   = (size.height - imgH * scale) / 2 + pan.dy;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromLTWH(left, top, imgW * scale, imgH * scale),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter old) =>
      old.pan != pan || old.zoom != zoom || old.image != image;
}

// ─── Painter: cuadrícula de regla de tercios + borde del marco ───────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Líneas de regla de tercios
    final linePaint = Paint()
      ..color       = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 2; i++) {
      final x = size.width  * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y),  linePaint);
    }

    // Esquinas del marco (L-shapes en las 4 esquinas)
    final cornerPaint = Paint()
      ..color       = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    const arm = 22.0; // longitud de cada brazo de la L

    // Superior-izquierda
    canvas.drawLine(Offset(0, arm), Offset.zero, cornerPaint);
    canvas.drawLine(Offset(0, 0), Offset(arm, 0), cornerPaint);
    // Superior-derecha
    canvas.drawLine(
        Offset(size.width - arm, 0), Offset(size.width, 0), cornerPaint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, arm), cornerPaint);
    // Inferior-izquierda
    canvas.drawLine(
        Offset(0, size.height - arm), Offset(0, size.height), cornerPaint);
    canvas.drawLine(
        Offset(0, size.height), Offset(arm, size.height), cornerPaint);
    // Inferior-derecha
    canvas.drawLine(
        Offset(size.width - arm, size.height),
        Offset(size.width, size.height),
        cornerPaint);
    canvas.drawLine(
        Offset(size.width, size.height - arm),
        Offset(size.width, size.height),
        cornerPaint);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
