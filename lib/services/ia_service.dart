import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Servicio de IA que llama directamente al endpoint REST v1 estable de Gemini.
/// Funciona en web y móvil sin depender del SDK google_generative_ai.
class IAService {
  static String get _apiKey {
    final value = dotenv.env['GEMINI_API_KEY'] ?? '';
    return value.trim().replaceAll('"', '').replaceAll("'", '');
  }

  static const String _modelId = 'gemini-2.5-flash';
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String _systemPrompt =
      'Eres un experto en apoyo cognitivo. Toma la tarea y el tiempo disponible '
      'y divídela en pasos muy pequeños y manejables. '
      'Devuelve el resultado ESTRICTAMENTE en formato JSON: una lista de objetos '
      'donde cada objeto tenga "titulo" (nombre del paso) y "tiempo_estimado" (duración sugerida). '
      'No incluyas texto adicional, bloques Markdown ni caracteres extra. Solo el JSON puro.';

  /// Desglosa [tarea] en pasos manejables dado [tiempoDisponible].
  /// Lanza [Exception] con mensaje legible si algo falla.
  static Future<List<Map<String, String>>> desglosarEnPasos({
    required String tarea,
    required String tiempoDisponible,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Falta GEMINI_API_KEY en .env. Revisa que el nombre de la variable este bien escrito.',
      );
    }

    final url = Uri.parse('$_apiBase/$_modelId:generateContent');

    final prompt =
        '$_systemPrompt\n\nTarea: "$tarea"\nTiempo disponible: $tiempoDisponible';

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

    // Error HTTP — extrae el mensaje del servidor para mostrarlo al usuario.
    if (response.statusCode != 200) {
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

    // Extrae el texto de la respuesta evitando casteos ambiguos.
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

    // Limpia posibles bloques Markdown que Gemini puede añadir.
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
    return 'Error $statusCode al llamar a Gemini.';
  }

  static String _mensajeServidor(int statusCode, String serverMessage) {
    final normalized = serverMessage.toLowerCase();

    if (normalized.contains('api key not valid')) {
      return 'La API key de Gemini no es valida. Crea una clave nueva en Google AI Studio y reemplaza GEMINI_API_KEY en .env.';
    }

    return '${_mensajeHttp(statusCode)}\nDetalle: $serverMessage';
  }
}
