import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Servicio de Inteligencia Artificial conectado a la API de Google Gemini.
///
/// Responsabilidad única: recibir una tarea y el tiempo disponible,
/// y devolver una lista de pasos pequeños y manejables.
class IAService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  static const String _modelId = 'gemini-1.5-flash';

  /// Instrucción de sistema que define el rol y el formato de respuesta.
  static const String _systemPrompt =
      'Eres un experto en apoyo cognitivo. Toma la tarea y el tiempo disponible, '
      'y divídela en pasos muy pequeños y manejables. '
      'Devuelve el resultado ESTRICTAMENTE en formato JSON, siendo una lista de objetos '
      'donde cada objeto tenga "titulo" (el nombre del paso) y "tiempo_estimado" (duración sugerida). '
      'No incluyas texto adicional, bloques de código Markdown ni caracteres extra. Solo el JSON puro.';

  /// Desglosa una [tarea] en pasos pequeños dado un [tiempoDisponible].
  ///
  /// Retorna `List<Map<String, String>>` con las claves `titulo` y `tiempo_estimado`.
  /// Lanza [Exception] si la API falla o el JSON devuelto es inválido.
  static Future<List<Map<String, String>>> desglosarEnPasos({
    required String tarea,
    required String tiempoDisponible,
  }) async {
    final model = GenerativeModel(
      model: _modelId,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );

    final prompt = 'Tarea: "$tarea"\nTiempo disponible: $tiempoDisponible';

    final response = await model.generateContent([Content.text(prompt)]);
    final rawText = response.text ?? '';

    if (rawText.isEmpty) {
      throw Exception(
          'La IA no devolvió ninguna respuesta. Verifica tu API key.');
    }

    // Gemini a veces envuelve la respuesta en bloques Markdown (```json ... ```).
    // Este paso los elimina para garantizar un JSON limpio antes de parsear.
    final jsonText = rawText
        .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*', multiLine: true), '')
        .trim();

    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(jsonText) as List<dynamic>;
    } catch (_) {
      throw Exception(
        'La IA no devolvió un JSON válido. '
        'Intenta de nuevo o revisa tu conexión.',
      );
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
