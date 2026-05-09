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

class DriveBackupStatus {
  final bool success;
  final String message;
  final DateTime? timestamp;
  final int? filesUploaded;

  const DriveBackupStatus({
    required this.success,
    required this.message,
    this.timestamp,
    this.filesUploaded,
  });
}

class DriveRestoreResult {
  final bool success;
  final String message;
  final bool cloudIsNewer;
  final List<String> restoredFiles;

  const DriveRestoreResult({
    required this.success,
    required this.message,
    this.cloudIsNewer = false,
    this.restoredFiles = const [],
  });
}

class GoogleDriveService {
  GoogleDriveService._();

  static final GoogleDriveService instance = GoogleDriveService._();

  static const String _backupFolderName = 'Simple_App_Backup';
  static const String _settingsFileName = 'settings_backup.json';
  static const String _pictogramsSubfolder = 'pictogramas';
  static const String _lastSyncKey = 'drive_last_sync';

  GoogleSignInAccount? _cachedAccount;
  drive.DriveApi? _driveApi;

  Future<GoogleSignInAccount?> _ensureSignedIn() async {
    if (_cachedAccount != null) return _cachedAccount;

    final googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/drive.file',
      ],
    );

    _cachedAccount = await googleSignIn.signIn();
    if (_cachedAccount == null) return null;

    final authHeaders = await _cachedAccount!.authHeaders;
    final httpClient = GoogleAuthHttpClient(authHeaders);

    _driveApi = drive.DriveApi(httpClient);
    return _cachedAccount;
  }

  Future<String> _getOrCreateBackupFolder() async {
    final account = await _ensureSignedIn();
    if (account == null || _driveApi == null) {
      throw Exception('No se pudo autenticar con Google Drive.');
    }

    final existing = await _driveApi!.files.list(
      q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (existing.files != null && existing.files!.isNotEmpty) {
      return existing.files!.first.id!;
    }

    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await _driveApi!.files.create(folder);
    return created.id!;
  }

  Future<String?> _findFileInFolder(String folderId, String fileName) async {
    final result = await _driveApi!.files.list(
      q: "name='$fileName' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id;
    }
    return null;
  }

  Future<DateTime?> _getCloudSettingsModifiedTime(String folderId) async {
    final result = await _driveApi!.files.list(
      q: "name='$_settingsFileName' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      $fields: 'files(modifiedTime)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      final modified = result.files!.first.modifiedTime;
      if (modified != null) return modified.toLocal();
    }
    return null;
  }

  Future<Map<String, dynamic>> _collectSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data() ?? {};

    final settings = <String, dynamic>{
      'userId': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': data['role'],
      'avatar': data['avatar'],
      'points': data['points'],
      'streak': data['streak'],
      'hasCompletedOnboarding': data['hasCompletedOnboarding'],
      'emergencyName': data['emergencyName'],
      'emergencyPhone': data['emergencyPhone'],
      'notiTaskEnabled': data['notiTaskEnabled'],
      'notiTaskDefaultOffsetMinutes': data['notiTaskDefaultOffsetMinutes'],
      'pomodoroSoundEnabled': data['pomodoroSoundEnabled'],
      'pomodoroVibrationEnabled': data['pomodoroVibrationEnabled'],
      'pomodoroSound': data['pomodoroSound'],
      'focusSessionsCompleted': data['focusSessionsCompleted'],
      'totalFocusMinutes': data['totalFocusMinutes'],
      'kioskModeEnabled': data['kioskModeEnabled'],
      'backupTimestamp': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };

    return settings;
  }

  Future<void> _applySettings(Map<String, dynamic> settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final updatable = <String, dynamic>{};

    final stringFields = [
      'role', 'avatar', 'emergencyName', 'emergencyPhone',
      'pomodoroSound',
    ];
    for (final field in stringFields) {
      if (settings[field] != null) {
        updatable[field] = settings[field];
      }
    }

    final boolFields = [
      'hasCompletedOnboarding', 'notiTaskEnabled',
      'pomodoroSoundEnabled', 'pomodoroVibrationEnabled',
      'kioskModeEnabled',
    ];
    for (final field in boolFields) {
      if (settings[field] != null) {
        updatable[field] = settings[field] as bool;
      }
    }

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

    if (updatable.isNotEmpty) {
      await userRef.set(updatable, SetOptions(merge: true));
    }
  }

  Future<String> _getPictogramsSubfolder(String folderId) async {
    final existing = await _driveApi!.files.list(
      q: "name='$_pictogramsSubfolder' and '$folderId' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (existing.files != null && existing.files!.isNotEmpty) {
      return existing.files!.first.id!;
    }

    final folder = drive.File()
      ..name = _pictogramsSubfolder
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [folderId];

    final created = await _driveApi!.files.create(folder);
    return created.id!;
  }

  Future<DriveBackupStatus> backupToDrive() async {
    try {
      final account = await _ensureSignedIn();
      if (account == null || _driveApi == null) {
        return const DriveBackupStatus(
          success: false,
          message: 'Autenticación con Drive cancelada.',
        );
      }

      final folderId = await _getOrCreateBackupFolder();

      final settings = await _collectSettings();
      final settingsBytes = utf8.encode(jsonEncode(settings));

      final settingsFile = drive.File()
        ..name = _settingsFileName
        ..parents = [folderId];

      final existingSettingsId = await _findFileInFolder(folderId, _settingsFileName);

      if (existingSettingsId != null) {
        await _driveApi!.files.update(
          settingsFile,
          existingSettingsId,
          uploadMedia: drive.Media(
            http.ByteStream.fromBytes(settingsBytes),
            settingsBytes.length,
          ),
        );
      } else {
        await _driveApi!.files.create(
          settingsFile,
          uploadMedia: drive.Media(
            http.ByteStream.fromBytes(settingsBytes),
            settingsBytes.length,
          ),
        );
      }

      int uploaded = 1;

      final pictogramFolderId = await _getPictogramsSubfolder(folderId);
      final localPictograms = await _getLocalPictogramFiles();

      for (final pictoFile in localPictograms) {
        final bytes = await pictoFile.readAsBytes();
        final fileName = path.basename(pictoFile.path);
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [pictogramFolderId]
          ..mimeType = 'image/jpeg';

        final existingId = await _findFileInFolder(pictogramFolderId, fileName);

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
        uploaded++;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return DriveBackupStatus(
        success: true,
        message: 'Respaldo completado ($uploaded archivos).',
        timestamp: DateTime.now(),
        filesUploaded: uploaded,
      );
    } catch (e) {
      return DriveBackupStatus(
        success: false,
        message: 'Error al respaldar: ${e.toString()}',
      );
    }
  }

  Future<DriveRestoreResult> restoreFromDrive({bool force = false}) async {
    try {
      final account = await _ensureSignedIn();
      if (account == null || _driveApi == null) {
        return const DriveRestoreResult(
          success: false,
          message: 'Autenticación con Drive cancelada.',
        );
      }

      final folderId = await _getOrCreateBackupFolder();

      final cloudModified = await _getCloudSettingsModifiedTime(folderId);
      if (cloudModified == null) {
        return const DriveRestoreResult(
          success: false,
          message: 'No se encontró un respaldo en Google Drive.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      DateTime? lastSync;
      if (lastSyncStr != null) {
        lastSync = DateTime.tryParse(lastSyncStr);
      }

      if (!force && lastSync != null && lastSync.isAfter(cloudModified)) {
        return DriveRestoreResult(
          success: true,
          message: 'Tu versión local ya está actualizada.',
          cloudIsNewer: false,
        );
      }

      final settingsFileId = await _findFileInFolder(folderId, _settingsFileName);
      if (settingsFileId == null) {
        return const DriveRestoreResult(
          success: false,
          message: 'No se encontró el archivo de configuración en Drive.',
        );
      }

      final response = await _driveApi!.files.get(
        settingsFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await _collectBytes(response.stream);
      final settings = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      await _applySettings(settings);

      final restoredFiles = <String>[];

      final pictogramFolderId = await _getPictogramsSubfolder(folderId);
      final cloudPictograms = await _driveApi!.files.list(
        q: "'$pictogramFolderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (cloudPictograms.files != null && cloudPictograms.files!.isNotEmpty) {
        final localDir = await _getLocalPictogramsDir();

        for (final cloudFile in cloudPictograms.files!) {
          final fileId = cloudFile.id!;
          final fileName = cloudFile.name!;

          final localFile = File('${localDir.path}/$fileName');
          if (localFile.existsSync()) continue;

          final fileResponse = await _driveApi!.files.get(
            fileId,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final fileBytes = await _collectBytes(fileResponse.stream);
          await localFile.writeAsBytes(fileBytes);

          restoredFiles.add(fileName);
        }
      }

      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return DriveRestoreResult(
        success: true,
        message: restoredFiles.isEmpty
            ? 'Configuración restaurada desde Drive.'
            : 'Restauración completa: ${restoredFiles.length} pictogramas descargados.',
        cloudIsNewer: true,
        restoredFiles: restoredFiles,
      );
    } catch (e) {
      return DriveRestoreResult(
        success: false,
        message: 'Error al restaurar: ${e.toString()}',
      );
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncStr = prefs.getString(_lastSyncKey);
    if (syncStr == null) return null;
    return DateTime.tryParse(syncStr);
  }

  Future<List<File>> _getLocalPictogramFiles() async {
    final dir = await _getLocalPictogramsDir();
    if (!await dir.exists()) return [];

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<Directory> _getLocalPictogramsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pictoDir = Directory('${appDir.path}/pictogramas');
    if (!await pictoDir.exists()) {
      await pictoDir.create(recursive: true);
    }
    return pictoDir;
  }

  Future<bool> isCloudNewerThanLocal() async {
    try {
      final account = await _ensureSignedIn();
      if (account == null || _driveApi == null) return false;

      final folderId = await _getOrCreateBackupFolder();
      final cloudModified = await _getCloudSettingsModifiedTime(folderId);
      if (cloudModified == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr == null) return true;

      final lastSync = DateTime.tryParse(lastSyncStr);
      if (lastSync == null) return true;

      return cloudModified.isAfter(lastSync);
    } catch (_) {
      return false;
    }
  }

  Future<List<int>> _collectBytes(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  void signOut() {
    _cachedAccount = null;
    _driveApi = null;
  }
}

class GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  GoogleAuthHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
