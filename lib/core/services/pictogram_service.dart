// ============================================================
// lib/core/services/pictogram_service.dart
// ============================================================
// Servicio estático para la gestión completa del ciclo de vida
// de pictogramas personalizados de usuario TEA.
//
// ## Responsabilidades
//
//   1. **CRUD de pictogramas personalizados** — colección Firestore:
//      `users/{uid}/pictograms/`
//      Cada documento contiene: imageUrl, etiqueta, textoTts, categoria,
//      createdAt. La imagen asociada vive en Firebase Storage.
//
//   2. **Configuración del banco predefinido** — colección Firestore:
//      `users/{uid}/pictogramSettings/`
//      Cada documento es un override de categoría o visibilidad para
//      un pictograma del banco estático (SVG). Si no existe el documento,
//      el pictograma usa sus valores predeterminados.
//
//   3. **Captura/selección de imagen** — ImagePicker (cámara o galería).
//
//   4. **Recorte de imagen** — ImageCropper forzado a ratio 1:1.
//
//   5. **Subida a Firebase Storage** — path: `users/{uid}/pictograms/{filename}`.
//
// ## Variantes `*For(userId)` vs. sin sufijo
//
//   Los métodos sin sufijo usan el UID del usuario autenticado actual
//   (_userId). Los métodos `*For(userId)` admiten un UID externo, lo que
//   permite al tutor leer o modificar datos del usuario vinculado con
//   los mismos métodos.
// ============================================================

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

// ─── Modelo ──────────────────────────────────────────────────────────────────

/// Modelo inmutable de un pictograma personalizado almacenado en Firestore.
///
/// La distinción entre [imageUrl] (URL de Storage o asset) y el campo
/// `svgPath` del modelo [PictoEntry] existe porque los pictogramas
/// personalizados siempre son imágenes subidas (JPEG), mientras que los
/// pictogramas del banco predefinido son SVG locales.
class PictogramaPersonalizado {
  final String id;         // ID del documento de Firestore
  final String imageUrl;   // URL de descarga de Firebase Storage (o asset local)
  final String etiqueta;   // Texto visible en el tablero (MAYÚSCULAS)
  final String textoTts;   // Texto que se envía al motor TTS al activar el pictograma
  final String categoria;  // Categoría asignada ('Personalizado', 'Mañana', etc.)
  final DateTime createdAt;// Fecha de creación para ordenar por reciente

  const PictogramaPersonalizado({
    required this.id,
    required this.imageUrl,
    required this.etiqueta,
    required this.textoTts,
    required this.categoria,
    required this.createdAt,
  });

