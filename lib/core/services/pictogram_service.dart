import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Modelo inmutable de un pictograma personalizado almacenado en Firestore.
///
/// La distinción entre [imageUrl] (URL de Storage o asset) y el campo
/// `svgPath` del modelo [PictoEntry] existe porque los pictogramas
/// personalizados siempre son imágenes subidas (JPEG), mientras que los
/// pictogramas del banco predefinido son SVG locales.
class PictogramaPersonalizado {
  final String id;
  final String imageUrl;
  final String etiqueta;
  final String textoTts;   // Texto que se envía al motor TTS al activar el pictograma
  final String categoria;
  final DateTime createdAt;

  const PictogramaPersonalizado({
    required this.id,
    required this.imageUrl,
    required this.etiqueta,
    required this.textoTts,
    required this.categoria,
    required this.createdAt,
  });

  factory PictogramaPersonalizado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PictogramaPersonalizado(
      id:        doc.id,
      imageUrl:  data['imageUrl']  as String?   ?? '',
      etiqueta:  data['etiqueta']  as String?   ?? '',
      textoTts:  data['textoTts']  as String?   ?? '',
      categoria: data['categoria'] as String?   ?? 'Personalizado',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl':  imageUrl,
      'etiqueta':  etiqueta,
      'textoTts':  textoTts,
      'categoria': categoria,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Servicio estático para la gestión completa del ciclo de vida de pictogramas.
///
/// Cubre dos tipos de operaciones:
///   - **Pictogramas personalizados** (`pictograms/`): imágenes tomadas con
///     cámara o galería, recortadas a 1:1, subidas a Firebase Storage y
///     referenciadas en Firestore.
///   - **Configuración del banco predefinido** (`pictogramSettings/`): mapa de
///     sobreescrituras de categoría y visibilidad para los pictogramas SVG
///     del banco estático. Esto permite personalizar sin duplicar datos.
///
/// Las operaciones `*For(userId)` permiten al tutor leer y escribir datos
/// del usuario vinculado con los mismos métodos que el propio usuario.
class PictogramService {
  PictogramService._();

  static final _storage  = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth      = FirebaseAuth.instance;
  static final _picker    = ImagePicker();

  static String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');
    return user.uid;
  }

  // Referencia al usuario actual (para operaciones propias)
  static CollectionReference<Map<String, dynamic>> get _pictogramsRef =>
      _firestore.collection('users').doc(_userId).collection('pictograms');

  // Referencia a cualquier usuario (para operaciones del tutor)
  static CollectionReference<Map<String, dynamic>> _pictogramsRefFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('pictograms');

  // ─────────────────────────────────────────────────────────────
  // CONSULTAS
  // ─────────────────────────────────────────────────────────────

  /// Stream en tiempo real de pictogramas personalizados del usuario.
  /// Ordenados por fecha de creación descendente (más reciente primero).
  static Stream<List<PictogramaPersonalizado>> getCustomPictogramsStreamFor(String userId) {
    return _pictogramsRefFor(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PictogramaPersonalizado.fromFirestore).toList());
  }

  static Stream<List<PictogramaPersonalizado>> getCustomPictogramsStream() {
    return _pictogramsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PictogramaPersonalizado.fromFirestore(doc))
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // CREACIÓN (sin imagen — para pictogramas del banco del tutor)
  // ─────────────────────────────────────────────────────────────

  /// Crea un pictograma usando una URL de asset o Storage ya existente.
  /// Usado por el tutor cuando selecciona del banco predefinido SVG.
  static Future<PictogramaPersonalizado> createPictogramFor({
    required String userId,
    required String etiqueta,
    required String textoTts,
    String imageUrl  = '',
    String categoria = 'Personalizado',
  }) async {
    final docRef = await _pictogramsRefFor(userId).add({
      'imageUrl':  imageUrl,
      'etiqueta':  etiqueta.trim().toUpperCase(),
      'textoTts':  textoTts.trim(),
      'categoria': categoria,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return PictogramaPersonalizado.fromFirestore(doc);
  }

  // ─────────────────────────────────────────────────────────────
  // CONFIGURACIÓN: categoría y visibilidad por pictograma del banco
  // ─────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _settingsRefFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('pictogramSettings');

  /// Stream del mapa `{pictoId → {categoria, visible}}` para un usuario.
  /// Usando un Map en lugar de lista evita búsquedas O(n) en la UI.
  static Stream<Map<String, Map<String, dynamic>>> getPictogramSettingsStreamFor(String userId) {
    return _settingsRefFor(userId).snapshots().map(
      (s) => {for (final doc in s.docs) doc.id: doc.data()},
    );
  }

  /// Actualiza parcialmente la configuración de un pictograma con `merge: true`
  /// para no sobreescribir campos no incluidos en la llamada.
  static Future<void> updatePictogramSettingFor({
    required String userId,
    required String pictoId,
    String? categoria,
    bool?   visible,
  }) async {
    final updates = <String, dynamic>{};
    if (categoria != null) updates['categoria'] = categoria;
    if (visible != null)   updates['visible']   = visible;
    if (updates.isEmpty) return;
    await _settingsRefFor(userId).doc(pictoId).set(updates, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────────
  // ELIMINACIÓN (imagen en Storage + documento en Firestore)
  // ─────────────────────────────────────────────────────────────

  /// Elimina el pictograma y su imagen de Storage.
  /// La eliminación de Storage falla silenciosamente si la URL
  /// ya no existe o es una URL de asset local.
  static Future<void> deletePictogramFor(String userId, String pictogramId) async {
    final docRef = _pictogramsRefFor(userId).doc(pictogramId);
    final doc    = await docRef.get();
    if (doc.exists) {
      final imageUrl = doc.data()?['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {
          // La imagen puede no existir en Storage si era un asset local
        }
      }
    }
    await docRef.delete();
  }

  static Future<void> deletePictogram(String pictogramId) async {
    final docRef = _pictogramsRef.doc(pictogramId);
    final doc    = await docRef.get();

    if (doc.exists) {
      final imageUrl = doc.data()?['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {
          debugPrint('No se pudo eliminar la imagen de Storage.');
        }
      }
    }

    await docRef.delete();
  }

  // ─────────────────────────────────────────────────────────────
  // CAPTURA Y PROCESAMIENTO DE IMAGEN
  // ─────────────────────────────────────────────────────────────

  /// Calidad 85% y máximo 1024px: balance entre tamaño de archivo y
  /// fidelidad visual para pictogramas en pantalla a ~100px.
  static Future<XFile?> pickImageFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth:  1024,
      maxHeight: 1024,
    );
  }

