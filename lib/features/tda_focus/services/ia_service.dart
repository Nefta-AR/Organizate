// lib/services/ia_service.dart

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class IAService {
  static String get _apiKey {
    final value = dotenv.env['GEMINI_API_KEY'] ?? '';
    return value.trim().replaceAll('"', '').replaceAll("'", '');
  }

  static const List<String> _modelIds = [
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String _systemPrompt =
      'Eres un experto en apoyo cognitivo. Toma la tarea y el tiempo disponible '
      'y divídela en pasos muy pequeños y manejables. '
      'Devuelve el resultado ESTRICTAMENTE en formato JSON: una lista de objetos '
      'donde cada objeto tenga "titulo" (nombre del paso) y "tiempo_estimado" (duración sugerida). '
      'No incluyas texto adicional, bloques Markdown ni caracteres extra. Solo el JSON puro.';

  static Future<List<Map<String, String>>> desglosarEnPasos({
    required String tarea,
    required String tiempoDisponible,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Falta GEMINI_API_KEY en .env. Revisa que el nombre de la variable este bien escrito.',
      );
    }

    final prompt =
        '$_systemPrompt\n\nTarea: "$tarea"\nTiempo disponible: $tiempoDisponible';

    final response = await _generarContenidoConReintentos(prompt);

    if (response.statusCode != 200) {
      if (_puedeUsarPlanLocal(response)) {
        return _generarPlanLocal(tarea, tiempoDisponible);
      }

      String errorMsg = _mensajeHttp(response.statusCode);
      try {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errInner = errBody['error'];
        if (errInner is Map) {
          final serverMessage = errInner['message'];
          if (serverMessage is String && serverMessage.trim().isNotEmpty) {
            errorMsg = _mensajeServidor(response.statusCode, serverMessage);
          }
        }
      } catch (_) {
        errorMsg = '$errorMsg\nDetalle: ${response.body}';
      }
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    String rawText = '';

    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'];
      if (content is Map) {
        final parts = content['parts'];
        if (parts is List && parts.isNotEmpty) {
          rawText = (parts[0]['text'] as String?) ?? '';
        }
      }
    }

    if (rawText.isEmpty) {
      throw Exception(
          'La IA no devolvió ninguna respuesta. Verifica tu API key.');
    }

    final jsonText = rawText
        .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*', multiLine: true), '')
        .trim();

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(jsonText) as List<dynamic>;
    } catch (_) {
      throw Exception('La IA no devolvió un JSON válido. Intenta de nuevo.');
    }

    return decoded.map<Map<String, String>>((item) {
      if (item is! Map) throw Exception('Formato de paso inesperado.');
      return {
        'titulo': (item['titulo'] as String?)?.trim() ?? 'Paso sin nombre',
        'tiempo_estimado': (item['tiempo_estimado'] as String?)?.trim() ?? '',
      };
    }).toList();
  }

  static Future<http.Response> _generarContenidoConReintentos(
    String prompt,
  ) async {
    http.Response? lastResponse;
    http.Response? mostUsefulError;

    for (final modelId in _modelIds) {
      final url = Uri.parse('$_apiBase/$modelId:generateContent');

      for (var intento = 0; intento < 3; intento++) {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        );

        lastResponse = response;
        if (response.statusCode != 404) mostUsefulError = response;

        if (_debeProbarOtroModelo(response)) break;
        if (response.statusCode != 503) return response;

        await Future.delayed(Duration(milliseconds: 700 * (intento + 1)));
      }
    }

    return mostUsefulError ??
        lastResponse ??
        http.Response(
          '{"error":{"message":"Gemini no devolvio respuesta."}}',
          503,
        );
  }

  static List<Map<String, String>> _generarPlanLocal(
    String tarea,
    String tiempoDisponible,
  ) {
    final minutos = _minutosDisponibles(tiempoDisponible);
    final bloques = minutos <= 30
        ? 4
        : minutos <= 60
            ? 5
            : 6;
    final minutosPorBloque = (minutos / bloques).round().clamp(5, 90);
    final tareaLimpia = tarea.trim().replaceAll(RegExp(r'\s+'), ' ');

    final pasos = [
      'Definir el resultado esperado de "$tareaLimpia"',
      'Reunir lo necesario para avanzar',
      'Separar la tarea en partes pequeñas',
      'Hacer la primera parte concreta',
      'Revisar lo hecho y ajustar el siguiente paso',
      'Cerrar con una entrega o avance visible',
    ].take(bloques);

    return pasos
        .map((titulo) => {
              'titulo': titulo,
              'tiempo_estimado': '$minutosPorBloque min',
            })
        .toList();
  }

  static int _minutosDisponibles(String tiempoDisponible) {
    switch (tiempoDisponible) {
      case '30 minutos':
        return 30;
      case '1 hora':
        return 60;
      case 'Medio dia':
      case 'Medio día':
        return 240;
      case 'Todo el dia':
      case 'Todo el día':
        return 480;
      case 'Una semana':
        return 1200;
      default:
        return 60;
    }
  }

  static String _mensajeHttp(int statusCode) {
    if (statusCode == 400) {
      return 'Gemini rechazo la solicitud. Revisa que la API key sea valida y que el modelo este disponible.';
    }
    if (statusCode == 403) {
      return 'No se pudo autenticar con Gemini. Revisa que la API key sea valida, que la API de Gemini este habilitada y que sus restricciones permitan esta app.';
    }
    if (statusCode == 404) {
      return 'El modelo de Gemini configurado no esta disponible para esta API key.';
    }
    if (statusCode == 429) {
      return 'Gemini rechazo la solicitud por limite de uso. Intenta de nuevo en unos minutos.';
    }
    if (statusCode == 503) {
      return 'Gemini esta temporalmente saturado. Intenta de nuevo en unos minutos.';
    }
    return 'Error $statusCode al llamar a Gemini.';
  }

  static String _mensajeServidor(int statusCode, String serverMessage) {
    final normalized = serverMessage.toLowerCase();
    if (normalized.contains('api key not valid')) {
      return 'La API key de Gemini no es valida. Crea una clave nueva en Google AI Studio y reemplaza GEMINI_API_KEY en .env.';
    }
    if (normalized.contains('quota') || normalized.contains('rate limit')) {
      return 'Gemini rechazo la solicitud por cuota o limite de uso. Revisa el plan/billing de tu API key en Google AI Studio o intenta mas tarde.';
    }
    return '${_mensajeHttp(statusCode)}\nDetalle: $serverMessage';
  }

  static bool _debeProbarOtroModelo(http.Response response) {
    if (response.statusCode == 503) return false;
    if (response.statusCode == 404) return true;
    if (response.statusCode != 429) return false;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      final message = error is Map ? error['message'] : null;
      if (message is! String) return false;
      final normalized = message.toLowerCase();
      return normalized.contains('quota') || normalized.contains('rate limit');
    } catch (_) {
      return false;
    }
  }

  static bool _puedeUsarPlanLocal(http.Response response) {
    if (response.statusCode == 503 || response.statusCode == 404) return true;
    if (response.statusCode != 429) return false;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      final message = error is Map ? error['message'] : null;
      if (message is! String) return false;
      final normalized = message.toLowerCase();
      return normalized.contains('quota') || normalized.contains('rate limit');
    } catch (_) {
      return false;
    }
  }
}
