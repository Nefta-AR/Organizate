// ============================================================
// lib/core/services/google_drive_service.dart
// ============================================================
// Servicio singleton para backup y restauración en Google Drive.
//
// ## Autenticación
//
//   Usa GoogleSignIn con scope `drive.file` (acceso solo a archivos
//   creados por la app, no a todo el Drive del usuario).
//   [GoogleAuthHttpClient] extiende http.BaseClient para inyectar
//   el header Authorization en cada petición HTTP a la API de Drive.
//
// ## Estructura en Drive
//
//   Simple_App_Backup/               ← carpeta raíz del backup
//     settings_backup.json           ← Exportación JSON de Firestore
//     pictogramas/                   ← Sub-carpeta de imágenes de pictogramas
//       foto1.jpg
//       foto2.jpg
//       ...
//
// ## Clases de resultado
//
//   [DriveBackupStatus]: resultado de [backupToDrive()]
//     - success, message, timestamp, filesUploaded
//
//   [DriveRestoreResult]: resultado de [restoreFromDrive()]
//     - success, message, cloudIsNewer, restoredFiles
//     - cloudIsNewer: true cuando la nube tiene datos más recientes que el
//       dispositivo (usado para mostrar advertencia antes de restaurar).
//
// ## Persistencia de lastSync
//
//   La fecha del último backup se guarda en SharedPreferences bajo
//   la clave 'drive_last_sync' (formato ISO 8601) para compararla
//   con la fecha de modificación del archivo en Drive.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── DTO: resultado de un backup ───────────────────────────────────────────────

/// Resultado devuelto por [GoogleDriveService.backupToDrive].
class DriveBackupStatus {
  /// true si el backup se completó sin errores
  final bool success;

  /// Mensaje descriptivo del resultado (éxito o error)
  final String message;

  /// Timestamp de cuándo se realizó el backup (null si falló)
  final DateTime? timestamp;

  /// Número de archivos subidos (null si falló)
  final int? filesUploaded;

  const DriveBackupStatus({
    required this.success,
    required this.message,
    this.timestamp,
    this.filesUploaded,
  });
}

// ── DTO: resultado de una restauración ───────────────────────────────────────

/// Resultado devuelto por [GoogleDriveService.restoreFromDrive].
class DriveRestoreResult {
  /// true si la restauración se completó sin errores
  final bool success;

  /// Mensaje descriptivo del resultado
  final String message;

  /// true si la versión en la nube es más reciente que la local.
  /// El caller (SettingsScreen) puede usar esto para pedir confirmación al usuario.
  final bool cloudIsNewer;

  /// Lista de nombres de archivos restaurados (pictogramas descargados)
  final List<String> restoredFiles;

  const DriveRestoreResult({
    required this.success,
    required this.message,
    this.cloudIsNewer = false,
    this.restoredFiles = const [],
  });
}

// ── Servicio principal ────────────────────────────────────────────────────────

/// Singleton de acceso a Google Drive para backup/restauración.
///
/// Uso: `GoogleDriveService.instance.backupToDrive()`
class GoogleDriveService {
  // Constructor privado: impide instanciación directa
  GoogleDriveService._();

  // Instancia única del servicio (patrón singleton)
  static final GoogleDriveService instance = GoogleDriveService._();

  // ── Constantes de nombres en Drive ───────────────────────────────────────────

  // Nombre de la carpeta raíz del backup en el Drive del usuario
  static const String _backupFolderName = 'Simple_App_Backup';

  // Nombre del archivo JSON de configuración
  static const String _settingsFileName = 'settings_backup.json';

  // Nombre de la sub-carpeta de pictogramas dentro del backup
  static const String _pictogramsSubfolder = 'pictogramas';

  // Clave en SharedPreferences donde guardamos el timestamp del último sync
  static const String _lastSyncKey = 'drive_last_sync';

  // ── Estado de sesión ──────────────────────────────────────────────────────────

  // Caché de la cuenta Google activa para evitar re-autenticación en cada operación
  GoogleSignInAccount? _cachedAccount;

