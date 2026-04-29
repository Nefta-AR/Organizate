import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Servicio de IA que llama directamente al endpoint REST v1 estable de Gemini.
/// Funciona en web y móvil sin depender del SDK google_generative_ai.
class IAService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;

  static const String _modelId = 'gemini-pro';
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1/models';

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
    final url = Uri.parse('$_apiBase/$_modelId:generateContent?key=$_apiKey');

    final prompt =
        '$_systemPrompt\n\nTarea: "$tarea"\nTiempo disponible: $tiempoDisponible';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
      String errorMsg = 'Error ${response.statusCode}';
      try {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errInner = errBody['error'];
        if (errInner is Map) {
          errorMsg = '$errorMsg: ${errInner['message'] ?? response.body}';
        }
      } catch (_) {
        errorMsg = '$errorMsg: ${response.body}';
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
}
