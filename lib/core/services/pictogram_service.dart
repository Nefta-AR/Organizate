import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class PictogramaPersonalizado {
  final String id;
  final String imageUrl;
  final String etiqueta;
  final String textoTts;
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
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      etiqueta: data['etiqueta'] as String? ?? '',
      textoTts: data['textoTts'] as String? ?? '',
      categoria: data['categoria'] as String? ?? 'Personalizado',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'etiqueta': etiqueta,
      'textoTts': textoTts,
      'categoria': categoria,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class PictogramService {
  PictogramService._();

  static final _storage = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _picker = ImagePicker();

  static String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');
    return user.uid;
  }

  static CollectionReference<Map<String, dynamic>> get _pictogramsRef =>
      _firestore.collection('users').doc(_userId).collection('pictograms');

  static CollectionReference<Map<String, dynamic>> _pictogramsRefFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('pictograms');

  static Stream<List<PictogramaPersonalizado>> getCustomPictogramsStreamFor(String userId) {
    return _pictogramsRefFor(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PictogramaPersonalizado.fromFirestore).toList());
  }

  static Future<PictogramaPersonalizado> createPictogramFor({
    required String userId,
    required String etiqueta,
    required String textoTts,
    String imageUrl = '',
    String categoria = 'Personalizado',
  }) async {
    final docRef = await _pictogramsRefFor(userId).add({
      'imageUrl': imageUrl,
      'etiqueta': etiqueta.trim().toUpperCase(),
      'textoTts': textoTts.trim(),
      'categoria': categoria,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return PictogramaPersonalizado.fromFirestore(doc);
  }

  // ─────────────────────────────────────────────────────────────
  // CONFIGURACIÓN: categoría y visibilidad por pictograma
  // ─────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _settingsRefFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('pictogramSettings');

  static Stream<Map<String, Map<String, dynamic>>> getPictogramSettingsStreamFor(String userId) {
    return _settingsRefFor(userId).snapshots().map(
      (s) => {for (final doc in s.docs) doc.id: doc.data()},
    );
  }

  static Future<void> updatePictogramSettingFor({
    required String userId,
    required String pictoId,
    String? categoria,
    bool? visible,
  }) async {
    final updates = <String, dynamic>{};
    if (categoria != null) updates['categoria'] = categoria;
    if (visible != null) updates['visible'] = visible;
    if (updates.isEmpty) return;
    await _settingsRefFor(userId).doc(pictoId).set(updates, SetOptions(merge: true));
  }

  static Future<void> deletePictogramFor(String userId, String pictogramId) async {
    final docRef = _pictogramsRefFor(userId).doc(pictogramId);
    final doc = await docRef.get();
    if (doc.exists) {
      final imageUrl = doc.data()?['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {}
      }
    }
    await docRef.delete();
  }

  // ─────────────────────────────────────────────────────────────
  // CAPTURA DE IMAGEN
  // ─────────────────────────────────────────────────────────────

  static Future<XFile?> pickImageFromCamera() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
  }

  static Future<XFile?> pickImageFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RECORTE (1:1 cuadrado)
  // ─────────────────────────────────────────────────────────────

  static Future<CroppedFile?> cropImage({
    required String imagePath,
    int maxWidth = 512,
    int maxHeight = 512,
  }) async {
    return ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar pictograma',
          toolbarColor: const Color(0xFF7BB3D0),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          showCropGrid: true,
          statusBarLight: true,
          activeControlsWidgetColor: const Color(0xFF7BB3D0),
          dimmedLayerColor: Colors.black.withValues(alpha: 0.5),
          cropFrameColor: const Color(0xFF7BB3D0),
          cropGridColor: Colors.white.withValues(alpha: 0.6),
          cropFrameStrokeWidth: 3,
          cropGridRowCount: 3,
          cropGridColumnCount: 3,
        ),
        IOSUiSettings(
          title: 'Recortar pictograma',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          doneButtonTitle: '✅ Listo',
          cancelButtonTitle: 'Cancelar',
        ),
      ],
      compressQuality: 80,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SUBIDA A FIREBASE STORAGE
  // ─────────────────────────────────────────────────────────────

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
          'createdAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // ─────────────────────────────────────────────────────────────
  // FIRESTORE: CREAR PICTOGRAMA
  // ─────────────────────────────────────────────────────────────

  static Future<PictogramaPersonalizado> createPictogram({
    required String imageUrl,
    required String etiqueta,
    required String textoTts,
    String categoria = 'Personalizado',
  }) async {
    final docRef = await _pictogramsRef.add({
      'imageUrl': imageUrl,
      'etiqueta': etiqueta.trim().toUpperCase(),
      'textoTts': textoTts.trim(),
      'categoria': categoria,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return PictogramaPersonalizado.fromFirestore(doc);
  }

  // ─────────────────────────────────────────────────────────────
  // FLUJO COMPLETO: Captura → Recorte → Subida → Firestore
  // ─────────────────────────────────────────────────────────────

  static Future<PictogramaPersonalizado?> captureAndCreate({
    required String etiqueta,
    required String textoTts,
    String categoria = 'Personalizado',
    bool useCamera = true,
  }) async {
    final pickedFile = useCamera
        ? await pickImageFromCamera()
        : await pickImageFromGallery();

    if (pickedFile == null) return null;

    final cropped = await cropImage(imagePath: pickedFile.path);
    if (cropped == null) return null;

    final downloadUrl = await uploadImage(filePath: cropped.path);

    return createPictogram(
      imageUrl: downloadUrl,
      etiqueta: etiqueta,
      textoTts: textoTts,
      categoria: categoria,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CONSULTA: Stream de pictogramas personalizados
  // ─────────────────────────────────────────────────────────────

  static Stream<List<PictogramaPersonalizado>> getCustomPictogramsStream() {
    return _pictogramsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PictogramaPersonalizado.fromFirestore(doc))
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // ELIMINAR pictograma (imagen + documento)
  // ─────────────────────────────────────────────────────────────

  static Future<void> deletePictogram(String pictogramId) async {
    final docRef = _pictogramsRef.doc(pictogramId);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      final imageUrl = data?['imageUrl'] as String?;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (_) {
          debugPrint('No se pudo eliminar la imagen de Storage.');
        }
      }
    }

    await docRef.delete();
  }
}