  /// Factory que construye el modelo desde un snapshot de Firestore.
  /// Usa valores por defecto para campos nulos (documentos incompletos).
  factory PictogramaPersonalizado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PictogramaPersonalizado(
      id:        doc.id,
      // Defensivo: si el campo no existe o no es String, usa ''
      imageUrl:  data['imageUrl']  as String?   ?? '',
      etiqueta:  data['etiqueta']  as String?   ?? '',
      textoTts:  data['textoTts']  as String?   ?? '',
      // Default a 'Personalizado' si no se guardó la categoría
      categoria: data['categoria'] as String?   ?? 'Personalizado',
      // Convierte Timestamp de Firestore a DateTime; usa now() si es null
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serializa el modelo a un Map compatible con Firestore.
  /// No incluye el `id` porque Firestore lo maneja como clave del documento.
  Map<String, dynamic> toMap() {
    return {
      'imageUrl':  imageUrl,
      'etiqueta':  etiqueta,
      'textoTts':  textoTts,
      'categoria': categoria,
      // Convierte DateTime a Timestamp de Firestore para consistencia de tipos
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ─── Servicio ─────────────────────────────────────────────────────────────────

/// Servicio estático (constructor privado) para la gestión completa del
/// ciclo de vida de pictogramas.
class PictogramService {
  // Constructor privado: esta clase no debe instanciarse, todos los métodos son estáticos
  PictogramService._();

  // Instancias de servicios de Firebase (singleton por diseño de Firebase)
  static final _storage   = FirebaseStorage.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth      = FirebaseAuth.instance;
  static final _picker    = ImagePicker(); // Única instancia del picker para toda la app

  /// Obtiene el UID del usuario autenticado o lanza excepción si no hay sesión.
  static String get _userId {
    final user = _auth.currentUser;
    // Si no hay usuario, hay un bug en la navegación (AuthGate debería haberse activado)
    if (user == null) throw Exception('No hay usuario autenticado.');
    return user.uid;
  }

  // ─── Referencias de Firestore ──────────────────────────────────────────

  /// Referencia a la colección de pictogramas del usuario autenticado actual.
  static CollectionReference<Map<String, dynamic>> get _pictogramsRef =>
      _firestore.collection('users').doc(_userId).collection('pictograms');

  /// Referencia a la colección de pictogramas de cualquier usuario (para tutor).
  static CollectionReference<Map<String, dynamic>> _pictogramsRefFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('pictograms');

  // ─── Consultas (Streams en tiempo real) ───────────────────────────────

  /// Stream de pictogramas personalizados de un usuario específico (modo tutor).
  ///
  /// Ordenados por `createdAt` descendente para mostrar los más recientes primero.
  /// Convierte cada DocumentSnapshot al modelo [PictogramaPersonalizado].
  static Stream<List<PictogramaPersonalizado>> getCustomPictogramsStreamFor(String userId) {
    return _pictogramsRefFor(userId)
        .orderBy('createdAt', descending: true) // Más reciente primero
        .snapshots()
        .map((s) => s.docs.map(PictogramaPersonalizado.fromFirestore).toList());
  }

  /// Stream de pictogramas personalizados del usuario autenticado actual.
  ///
  /// Equivalente a [getCustomPictogramsStreamFor] pero usa el UID del usuario actual.
  static Stream<List<PictogramaPersonalizado>> getCustomPictogramsStream() {
    return _pictogramsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PictogramaPersonalizado.fromFirestore(doc))
            .toList());
  }

  // ─── Creación sin imagen (para banco predefinido del tutor) ────────────

  /// Crea un pictograma en la colección del usuario [userId] usando una URL ya existente.
  ///
  /// Usado por el tutor cuando selecciona un pictograma del banco SVG predefinido
  /// para añadirlo a la colección del usuario sin pasar por el proceso de captura.
  /// La URL puede ser un path de asset local o una URL de Storage.
  ///
  /// Retorna el modelo creado leyendo el documento recién escrito.
  static Future<PictogramaPersonalizado> createPictogramFor({
    required String userId,
    required String etiqueta,
    required String textoTts,
    String imageUrl  = '',              // Vacío si el tutor no adjunta imagen
    String categoria = 'Personalizado', // Default: sin categoría específica
  }) async {
    // Añadimos el documento a la colección del usuario especificado
    final docRef = await _pictogramsRefFor(userId).add({
      'imageUrl':  imageUrl,
      'etiqueta':  etiqueta.trim().toUpperCase(), // Siempre en mayúsculas para consistencia
      'textoTts':  textoTts.trim(),
      'categoria': categoria,
      'createdAt': FieldValue.serverTimestamp(), // Timestamp del servidor para exactitud
    });

    // Leemos el documento recién creado para obtener el ID asignado por Firestore
    final doc = await docRef.get();
    return PictogramaPersonalizado.fromFirestore(doc);
  }

  // ─── Configuración: categoría y visibilidad por pictograma del banco ───

  /// Referencia a la colección de configuración de banco predefinido del usuario.
  static CollectionReference<Map<String, dynamic>> _settingsRefFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('pictogramSettings');

  /// Stream del mapa `{pictoId → {categoria, visible}}` para un usuario.
  ///
  /// Usando un Map en lugar de una lista se evitan búsquedas O(n) en la UI:
  /// el lookup `settings[id]` es O(1).
  ///
  /// Si un pictograma no tiene documento en esta colección, no aparecerá
  /// en el mapa y `_efectiva()` / `_visible()` usarán los valores predeterminados.
  static Stream<Map<String, Map<String, dynamic>>> getPictogramSettingsStreamFor(String userId) {
    return _settingsRefFor(userId).snapshots().map(
      // Construimos el mapa doc.id → doc.data() con un "for spread"
      (s) => {for (final doc in s.docs) doc.id: doc.data()},
    );
  }

  /// Actualiza parcialmente la configuración de un pictograma del banco predefinido.
  ///
  /// Usa `SetOptions(merge: true)` para escribir solo los campos que llegan no-nulos,
  /// sin sobreescribir los demás campos del documento (ej: si actualizas categoría,
  /// el campo `visible` no se toca).
  static Future<void> updatePictogramSettingFor({
    required String userId,
    required String pictoId,
    String? categoria, // null = no actualizar este campo
    bool?   visible,   // null = no actualizar este campo
  }) async {
    // Construimos el map de actualizaciones con solo los campos no nulos
    final updates = <String, dynamic>{};
    if (categoria != null) updates['categoria'] = categoria;
    if (visible   != null) updates['visible']   = visible;

    // Si no hay nada que actualizar, salimos sin tocar Firestore
    if (updates.isEmpty) return;

    // Merge:true → escribe los campos del map sin borrar los campos existentes
    await _settingsRefFor(userId).doc(pictoId).set(updates, SetOptions(merge: true));
  }

  // ─── Edición de pictogramas personalizados ─────────────────────────────

  /// Actualiza parcialmente un pictograma personalizado de [userId].
  ///
  /// Solo escribe los campos que llegan no-nulos, igual que
  /// [updatePictogramSettingFor]. La etiqueta se normaliza a MAYÚSCULAS
  /// con la misma regla que [createPictogram], para mantener la
  /// consistencia visual del tablero.
  ///
  /// En comunicación aumentativa un error de escritura no es cosmético:
  /// el texto es el mensaje. Por eso el pictograma debe poder corregirse
  /// sin obligar a eliminarlo y volver a crearlo (perdiendo la foto).
  static Future<void> updatePictogramFor({
    required String userId,
    required String pictogramId,
    String? etiqueta,
    String? textoTts,
    String? categoria,
  }) async {
    final updates = <String, dynamic>{};
    if (etiqueta  != null && etiqueta.trim().isNotEmpty) {
      updates['etiqueta'] = etiqueta.trim().toUpperCase();
    }
    if (textoTts  != null && textoTts.trim().isNotEmpty) {
      updates['textoTts'] = textoTts.trim();
    }
    if (categoria != null) updates['categoria'] = categoria;

    if (updates.isEmpty) return;

    await _pictogramsRefFor(userId).doc(pictogramId).update(updates);
  }

  /// Actualiza un pictograma del usuario autenticado actual.
  ///
  /// Equivalente a [updatePictogramFor] usando el UID actual.
  static Future<void> updatePictogram({
    required String pictogramId,
    String? etiqueta,
    String? textoTts,
    String? categoria,
  }) {
    return updatePictogramFor(
      userId:      _userId,
      pictogramId: pictogramId,
      etiqueta:    etiqueta,
      textoTts:    textoTts,
      categoria:   categoria,
    );
  }

  // ─── Eliminación ──────────────────────────────────────────────────────

  /// Elimina un pictograma del usuario [userId]: primero borra la imagen
  /// de Firebase Storage, luego borra el documento de Firestore.
  ///
  /// La eliminación de Storage falla silenciosamente si la URL no existe
  /// o es una URL de asset local (no es un archivo en Storage).
  static Future<void> deletePictogramFor(String userId, String pictogramId) async {
    final docRef = _pictogramsRefFor(userId).doc(pictogramId);
    final doc    = await docRef.get();

    if (doc.exists) {
      final imageUrl = doc.data()?['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Intentamos borrar el archivo en Storage por su URL pública de descarga
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {
          // Ignoramos el error: la imagen puede no existir en Storage
          // (por ejemplo si es un path de asset local)
        }
      }
    }

    // Borramos el documento de Firestore independientemente del resultado de Storage
    await docRef.delete();
  }

  /// Elimina un pictograma del usuario autenticado actual.
  ///
  /// Equivalente a [deletePictogramFor] usando el UID actual.
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

  // ─── Captura y procesamiento de imagen ────────────────────────────────

  /// Abre la cámara y retorna el archivo capturado (null si el usuario cancela).
  ///
  /// Parámetros de compresión:
  /// - `imageQuality: 85` — 85% de calidad JPEG: balance entre tamaño y fidelidad.
  /// - `maxWidth/maxHeight: 1024` — máximo 1024px en cualquier dimensión.
  static Future<XFile?> pickImageFromCamera() async {
    return _picker.pickImage(
      source:       ImageSource.camera,
      imageQuality: 85,   // 85% de calidad JPEG
      maxWidth:     1024, // Máximo 1024px de ancho
      maxHeight:    1024, // Máximo 1024px de alto
    );
  }

  /// Abre la galería de fotos y retorna el archivo seleccionado (null si cancela).
  ///
  /// Mismos parámetros de compresión que [pickImageFromCamera].
  static Future<XFile?> pickImageFromGallery() async {
    return _picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 85,
      maxWidth:     1024,
      maxHeight:    1024,
    );
  }

  /// Recorta la imagen a formato cuadrado 1:1.
  ///
  /// El recorte cuadrado es obligatorio para que todos los pictogramas tengan
  /// las mismas dimensiones en el tablero TEA (grid uniforme sin distorsión).
  ///
  /// Retorna null si el usuario cancela la pantalla de recorte.
  static Future<CroppedFile?> cropImage({
    required String imagePath,  // Path al archivo imagen original
    int maxWidth  = 512,        // Tamaño máximo de salida en píxeles
    int maxHeight = 512,
  }) async {
    return ImageCropper().cropImage(
      sourcePath:  imagePath,
      // Ratio de aspecto 1:1 = cuadrado perfecto para el grid de pictogramas
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        // Configuración UI específica para Android
        AndroidUiSettings(
          toolbarTitle:              'Recortar pictograma',
          toolbarColor:              const Color(0xFF5A9ABF), // Azul de la app
          toolbarWidgetColor:        Colors.white,
          initAspectRatio:           CropAspectRatioPreset.square,
          lockAspectRatio:           true,  // El usuario no puede cambiar el ratio
          // Se ocultan los controles inferiores para evitar que el slider de zoom
          // se superponga con la barra de navegación del sistema en dispositivos
          // con pantalla pequeña o con navegación por gestos.
          hideBottomControls:        true,
          showCropGrid:              true,  // Cuadrícula de regla de tercios
          statusBarLight:            true,
          activeControlsWidgetColor: const Color(0xFF5A9ABF),
          dimmedLayerColor:          Colors.black.withValues(alpha: 0.5),
          cropFrameColor:            const Color(0xFF5A9ABF),
          cropGridColor:             Colors.white.withValues(alpha: 0.6),
          cropFrameStrokeWidth:      3,
          cropGridRowCount:          3,    // Cuadrícula de 3x3 (regla de tercios)
          cropGridColumnCount:       3,
        ),
        // Configuración UI específica para iOS
        IOSUiSettings(
          title:                   'Recortar pictograma',
          aspectRatioLockEnabled:  true,  // Bloquear ratio 1:1
          resetAspectRatioEnabled: false, // No permitir resetear el ratio
          doneButtonTitle:         '✅ Listo',
          cancelButtonTitle:       'Cancelar',
        ),
      ],
      compressQuality: 80,      // 80% de calidad JPEG tras el recorte
      maxWidth:        maxWidth,
      maxHeight:       maxHeight,
    );
  }

