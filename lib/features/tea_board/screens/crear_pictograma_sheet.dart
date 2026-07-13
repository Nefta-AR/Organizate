// ============================================================
// lib/features/tea_board/screens/crear_pictograma_sheet.dart
// ============================================================
// Bottom sheet para crear pictogramas personalizados con foto.
//
// ## Flujo de creación
//
//   1. El usuario elige la fuente de imagen:
//        - Galería: ImagePicker.getImage(source: gallery)
//        - Cámara:  ImagePicker.getImage(source: camera)
//   2. La imagen seleccionada pasa por image_cropper para recorte cuadrado.
//   3. El archivo recortado se sube a Firebase Storage via PictogramService.
//   4. PictogramService.createPictogram() escribe el documento en Firestore:
//        users/{uid}/pictogramConfig/{auto-id}
//        con los campos: label, storageUrl, textoTts, categoria, isCustom:true
//   5. El sheet se cierra y retorna el [PictogramaPersonalizado] creado.
//
// ## Apertura
//
//   CrearPictogramaSheet.show(context)
//   Método estático con showModalBottomSheet + DraggableScrollableSheet.
//   Retorna Future<PictogramaPersonalizado?> — null si el usuario cancela.
//
// ## Feedback háptico
//
//   HapticFeedback.mediumImpact() al guardar el pictograma exitosamente.
//   Diseñado para usuarios TEA que se benefician del feedback táctil.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/pictogram_service.dart';
import '../../../core/theme/app_theme.dart';
import 'pictogram_crop_page.dart';

class CrearPictogramaSheet extends StatefulWidget {
  /// Si es null, el pictograma se crea para el usuario autenticado.
  /// Si se proporciona, se crea para ese usuario (por ejemplo, un tutor
  /// agregando un pictograma a la cuenta de su paciente).
  final String? targetUserId;

  const CrearPictogramaSheet({super.key, this.targetUserId});

  // Método estático de apertura del sheet.
  // Retorna el pictograma creado, o null si el usuario cerró sin guardar.
  // Usando tipo genérico <PictogramaPersonalizado> para que pop(picto) devuelva
  // el valor correcto al caller en _buildBotonGuardar().
  static Future<PictogramaPersonalizado?> show(
    BuildContext context, {
    String? targetUserId,
  }) {
    return showModalBottomSheet<PictogramaPersonalizado>(
      context: context,
      isScrollControlled: true,    // Permite que el sheet ocupe más del 50% de pantalla
      backgroundColor: Colors.transparent, // El Container interior define el fondo real
      // El Padding dinámico empuja el sheet hacia arriba cuando aparece el teclado,
      // haciendo que los campos de texto queden visibles sobre él.
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CrearPictogramaSheet(targetUserId: targetUserId),
      ),
    );
  }

  @override
  State<CrearPictogramaSheet> createState() => _CrearPictogramaSheetState();
}

class _CrearPictogramaSheetState extends State<CrearPictogramaSheet> {
  // Imagen recortada lista para subir a Storage.
  // null = aún no se ha seleccionado imagen (muestra solo los botones de fuente).
  File? _imagenSeleccionada;

  // Controller del campo de nombre del pictograma (se muestra debajo del mismo).
  // Ejemplo de valor: "MI PERRO" (forzado a mayúsculas con TextCapitalization.characters)
  final _etiquetaController = TextEditingController();

  // Controller del texto que leerá el motor TTS al tocar el pictograma.
  // Ejemplo: "Quiero ver a mi perro" (frases completas para comunicación AAC)
  final _textoTtsController = TextEditingController();

  // true mientras se está subiendo la imagen o escribiendo en Firestore.
  // Deshabilita botones para evitar subidas paralelas.
  bool _procesando = false;

  // Mensaje de error de validación o de Firebase.
  // String vacío ('') significa que no hay error (no usamos nullable para simplificar guards).
  String _error = '';

  // Categorías disponibles para organizar los pictogramas en el tablero.
  // 'Personalizado' es la categoría por defecto para fotos propias del usuario.
  final List<String> _categorias = [
    'Personalizado', // Para imágenes personales sin categoría específica
    'Mañana',        // Rutina de la mañana
    'Tarde',         // Actividades de tarde
    'Noche',         // Rutina nocturna
    'Comida',        // Pictogramas de alimentos
    'Emociones',     // Expresión de estados emocionales
    'Acciones',      // Verbos y actividades
  ];

