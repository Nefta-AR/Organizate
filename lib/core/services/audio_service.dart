import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  AudioService._privateConstructor();

  static final AudioService instance = AudioService._privateConstructor();

  final AudioPlayer _player = AudioPlayer();
  final Map<String, String> _cache = {};
  bool _isPlaying = false;
  void Function(bool)? _onPlayingChanged;

  bool get isPlaying => _isPlaying;

  void setOnPlayingChanged(void Function(bool) callback) {
    _onPlayingChanged = callback;
  }

  Future<String> get _cacheDirPath async {
    final dir = await getApplicationDocumentsDirectory();
    final voicesDir = Directory('${dir.path}/voices_cache');
    if (!await voicesDir.exists()) {
      await voicesDir.create(recursive: true);
    }
    return voicesDir.path;
  }

  String _hashText(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }

  Future<String> _getCacheFilePath(String text) async {
    final dirPath = await _cacheDirPath;
    final hash = _hashText(text);
    return '$dirPath/$hash.mp3';
  }

  Future<bool> _existsInCache(String text) async {
    final filePath = await _getCacheFilePath(text);
    return File(filePath).exists();
  }

  Future<String> _fetchFromCloud(String text, {String? vozId}) async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final result = await functions.httpsCallable('sintetizarVoz').call({
      'texto': text,
      'vozId': vozId ?? 'neural2-f',
    });

    final data = result.data as Map;
    final audioBase64 = data['audioContent'] as String;
    final bytes = base64Decode(audioBase64);

    final filePath = await _getCacheFilePath(text);
    await File(filePath).writeAsBytes(bytes);

    return filePath;
  }

  Future<void> playText(String text, {String? vozId}) async {
    if (text.trim().isEmpty) return;

    final filePath = await _getCacheFilePath(text);

    if (await _existsInCache(text)) {
      await _playFile(filePath);
      return;
    }

    try {
      final cloudPath = await _fetchFromCloud(text, vozId: vozId);
      await _playFile(cloudPath);
    } catch (e) {
      print('Error al sintetizar voz: $e');
    }
  }

  Future<void> _playFile(String filePath) async {
    await _player.stop();
    await _player.setSource(DeviceFileSource(filePath));

    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _onPlayingChanged?.call(false);
    });

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

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _onPlayingChanged?.call(false);
  }

  Future<void> clearCache() async {
    final dirPath = await _cacheDirPath;
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _cache.clear();
  }

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

  void dispose() {
    _player.dispose();
  }
}