  // ─── Subida a Firebase Storage ─────────────────────────────────────────

  /// Sube un archivo de imagen a Firebase Storage y retorna su URL de descarga.
  ///
  /// Path en Storage: `users/{uid}/pictograms/{filename}`
  /// El filename por defecto incluye el timestamp en ms para evitar colisiones.
  ///
  /// Los metadatos personalizados (`uploadedBy`, `createdAt`) permiten auditar
  /// quién y cuándo subió cada archivo desde la consola de Firebase Storage.
  static Future<String> uploadImage({
    required String filePath,    // Path local al archivo imagen (post-recorte)
    String? customFileName,      // Nombre de archivo custom (opcional)
  }) async {
    return uploadImageFor(userId: _userId, filePath: filePath, customFileName: customFileName);
  }

  /// Sube una imagen al Storage de un usuario específico.
  ///
  /// Usado por el tutor para subir pictogramas personalizados a la cuenta
  /// del paciente. El `uploadedBy` en los metadatos refleja quién realiza
  /// la subida (tutor), pero el archivo se guarda en `users/{targetUserId}`.
  static Future<String> uploadImageFor({
    required String userId,
    required String filePath,
    String? customFileName,
  }) async {
    final file = File(filePath);

    // Validamos que el archivo exista antes de intentar subirlo
    if (!await file.exists()) {
      throw Exception('El archivo no existe.');
    }

    // Generamos el nombre de archivo: custom o timestamp-based
    final fileName = customFileName ??
        'picto_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Referencia al path en Storage donde se subirá el archivo
    final ref = _storage.ref().child('users/$userId/pictograms/$fileName');

    // Subimos el archivo con metadata para auditoría
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg', // Tipo MIME explícito
        customMetadata: {
          'uploadedBy': _userId,                          // UID de quien sube
          'createdAt':  DateTime.now().toIso8601String(), // Timestamp legible
        },
      ),
    );

    // Esperamos a que complete la subida y obtenemos el snapshot
    final snapshot    = await uploadTask;
    // La URL de descarga es la URL pública que se almacena en Firestore
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // ─── Flujo completo: Captura → Recorte → Subida → Firestore ──────────

  /// Orquesta todo el proceso de creación de un pictograma personalizado.
  ///
  /// Pasos:
  ///   1. [pickImageFromCamera] o [pickImageFromGallery] según [useCamera].
  ///   2. [cropImage] — recorte a 1:1.
  ///   3. [uploadImage] — sube a Firebase Storage.
  ///   4. [createPictogram] — crea el documento en Firestore.
  ///
  /// Retorna null si el usuario cancela en cualquier paso (picker o cropper).
  static Future<PictogramaPersonalizado?> captureAndCreate({
    required String etiqueta,
    required String textoTts,
    String categoria = 'Personalizado',
    bool useCamera   = true, // true = cámara, false = galería
  }) async {
    // Paso 1: captura o selección de imagen
    final pickedFile = useCamera
        ? await pickImageFromCamera()
        : await pickImageFromGallery();

    // El usuario canceló la cámara/galería
    if (pickedFile == null) return null;

    // Paso 2: recorte a cuadrado 1:1
    final cropped = await cropImage(imagePath: pickedFile.path);

    // El usuario canceló la pantalla de recorte
    if (cropped == null) return null;

    // Paso 3: subida del archivo recortado a Firebase Storage
    final downloadUrl = await uploadImage(filePath: cropped.path);

    // Paso 4: creación del documento en Firestore con la URL obtenida
    return createPictogram(
      imageUrl:  downloadUrl,
      etiqueta:  etiqueta,
      textoTts:  textoTts,
      categoria: categoria,
    );
  }

  /// Crea el documento de un pictograma personalizado en Firestore.
  ///
  /// La etiqueta se normaliza: `trim()` + `toUpperCase()` para coherencia
  /// visual en el tablero TEA (todos los nombres en mayúsculas).
  ///
  /// Usa `FieldValue.serverTimestamp()` para que el timestamp sea del servidor
  /// y no del reloj local del dispositivo (que puede estar desincronizado).
  ///
  /// Retorna el modelo leyendo el documento recién escrito para obtener el ID.
  static Future<PictogramaPersonalizado> createPictogram({
    required String imageUrl,   // URL de descarga de Firebase Storage
    required String etiqueta,   // Etiqueta legible (será convertida a MAYÚSCULAS)
    required String textoTts,   // Texto para TTS (voz del pictograma)
    String categoria = 'Personalizado', // Categoría en el tablero TEA
  }) async {
    // Añadimos el documento a la colección del usuario autenticado actual
    final docRef = await _pictogramsRef.add({
      'imageUrl':  imageUrl,
      'etiqueta':  etiqueta.trim().toUpperCase(), // Normalización: trim + MAYÚSCULAS
      'textoTts':  textoTts.trim(),               // Solo trim (el TTS sí distingue mayúsculas)
      'categoria': categoria,
      'createdAt': FieldValue.serverTimestamp(), // Timestamp del servidor
    });

    // Leemos el documento para obtener el ID asignado por Firestore
    final doc = await docRef.get();
    return PictogramaPersonalizado.fromFirestore(doc);
  }
}