  // Categoría actualmente seleccionada por el usuario (persiste en Firestore).
  String _categoriaSeleccionada = 'Personalizado';

  // ── Liberación de recursos ────────────────────────────────────────────────────

  @override
  void dispose() {
    // Liberamos los TextEditingControllers para evitar memory leaks
    _etiquetaController.dispose();
    _textoTtsController.dispose();
    super.dispose();
  }

  // ── Selección y recorte de imagen ─────────────────────────────────────────────

  Future<void> _seleccionarImagen(bool usarCamara) async {
    try {
      // Llamamos al método correspondiente del PictogramService según la fuente:
      // - pickImageFromCamera(): abre la cámara del dispositivo
      // - pickImageFromGallery(): abre el selector de archivos del sistema
      final picked = usarCamara
          ? await PictogramService.pickImageFromCamera()
          : await PictogramService.pickImageFromGallery();

      // Si el usuario canceló la selección (null), no hacemos nada
      if (picked == null) return;

      // Cropper Flutter puro: respeta SafeArea, no usa UCrop nativo.
      if (!mounted) return;
      final croppedFile = await PictogramCropPage.show(context, File(picked.path));

      // Si el usuario canceló el recorte, no hacemos nada
      if (croppedFile == null) return;

      setState(() {
        _imagenSeleccionada = croppedFile;
        _error = '';
      });

      // Autorrelleno inteligente: si los campos están vacíos,
      // ponemos valores por defecto para que el usuario no tenga que escribir nada.
      // Es útil para usuarios con dificultades de escritura (característica de accesibilidad).
      if (_etiquetaController.text.isEmpty) {
        _etiquetaController.text = 'MI FOTO'; // Nombre genérico en mayúsculas
      }
      if (_textoTtsController.text.isEmpty) {
        _textoTtsController.text = 'Mira mi foto'; // Frase TTS por defecto
      }

    } catch (e) {
      // Error de permisos de cámara/galería o error de image_cropper
      setState(() => _error = 'No se pudo procesar la imagen.');
    }
  }

  // ── Guardar el pictograma en Storage y Firestore ─────────────────────────────

