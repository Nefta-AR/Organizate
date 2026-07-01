// ============================================================
// lib/core/services/audio_service.dart
// ============================================================
// Servicio singleton para síntesis de voz (TTS) via Cloud Functions.
//
// ## Flujo de reproducción
//
// 1. Se calcula el hash SHA256 del texto como clave de caché.
// 2. Si existe el archivo MP3 en disco (`voices_cache/{hash}.mp3`),
//    se reproduce directamente sin llamar a la red.
// 3. Si no existe, se llama a la Cloud Function `sintetizarVoz`
//    (que a su vez llama a Google TTS Neural2), se guarda el MP3
//    en disco y luego se reproduce.
//
// La caché persiste entre sesiones del usuario. [clearCache] permite
// liberar espacio desde la pantalla de Ajustes.
//
// ## Singleton
//
// `AudioService.instance` es la única instancia del servicio.
// No crear instancias adicionales — [AudioPlayer] tiene recursos
// nativos que deben ser manejados por un único objeto.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  // Constructor privado: garantiza que solo existe una instancia.
  AudioService._privateConstructor();

  /// Instancia única del servicio (patrón Singleton).
  static final AudioService instance = AudioService._privateConstructor();

  final AudioPlayer _player = AudioPlayer();
  final Map<String, String> _cache = {}; // Caché en memoria: text → filePath
  bool _isPlaying = false;
  void Function(bool)? _onPlayingChanged; // Callback para actualizar UI

  bool get isPlaying => _isPlaying;

  /// Registra un callback que se invoca cuando cambia el estado de reproducción.
  void setOnPlayingChanged(void Function(bool) callback) {
    _onPlayingChanged = callback;
  }

  /// Devuelve la ruta del directorio de caché de voces (crea si no existe).
  Future<String> get _cacheDirPath async {
    final dir = await getApplicationDocumentsDirectory();
    final voicesDir = Directory('${dir.path}/voices_cache');
    if (!await voicesDir.exists()) {
      await voicesDir.create(recursive: true);
    }
    return voicesDir.path;
  }

  /// Calcula el hash SHA256 del texto para usar como nombre de archivo.
  String _hashText(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }

  /// Devuelve la ruta completa del archivo de caché para un texto.
  Future<String> _getCacheFilePath(String text) async {
    final dirPath = await _cacheDirPath;
    final hash = _hashText(text);
    return '$dirPath/$hash.mp3';
  }

  /// Verifica si el MP3 ya existe en el caché local.
  Future<bool> _existsInCache(String text) async {
    final filePath = await _getCacheFilePath(text);
    return File(filePath).exists();
  }

  /// Llama a la Cloud Function `sintetizarVoz`, recibe el audio en Base64,
  /// lo decodifica y lo guarda en disco. Retorna la ruta del archivo guardado.
  Future<String> _fetchFromCloud(String text, {String? vozId}) async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final result = await functions.httpsCallable('sintetizarVoz').call({
      'texto': text,
      'vozId': vozId ?? 'neural2-f', // Voz femenina Neural2 en español
    });

    final data = result.data as Map;
    final audioBase64 = data['audioContent'] as String;
    final bytes = base64Decode(audioBase64);

    // Persiste el MP3 en disco para futuras reproducciones sin red
    final filePath = await _getCacheFilePath(text);
    await File(filePath).writeAsBytes(bytes);

    return filePath;
  }

  /// Reproduce el [text] usando TTS. Usa caché local si el audio ya fue sintetizado.
  ///
  /// [vozId]: ID de voz de Google TTS (default: 'neural2-f' = español femenino).
  Future<void> playText(String text, {String? vozId}) async {
    if (text.trim().isEmpty) return;

    final filePath = await _getCacheFilePath(text);

    // Reproducir desde caché si existe
    if (await _existsInCache(text)) {
      await _playFile(filePath);
      return;
    }

    // Sintetizar desde la nube y reproducir
    try {
      final cloudPath = await _fetchFromCloud(text, vozId: vozId);
      await _playFile(cloudPath);
    } catch (e) {
      debugPrint('Error al sintetizar voz: $e');
    }
  }

  /// Configura el player para reproducir el archivo en [filePath].
  Future<void> _playFile(String filePath) async {
    await _player.stop();
    await _player.setSource(DeviceFileSource(filePath));

    // Notifica al UI cuando termina la reproducción
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _onPlayingChanged?.call(false);
    });

    // Notifica al UI cuando cambia el estado del player
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _isPlaying = true;
        _onPlayingChanged?.call(true);
      } else if (state == PlayerState.paused || state == PlayerState.stopped) {
        _isPlaying = false;
        _onPlayingChanged?.call(false);
      }
    });

    await _player.resume();
  }

  /// Detiene la reproducción actual inmediatamente.
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _onPlayingChanged?.call(false);
  }

  /// Elimina todo el caché de voces del disco.
  /// Llamar desde Ajustes → Foco → "Limpiar caché de audio".
  Future<void> clearCache() async {
    final dirPath = await _cacheDirPath;
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _cache.clear();
  }

  /// Devuelve el tamaño total del caché en bytes.
  Future<int> getCacheSize() async {
    final dirPath = await _cacheDirPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    int totalBytes = 0;
    await for (final file in dir.list()) {
      if (file is File) {
        totalBytes += await file.length();
      }
    }
    return totalBytes;
  }

  /// Libera los recursos nativos del [AudioPlayer].
  void dispose() {
    _player.dispose();
  }
}