  static Future<XFile?> pickImageFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth:  1024,
      maxHeight: 1024,
    );
  }

  /// Fuerza recorte cuadrado 1:1 para que todos los pictogramas tengan
  /// las mismas dimensiones en el tablero TEA (grid uniforme).
  static Future<CroppedFile?> cropImage({
    required String imagePath,
    int maxWidth  = 512,
    int maxHeight = 512,
  }) async {
    return ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle:              'Recortar pictograma',
          toolbarColor:              const Color(0xFF7BB3D0),
          toolbarWidgetColor:        Colors.white,
          initAspectRatio:           CropAspectRatioPreset.square,
          lockAspectRatio:           true,
          hideBottomControls:        false,
          showCropGrid:              true,
          statusBarLight:            true,
          activeControlsWidgetColor: const Color(0xFF7BB3D0),
          dimmedLayerColor:          Colors.black.withValues(alpha: 0.5),
          cropFrameColor:            const Color(0xFF7BB3D0),
          cropGridColor:             Colors.white.withValues(alpha: 0.6),
          cropFrameStrokeWidth:      3,
          cropGridRowCount:          3,
          cropGridColumnCount:       3,
        ),
        IOSUiSettings(
          title:                  'Recortar pictograma',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          doneButtonTitle:        '✅ Listo',
          cancelButtonTitle:      'Cancelar',
        ),
      ],
      compressQuality: 80,
      maxWidth:        maxWidth,
      maxHeight:       maxHeight,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SUBIDA A FIREBASE STORAGE
  // ─────────────────────────────────────────────────────────────

  /// Sube la imagen al path `users/{uid}/pictograms/{filename}` y retorna
  /// la URL pública de descarga. El metadata custom permite auditar
  /// quién y cuándo subió cada archivo desde la consola de Storage.
  static Future<String> uploadImage({
    required String filePath,
    String? customFileName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('El archivo no existe.');
    }

    final fileName = customFileName ??
        'picto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/$_userId/pictograms/$fileName');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': _userId,
          'createdAt':  DateTime.now().toIso8601String(),
        },
      ),
    );

    final snapshot    = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // ─────────────────────────────────────────────────────────────
  // FLUJO COMPLETO: Captura → Recorte → Subida → Firestore
  // ─────────────────────────────────────────────────────────────

  /// Orquesta todo el proceso de creación de un pictograma personalizado
  /// desde cero. Retorna null si el usuario cancela en cualquier paso.
  static Future<PictogramaPersonalizado?> captureAndCreate({
    required String etiqueta,
    required String textoTts,
    String categoria = 'Personalizado',
    bool useCamera   = true,
  }) async {
    final pickedFile = useCamera
        ? await pickImageFromCamera()
        : await pickImageFromGallery();

    if (pickedFile == null) return null;

    final cropped = await cropImage(imagePath: pickedFile.path);
    if (cropped == null) return null;

    final downloadUrl = await uploadImage(filePath: cropped.path);

    return createPictogram(
      imageUrl:  downloadUrl,
      etiqueta:  etiqueta,
      textoTts:  textoTts,
      categoria: categoria,
    );
  }

  static Future<PictogramaPersonalizado> createPictogram({
    required String imageUrl,
    required String etiqueta,
    required String textoTts,
    String categoria = 'Personalizado',
  }) async {
    final docRef = await _pictogramsRef.add({
      'imageUrl':  imageUrl,
      'etiqueta':  etiqueta.trim().toUpperCase(),
      'textoTts':  textoTts.trim(),
      'categoria': categoria,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return PictogramaPersonalizado.fromFirestore(doc);
  }
}