  Future<void> _guardarPictograma() async {
    // Validación 1: debe haber una imagen seleccionada y recortada
    if (_imagenSeleccionada == null) {
      setState(() => _error = 'Primero selecciona una imagen.');
      return;
    }

    // Validación 2: el nombre del pictograma no puede estar vacío
    // (el tablero usa la etiqueta para identificar visualmente el pictograma)
    if (_etiquetaController.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un nombre para el pictograma.');
      return;
    }

    // Activamos el estado de procesamiento y limpiamos errores previos
    setState(() {
      _procesando = true;
      _error = '';
    });

    try {
      final targetUserId = widget.targetUserId;

      // Paso 1: subimos la imagen a Firebase Storage.
      // Si hay targetUserId, el archivo se guarda en su carpeta (tutor → paciente).
      final downloadUrl = targetUserId != null
          ? await PictogramService.uploadImageFor(
              userId: targetUserId,
              filePath: _imagenSeleccionada!.path,
            )
          : await PictogramService.uploadImage(
              filePath: _imagenSeleccionada!.path,
            );

      // Paso 2: creamos el documento en Firestore con todos los campos del pictograma.
      final picto = targetUserId != null
          ? await PictogramService.createPictogramFor(
              userId: targetUserId,
              imageUrl: downloadUrl,
              etiqueta: _etiquetaController.text.trim(),
              textoTts: _textoTtsController.text.trim(),
              categoria: _categoriaSeleccionada,
            )
          : await PictogramService.createPictogram(
              imageUrl: downloadUrl,
              etiqueta: _etiquetaController.text.trim(),
              textoTts: _textoTtsController.text.trim(),
              categoria: _categoriaSeleccionada,
            );

      if (mounted) {
        // Feedback háptico de éxito (pulso medio): refuerzo sensorial para usuarios TEA
        HapticFeedback.mediumImpact();

        // Cerramos el sheet devolviendo el pictograma creado.
        // El caller en TeaBoardScreen añadirá este pictograma a su lista local sin
        // necesidad de hacer otro read a Firestore.
        Navigator.of(context).pop(picto);
      }

    } catch (e) {
      // Error de Storage (cuota excedida, sin red) o de Firestore (permisos)
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');

    } finally {
      // Siempre apagamos el spinner, aunque el widget haya sido desmontado al hacer pop
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  // ── Construcción del widget principal ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet: permite arrastrar el sheet hacia arriba para revelar
    // más campos cuando el teclado virtual empuje el contenido hacia arriba
    return DraggableScrollableSheet(
      initialChildSize: 0.65, // Ocupa el 65% de la pantalla al abrirse
      minChildSize: 0.45,     // Mínimo 45% (suficiente para ver los botones principales)
      maxChildSize: 0.92,     // Máximo 92% (casi pantalla completa al expandir)
      snap: true,             // Hace clic en posiciones fijas al soltar el arrastre

      builder: (_, scrollController) {
        // Alto de la barra de navegación del sistema (0 con pantalla completa,
        // ~24px con gestos, ~48px con navegación de 3 botones). Se suma al
        // padding inferior para que el botón "Guardar" nunca quede tapado.
        final navBarInset = MediaQuery.of(context).viewPadding.bottom;

        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.warmCream, // Fondo crema cálido (tono AAC accesible)
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXLarge), // Esquinas redondeadas solo arriba
            ),
          ),
          child: Column(
            children: [
              // Barra indicadora de que el sheet es arrastrable
              _buildHandle(),

              // Área scrollable: conectada al scrollController del DraggableScrollableSheet
              // para coordinar el scroll del contenido con el arrastre del sheet
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  // Padding inferior: 40 base + barra de navegación del sistema
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 40 + navBarInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(), // Icono cámara + título + subtítulo
                      const SizedBox(height: 24),

                      _buildImagenSelector(), // Dos botones: Cámara / Galería

                      // La vista previa solo aparece tras seleccionar imagen
                      if (_imagenSeleccionada != null) ...[
                        const SizedBox(height: 20),
                        _buildPreview(), // Miniatura 160x160 de la imagen recortada
                      ],

                      const SizedBox(height: 20),
                      _buildCampoEtiqueta(),     // Campo: nombre del pictograma
                      const SizedBox(height: 14),
                      _buildCampoTextoTts(),     // Campo: texto para la voz
                      const SizedBox(height: 14),
                      _buildSelectorCategoria(), // Chips de categorías

                      // Banner de error solo visible si _error no está vacío
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildError(),
                      ],

                      const SizedBox(height: 28),
                      _buildBotonGuardar(), // Botón de acción principal
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Barra drag indicator ──────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          // Semitransparente: aspecto discreto que no compite con el contenido
          color: AppTheme.mutedText.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ── Encabezado con icono y título ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Contenedor cuadrado redondeado con icono de cámara
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.softBlueContainer, // Fondo azul muy suave
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.add_a_photo_rounded, // Icono cámara + signo + (añadir foto)
            color: AppTheme.softBlueDark,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),

        // Título y subtítulo del sheet
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear Pictograma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.warmCharcoal,
              ),
            ),
            Text(
              'Toma una foto o elige de la galería',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Selector de fuente de imagen (Cámara / Galería) ──────────────────────────

  Widget _buildImagenSelector() {
    // Row con dos botones de igual ancho (Expanded) para las dos fuentes
    return Row(
      children: [
        Expanded(
          child: _buildBotonFuente(
            icon: Icons.camera_alt_rounded,
            label: 'Cámara',
            onTap: () => _seleccionarImagen(true), // true = usar cámara
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBotonFuente(
            icon: Icons.photo_library_rounded,
            label: 'Galería',
            onTap: () => _seleccionarImagen(false), // false = usar galería
          ),
        ),
      ],
    );
  }

  // ── Tarjeta de botón de fuente de imagen ─────────────────────────────────────

  Widget _buildBotonFuente({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      // null durante _procesando: evita navegar a cámara mientras se guarda
      onTap: _procesando ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite, // Blanco puro para máximo contraste
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.outlineSoft, // Borde gris muy suave
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), // Sombra casi imperceptible
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icono de la fuente en azul suave (color de acción del tema AAC)
            Icon(icon, color: AppTheme.softBlue, size: 28),
            const SizedBox(height: 6),
            // Texto descriptivo de la fuente
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.softCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vista previa de la imagen seleccionada ────────────────────────────────────

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista previa',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.warmCharcoal,
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: Container(
            width: 160, height: 160,  // Tamaño cuadrado representativo del pictograma final
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.softBlue.withValues(alpha: 0.3), // Borde azul suave
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.softBlue.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              // -2 al radio para que el clip siga la forma del borde exterior
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
              child: Image.file(
                _imagenSeleccionada!,
                fit: BoxFit.cover, // La imagen llena el cuadrado sin dejar bordes blancos
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Campo de texto: nombre del pictograma ─────────────────────────────────────

  Widget _buildCampoEtiqueta() {
    return TextField(
      controller: _etiquetaController,
      // Fuerza mayúsculas en cada carácter: los pictogramas AAC usan texto en mayúsculas
      // para facilitar la lectura a usuarios con dislexia o baja visión
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: 'Nombre del pictograma',
        hintText: 'Ej: MI PERRO',
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none, // Sin borde por defecto (se sobreescribe abajo)
        ),
        // Borde gris suave cuando el campo no está enfocado
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(
            color: AppTheme.outlineVariant,
            width: 1,
          ),
        ),
        // Borde azul más grueso cuando el campo está enfocado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(
            color: AppTheme.softBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Campo de texto: frase que leerá el TTS ───────────────────────────────────

  Widget _buildCampoTextoTts() {
    return TextField(
      controller: _textoTtsController,
      // Sin textCapitalization.characters: el texto TTS puede ser una frase normal
      decoration: InputDecoration(
        labelText: 'Qué dirá la voz',
        hintText: 'Ej: Quiero ver a mi perro',
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        // Misma estética que _buildCampoEtiqueta para coherencia visual
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(
            color: AppTheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(
            color: AppTheme.softBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Chips de selección de categoría ──────────────────────────────────────────

  Widget _buildSelectorCategoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.warmCharcoal,
          ),
        ),
        const SizedBox(height: 8),

        // Wrap: los chips se redistribuyen automáticamente en múltiples líneas
        Wrap(
          spacing: 8,   // Espacio horizontal entre chips
          runSpacing: 8, // Espacio vertical entre filas de chips
          children: _categorias.map((cat) {
            final selected = _categoriaSeleccionada == cat;

            return GestureDetector(
              // Al tocar un chip, actualiza la categoría seleccionada
              onTap: () => setState(() => _categoriaSeleccionada = cat),

              // AnimatedContainer: transiciona suavemente el fondo al seleccionar/deseleccionar
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  // Fondo azul muy suave si está seleccionado, gris si no
                  color: selected
                      ? AppTheme.softBlueContainer
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    // Borde azul si está seleccionado, transparente si no
                    color: selected
                        ? AppTheme.softBlue.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    // Negrita si está seleccionado para mayor énfasis visual
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    // Texto azul oscuro si seleccionado, gris si no
                    color: selected
                        ? AppTheme.softBlueDark
                        : AppTheme.mutedText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Banner de error ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Fondo de error muy suave (8% de opacidad) para no ser alarmante
        color: AppTheme.errorMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.errorMuted.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono de advertencia
          const Icon(Icons.error_outline, color: AppTheme.errorMuted, size: 18),
          const SizedBox(width: 8),
          // Texto de error expandido para evitar overflow
          Expanded(
            child: Text(
              _error,
              style: const TextStyle(
                color: AppTheme.errorMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón principal "Guardar Pictograma" ─────────────────────────────────────

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        // null durante _procesando: evita subidas paralelas
        onPressed: _procesando ? null : _guardarPictograma,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.softBlue,
          // Color deshabilitado: azul semitransparente para feedback visual
          disabledBackgroundColor: AppTheme.softBlue.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          elevation: 0, // Sin sombra para diseño plano coherente con el resto del sheet
        ),

        // El icono cambia a un spinner durante la subida a Storage/Firestore
        icon: _procesando
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.save_alt_rounded, size: 20),

        // El texto cambia para comunicar el estado al usuario
        label: Text(
          _procesando ? 'Guardando...' : 'Guardar Pictograma',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