  // Instancia del cliente de la API de Drive (requiere autenticación previa)
  drive.DriveApi? _driveApi;

  // ── Autenticación ─────────────────────────────────────────────────────────────

  /// Asegura que haya una sesión activa con Google.
  /// Si ya hay una cuenta cacheada, la retorna directamente.
  /// Si no, abre el flujo de Google Sign-In y crea el cliente HTTP autenticado.
  Future<GoogleSignInAccount?> _ensureSignedIn() async {
    if (_cachedAccount != null) return _cachedAccount; // Sesión existente

    // Solo pedimos acceso a archivos creados por esta app (drive.file)
    // Es el scope mínimo necesario: no lee ni modifica nada más del Drive del usuario
    final googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/drive.file',
      ],
    );

    // Muestra el picker de cuenta Google al usuario
    _cachedAccount = await googleSignIn.signIn();
    if (_cachedAccount == null) return null; // Usuario canceló

    // Los authHeaders incluyen el token de acceso OAuth2
    final authHeaders = await _cachedAccount!.authHeaders;

    // Creamos el cliente HTTP que inyectará el token en cada petición
    final httpClient = GoogleAuthHttpClient(authHeaders);

    // Inicializamos el cliente de la API v3 de Drive con el cliente autenticado
    _driveApi = drive.DriveApi(httpClient);

    return _cachedAccount;
  }

  // ── Gestión de carpetas en Drive ──────────────────────────────────────────────

  /// Obtiene el ID de la carpeta raíz de backup, creándola si no existe.
  /// Busca por nombre y mimeType de carpeta para evitar duplicados.
  Future<String> _getOrCreateBackupFolder() async {
    final account = await _ensureSignedIn();
    if (account == null || _driveApi == null) {
      throw Exception('No se pudo autenticar con Google Drive.');
    }

    // Buscamos la carpeta por nombre exacto y tipo MIME de carpeta
    final existing = await _driveApi!.files.list(
      q: "name='$_backupFolderName' "
          "and mimeType='application/vnd.google-apps.folder' "
          "and trashed=false",
      spaces: 'drive',
      \$fields: 'files(id, name)', // Solo pedimos los campos que necesitamos
    );

    // Si ya existe, retornamos el ID de la primera coincidencia
    if (existing.files != null && existing.files!.isNotEmpty) {
      return existing.files!.first.id!;
    }

    // No existe: creamos la carpeta con el mimeType de carpeta de Google
    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await _driveApi!.files.create(folder);
    return created.id!; // ID asignado por Google Drive
  }

  /// Busca un archivo por nombre dentro de una carpeta específica.
  /// Retorna el ID del archivo o null si no existe.
  Future<String?> _findFileInFolder(String folderId, String fileName) async {
    final result = await _driveApi!.files.list(
      // Filtramos: nombre exacto + padre = folderId + no en papelera
      q: "name='$fileName' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      \$fields: 'files(id, name, modifiedTime)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id; // ID del archivo encontrado
    }
    return null; // No encontrado
  }

  /// Obtiene la fecha de modificación del archivo de configuración en la nube.
  /// Se usa para comparar con el último sync local y decidir si restaurar.
  Future<DateTime?> _getCloudSettingsModifiedTime(String folderId) async {
    final result = await _driveApi!.files.list(
      q: "name='$_settingsFileName' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      \$fields: 'files(modifiedTime)', // Solo necesitamos la fecha de modificación
    );

    if (result.files != null && result.files!.isNotEmpty) {
      final modified = result.files!.first.modifiedTime;
      // Convertimos de UTC (Drive) a hora local para comparar con SharedPreferences
      if (modified != null) return modified.toLocal();
    }
    return null; // Sin archivo de configuración en Drive
  }

  // ── Recolección y aplicación de configuraciones ────────────────────────────────

  /// Recolecta la configuración del usuario desde Firestore para el backup.
  /// Solo incluye campos relevantes (excluye sub-colecciones y datos volátiles).
  Future<Map<String, dynamic>> _collectSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    // Leemos el documento del usuario de Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data() ?? {};

    // Construimos el mapa de configuración a guardar en el JSON del backup
    final settings = <String, dynamic>{
      // Identificadores del usuario (para validar al restaurar)
      'userId': user.uid,
      'email': user.email,
      'displayName': user.displayName,

      // Datos del perfil
      'role': data['role'],
      'avatar': data['avatar'],
      'points': data['points'],
      'streak': data['streak'],
      'hasCompletedOnboarding': data['hasCompletedOnboarding'],

      // Contacto de emergencia
      'emergencyName': data['emergencyName'],
      'emergencyPhone': data['emergencyPhone'],

      // Preferencias de notificaciones
      'notiTaskEnabled': data['notiTaskEnabled'],
      'notiTaskDefaultOffsetMinutes': data['notiTaskDefaultOffsetMinutes'],

      // Preferencias del Pomodoro
      'pomodoroSoundEnabled': data['pomodoroSoundEnabled'],
      'pomodoroVibrationEnabled': data['pomodoroVibrationEnabled'],
      'pomodoroSound': data['pomodoroSound'],

      // Estadísticas de sesiones de foco
      'focusSessionsCompleted': data['focusSessionsCompleted'],
      'totalFocusMinutes': data['totalFocusMinutes'],

      // Metadatos del backup (no se restauran, son solo para diagnóstico)
      'backupTimestamp': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };

    return settings;
  }

  /// Aplica la configuración restaurada desde Drive al documento Firestore del usuario.
  /// Solo restaura campos que tienen valor (no sobreescribe con null).
  /// Usa merge: true para no eliminar campos no incluidos en el backup.
  Future<void> _applySettings(Map<String, dynamic> settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Construimos el mapa de campos a actualizar, filtrando los que tienen valor
    final updatable = <String, dynamic>{};

    // Campos String: restauramos si no son null
    final stringFields = [
      'role', 'avatar', 'emergencyName', 'emergencyPhone', 'pomodoroSound',
    ];
    for (final field in stringFields) {
      if (settings[field] != null) {
        updatable[field] = settings[field];
      }
    }

    // Campos bool: restauramos con cast explícito para no guardar tipos incorrectos
    final boolFields = [
      'hasCompletedOnboarding', 'notiTaskEnabled',
      'pomodoroSoundEnabled', 'pomodoroVibrationEnabled',
    ];
    for (final field in boolFields) {
      if (settings[field] != null) {
        updatable[field] = settings[field] as bool;
      }
    }

    // Campos numéricos: en JSON los números pueden venir como String tras el decode,
    // por lo que usamos int.tryParse() como fallback
    final numFields = [
      'points', 'streak', 'notiTaskDefaultOffsetMinutes',
      'focusSessionsCompleted', 'totalFocusMinutes',
    ];
    for (final field in numFields) {
      if (settings[field] != null) {
        updatable[field] = settings[field] is num
            ? settings[field]
            : int.tryParse(settings[field].toString());
      }
    }

    // Escribimos todos los campos actualizables de una sola vez
    if (updatable.isNotEmpty) {
      await userRef.set(updatable, SetOptions(merge: true));
    }
  }

  // ── Sub-carpeta de pictogramas ─────────────────────────────────────────────────

  /// Obtiene el ID de la sub-carpeta de pictogramas dentro de [folderId],
  /// creándola si no existe. Similar a [_getOrCreateBackupFolder].
  Future<String> _getPictogramsSubfolder(String folderId) async {
    final existing = await _driveApi!.files.list(
      q: "name='$_pictogramsSubfolder' "
          "and '$folderId' in parents "
          "and mimeType='application/vnd.google-apps.folder' "
          "and trashed=false",
      spaces: 'drive',
      \$fields: 'files(id, name)',
    );

    if (existing.files != null && existing.files!.isNotEmpty) {
      return existing.files!.first.id!;
    }

    // Creamos la sub-carpeta especificando su padre
    final folder = drive.File()
      ..name = _pictogramsSubfolder
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [folderId]; // Esta es la diferencia: la sub-carpeta tiene padre

    final created = await _driveApi!.files.create(folder);
    return created.id!;
  }

  // ── Backup a Drive ────────────────────────────────────────────────────────────

  /// Sube la configuración de Firestore y los pictogramas locales a Google Drive.
  ///
  /// Estrategia: si el archivo ya existe en Drive, usa `files.update` (reemplaza);
  /// si no existe, usa `files.create` (crea nuevo). Esto evita duplicados.
  Future<DriveBackupStatus> backupToDrive() async {
    try {
      // Paso 1: autenticarnos con Google
      final account = await _ensureSignedIn();
      if (account == null || _driveApi == null) {
        return const DriveBackupStatus(
          success: false,
          message: 'Autenticación con Drive cancelada.',
        );
      }

      // Paso 2: obtener (o crear) la carpeta raíz del backup
      final folderId = await _getOrCreateBackupFolder();

      // Paso 3: recolectar configuración de Firestore y codificarla en JSON
      final settings = await _collectSettings();
      final settingsBytes = utf8.encode(jsonEncode(settings)); // bytes del JSON

      // Paso 4: preparar el archivo de configuración
      final settingsFile = drive.File()
        ..name = _settingsFileName
        ..parents = [folderId];

      // Verificamos si ya existe para usar update vs create
      final existingSettingsId =
          await _findFileInFolder(folderId, _settingsFileName);

      if (existingSettingsId != null) {
        // Actualizamos el archivo existente (no cambiamos el ID)
        await _driveApi!.files.update(
          settingsFile,
          existingSettingsId,
          uploadMedia: drive.Media(
            http.ByteStream.fromBytes(settingsBytes),
            settingsBytes.length,
          ),
        );
      } else {
        // Creamos un nuevo archivo
        await _driveApi!.files.create(
          settingsFile,
          uploadMedia: drive.Media(
            http.ByteStream.fromBytes(settingsBytes),
            settingsBytes.length,
          ),
        );
      }

      int uploaded = 1; // Contamos el JSON de configuración como 1 archivo

      // Paso 5: subir pictogramas locales (imágenes .jpg)
      final pictogramFolderId = await _getPictogramsSubfolder(folderId);
      final localPictograms = await _getLocalPictogramFiles();

      for (final pictoFile in localPictograms) {
        // Leemos los bytes de la imagen local
        final bytes = await pictoFile.readAsBytes();
        // Usamos el nombre del archivo local como nombre en Drive
        final fileName = path.basename(pictoFile.path);

        final driveFile = drive.File()
          ..name = fileName
          ..parents = [pictogramFolderId]
          ..mimeType = 'image/jpeg'; // Tipo MIME explícito para imágenes

        // Misma lógica update/create para cada pictograma
        final existingId =
            await _findFileInFolder(pictogramFolderId, fileName);

        if (existingId != null) {
          await _driveApi!.files.update(
            driveFile,
            existingId,
            uploadMedia: drive.Media(
              http.ByteStream.fromBytes(bytes),
              bytes.length,
            ),
          );
        } else {
          await _driveApi!.files.create(
            driveFile,
            uploadMedia: drive.Media(
              http.ByteStream.fromBytes(bytes),
              bytes.length,
            ),
          );
        }
        uploaded++; // Contamos cada pictograma subido
      }

      // Paso 6: actualizamos la fecha del último sync en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return DriveBackupStatus(
        success: true,
        message: 'Respaldo completado ($uploaded archivos).',
        timestamp: DateTime.now(),
        filesUploaded: uploaded,
      );

    } catch (e) {
      // Error no esperado: retornamos el mensaje para que el UI lo muestre
      return DriveBackupStatus(
        success: false,
        message: 'Error al respaldar: ${e.toString()}',
      );
    }
  }

  // ── Restaurar desde Drive ──────────────────────────────────────────────────────

  /// Descarga la configuración y pictogramas desde Google Drive y los aplica localmente.
  ///
  /// [force]: si true, restaura incluso si la versión local es más reciente.
  /// Si false, compara fechas y puede retornar early con cloudIsNewer: false.
  Future<DriveRestoreResult> restoreFromDrive({bool force = false}) async {
    try {
      // Paso 1: autenticación
      final account = await _ensureSignedIn();
      if (account == null || _driveApi == null) {
        return const DriveRestoreResult(
          success: false,
          message: 'Autenticación con Drive cancelada.',
        );
      }

      // Paso 2: localizar la carpeta de backup
      final folderId = await _getOrCreateBackupFolder();

      // Paso 3: comparar fechas para decidir si restaurar es necesario
      final cloudModified = await _getCloudSettingsModifiedTime(folderId);
      if (cloudModified == null) {
        // No hay backup en Drive: no hay nada que restaurar
        return const DriveRestoreResult(
          success: false,
          message: 'No se encontró un respaldo en Google Drive.',
        );
      }

      // Leemos la fecha del último sync desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      DateTime? lastSync;
      if (lastSyncStr != null) {
        lastSync = DateTime.tryParse(lastSyncStr);
      }

      // Si la versión local es más reciente y no se forzó la restauración,
      // no sobreescribimos datos locales más nuevos con datos más viejos de la nube
      if (!force && lastSync != null && lastSync.isAfter(cloudModified)) {
        return const DriveRestoreResult(
          success: true,
          message: 'Tu versión local ya está actualizada.',
          cloudIsNewer: false, // Informamos que la nube NO es más nueva
        );
      }

      // Paso 4: descargar y aplicar la configuración JSON
      final settingsFileId =
          await _findFileInFolder(folderId, _settingsFileName);
      if (settingsFileId == null) {
        return const DriveRestoreResult(
          success: false,
          message: 'No se encontró el archivo de configuración en Drive.',
        );
      }

      // Descargamos el archivo completo como stream de bytes
      final response = await _driveApi!.files.get(
        settingsFileId,
        downloadOptions: drive.DownloadOptions.fullMedia, // Descarga completa
      ) as drive.Media;

      // Acumulamos todos los chunks del stream en un único List<int>
      final bytes = await _collectBytes(response.stream);

      // Deserializamos el JSON y aplicamos los campos a Firestore
      final settings = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      await _applySettings(settings);

      // Paso 5: restaurar pictogramas (solo los que no existen localmente)
      final restoredFiles = <String>[];
      final pictogramFolderId = await _getPictogramsSubfolder(folderId);

      // Listamos todos los pictogramas de la sub-carpeta en Drive
      final cloudPictograms = await _driveApi!.files.list(
        q: "'$pictogramFolderId' in parents and trashed=false",
        spaces: 'drive',
        \$fields: 'files(id, name, modifiedTime)',
      );

      if (cloudPictograms.files != null &&
          cloudPictograms.files!.isNotEmpty) {
        final localDir = await _getLocalPictogramsDir();

        for (final cloudFile in cloudPictograms.files!) {
          final fileId = cloudFile.id!;
          final fileName = cloudFile.name!;

          // Si el pictograma ya existe localmente, lo saltamos para no sobreescribir
          final localFile = File('${localDir.path}/$fileName');
          if (localFile.existsSync()) continue;

          // Descargamos el pictograma desde Drive
          final fileResponse = await _driveApi!.files.get(
            fileId,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final fileBytes = await _collectBytes(fileResponse.stream);

          // Escribimos los bytes en el directorio local de pictogramas
          await localFile.writeAsBytes(fileBytes);
          restoredFiles.add(fileName); // Registramos el archivo restaurado
        }
      }

      // Paso 6: actualizamos la fecha del último sync tras la restauración exitosa
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return DriveRestoreResult(
        success: true,
        message: restoredFiles.isEmpty
            ? 'Configuración restaurada desde Drive.'
            : 'Restauración completa: ${restoredFiles.length} pictogramas descargados.',
        cloudIsNewer: true, // La nube sí era más nueva (por eso restauramos)
        restoredFiles: restoredFiles,
      );

    } catch (e) {
      return DriveRestoreResult(
        success: false,
        message: 'Error al restaurar: ${e.toString()}',
      );
    }
  }

  // ── Utilidades públicas ────────────────────────────────────────────────────────

  /// Retorna la fecha y hora del último backup exitoso guardada en SharedPreferences.
  /// Retorna null si nunca se ha hecho backup.
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncStr = prefs.getString(_lastSyncKey);
    if (syncStr == null) return null;
    return DateTime.tryParse(syncStr); // null si el string está malformado
  }

  // ── Utilidades privadas de archivos locales ────────────────────────────────────

  /// Lista los archivos .jpg del directorio local de pictogramas.
  /// Ignora subdirectorios y archivos que no sean imágenes.
  Future<List<File>> _getLocalPictogramFiles() async {
    final dir = await _getLocalPictogramsDir();

    // Si el directorio no existe, no hay pictogramas (return vacío)
    if (!await dir.exists()) return [];

    final files = <File>[];
    // Stream de entidades del directorio (no recursivo)
    await for (final entity in dir.list()) {
      // Solo archivos .jpg (pictogramas del tablero AAC)
      if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
        files.add(entity);
      }
    }
    return files;
  }

  /// Retorna el directorio local de pictogramas, creándolo si no existe.
  /// Ruta: [applicationDocumentsDirectory]/pictogramas/
  Future<Directory> _getLocalPictogramsDir() async {
    // getApplicationDocumentsDirectory(): persistente entre reinicios de la app
    final appDir = await getApplicationDocumentsDirectory();
    final pictoDir = Directory('${appDir.path}/pictogramas');

    // recursive: true → crea directorios padre si es necesario
    if (!await pictoDir.exists()) {
      await pictoDir.create(recursive: true);
    }
    return pictoDir;
  }

  /// Verifica si el backup en la nube es más reciente que el último sync local.
  /// Se usa en SettingsScreen para mostrar un badge de "actualización disponible".
  Future<bool> isCloudNewerThanLocal() async {
    try {
      final account = await _ensureSignedIn();
      if (account == null || _driveApi == null) return false;

      final folderId = await _getOrCreateBackupFolder();
      final cloudModified = await _getCloudSettingsModifiedTime(folderId);
      if (cloudModified == null) return false; // Sin backup en Drive

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);

      // Si nunca se ha sincronizado, la nube siempre es "más nueva"
      if (lastSyncStr == null) return true;

      final lastSync = DateTime.tryParse(lastSyncStr);
      if (lastSync == null) return true; // String malformado → asumir desactualizado

      // true si la fecha de modificación en Drive es posterior al último sync local
      return cloudModified.isAfter(lastSync);

    } catch (_) {
      // Si falla la autenticación o la API, asumimos que no sabemos → false
      return false;
    }
  }

  // ── Utilitario de stream ───────────────────────────────────────────────────────

  /// Acumula todos los chunks de un stream de bytes en una sola lista.
  /// Necesario porque la API de Drive devuelve Media como Stream<List<int>>.
  Future<List<int>> _collectBytes(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk); // Concatenamos cada fragmento del stream
    }
    return bytes;
  }

  /// Cierra la sesión de Google Drive y limpia el caché.
  /// Se debe llamar cuando el usuario cierra sesión en la app.
  void signOut() {
    _cachedAccount = null; // Fuerza re-autenticación en la próxima operación
    _driveApi = null;
  }
}

// ── Cliente HTTP autenticado para Google APIs ──────────────────────────────────

/// Extiende [http.BaseClient] para inyectar el token de acceso OAuth2
/// en el header Authorization de cada petición a la API de Google Drive.
///
/// GoogleSignIn provee los headers como Map<String, String> que incluyen
/// {'Authorization': 'Bearer <token>', ...}.
class GoogleAuthHttpClient extends http.BaseClient {
  // Map de headers de autenticación (de GoogleSignInAccount.authHeaders)
  final Map<String, String> _headers;

  // Cliente HTTP interno que realiza las peticiones reales
  final http.Client _inner = http.Client();

  GoogleAuthHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Inyectamos los headers de autenticación en cada petición saliente
    request.headers.addAll(_headers);
    return _inner.send(request); // Delegamos al cliente interno
  }

  @override
  void close() {
    // Liberamos el cliente HTTP interno al cerrar
    _inner.close();
  }
}
