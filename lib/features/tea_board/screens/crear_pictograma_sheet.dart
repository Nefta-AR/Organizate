import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/pictogram_service.dart';
import '../../../core/theme/app_theme.dart';

class CrearPictogramaSheet extends StatefulWidget {
  const CrearPictogramaSheet({super.key});

  static Future<PictogramaPersonalizado?> show(BuildContext context) {
    return showModalBottomSheet<PictogramaPersonalizado>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CrearPictogramaSheet(),
    );
  }

  @override
  State<CrearPictogramaSheet> createState() => _CrearPictogramaSheetState();
}

class _CrearPictogramaSheetState extends State<CrearPictogramaSheet> {
  File? _imagenSeleccionada;
  final _etiquetaController = TextEditingController();
  final _textoTtsController = TextEditingController();

  bool _procesando = false;
  String _error = '';

  final List<String> _categorias = [
    'Personalizado',
    'Mañana',
    'Tarde',
    'Noche',
    'Comida',
    'Emociones',
    'Acciones',
  ];
  String _categoriaSeleccionada = 'Personalizado';

  @override
  void dispose() {
    _etiquetaController.dispose();
    _textoTtsController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(bool usarCamara) async {
    try {
      final picked = usarCamara
          ? await PictogramService.pickImageFromCamera()
          : await PictogramService.pickImageFromGallery();

      if (picked == null) return;

      final cropped = await PictogramService.cropImage(imagePath: picked.path);
      if (cropped == null) return;

      setState(() {
        _imagenSeleccionada = File(cropped.path);
        _error = '';
      });

      if (_etiquetaController.text.isEmpty) {
        _etiquetaController.text = 'MI FOTO';
      }
      if (_textoTtsController.text.isEmpty) {
        _textoTtsController.text = 'Mira mi foto';
      }
    } catch (e) {
      setState(() => _error = 'No se pudo procesar la imagen.');
    }
  }

  Future<void> _guardarPictograma() async {
    if (_imagenSeleccionada == null) {
      setState(() => _error = 'Primero selecciona una imagen.');
      return;
    }

    if (_etiquetaController.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un nombre para el pictograma.');
      return;
    }

    setState(() {
      _procesando = true;
      _error = '';
    });

    try {
      final downloadUrl = await PictogramService.uploadImage(
        filePath: _imagenSeleccionada!.path,
      );

      final picto = await PictogramService.createPictogram(
        imageUrl: downloadUrl,
        etiqueta: _etiquetaController.text.trim(),
        textoTts: _textoTtsController.text.trim(),
        categoria: _categoriaSeleccionada,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(picto);
      }
    } catch (e) {
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      snap: true,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.warmCream,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXLarge),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildImagenSelector(),
                      if (_imagenSeleccionada != null) ...[
                        const SizedBox(height: 20),
                        _buildPreview(),
                      ],
                      const SizedBox(height: 20),
                      _buildCampoEtiqueta(),
                      const SizedBox(height: 14),
                      _buildCampoTextoTts(),
                      const SizedBox(height: 14),
                      _buildSelectorCategoria(),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildError(),
                      ],
                      const SizedBox(height: 28),
                      _buildBotonGuardar(),
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

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.mutedText.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.softBlueContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.add_a_photo_rounded,
            color: AppTheme.softBlueDark,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
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

  Widget _buildImagenSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildBotonFuente(
            icon: Icons.camera_alt_rounded,
            label: 'Cámara',
            onTap: () => _seleccionarImagen(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBotonFuente(
            icon: Icons.photo_library_rounded,
            label: 'Galería',
            onTap: () => _seleccionarImagen(false),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonFuente({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _procesando ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.outlineSoft,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.softBlue, size: 28),
            const SizedBox(height: 6),
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
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.softBlue.withValues(alpha: 0.3),
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
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
              child: Image.file(
                _imagenSeleccionada!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoEtiqueta() {
    return TextField(
      controller: _etiquetaController,
      decoration: InputDecoration(
        labelText: 'Nombre del pictograma',
        hintText: 'Ej: MI PERRO',
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
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
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _buildCampoTextoTts() {
    return TextField(
      controller: _textoTtsController,
      decoration: InputDecoration(
        labelText: 'Qué dirá la voz',
        hintText: 'Ej: Quiero ver a mi perro',
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categorias.map((cat) {
            final selected = _categoriaSeleccionada == cat;
            return GestureDetector(
              onTap: () => setState(() => _categoriaSeleccionada = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.softBlueContainer
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
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
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.errorMuted.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorMuted, size: 18),
          const SizedBox(width: 8),
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

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _procesando ? null : _guardarPictograma,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.softBlue,
          disabledBackgroundColor: AppTheme.softBlue.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          elevation: 0,
        ),
        icon: _procesando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.save_alt_rounded, size: 20),
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
