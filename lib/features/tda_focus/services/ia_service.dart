// ============================================================
// lib/features/tda_focus/services/ia_service.dart
// ============================================================
// Servicio de descomposición de tareas mediante Gemini AI.
//
// Arquitectura:
//   Flutter → Firebase Cloud Functions (desglosarTarea) → Gemini 2.0/2.5 Flash
//
// El código de la Cloud Function está en functions/src/index.ts.
// Recibe {tarea, tiempoDisponible} y retorna una lista de pasos:
//   [{titulo: string, tiempo_estimado: string}, ...]
//
// Se usa Cloud Functions como proxy para:
//   1. Mantener la API key de Gemini fuera del cliente (seguridad).
//   2. Centralizar el rate-limiting y manejo de cuotas.
//   3. Poder actualizar el prompt sin hacer un update de la app.
//
// Timeout: 10 segundos. Si Gemini no responde, lanza deadline-exceeded.
// ============================================================

import 'package:cloud_functions/cloud_functions.dart';

class IAService {
  // Constructor privado: clase puramente estática.
  IAService._();

  static final _functions = FirebaseFunctions.instance;

  /// Llama a la Cloud Function 'desglosarTarea' y retorna la lista de pasos.
  ///
  /// [tarea] es la descripción de la tarea a descomponer.
  /// [tiempoDisponible] es una string como "30 minutos", "Todo el día", etc.
  ///
  /// Lanza [Exception] con mensajes en español si hay algún error.
  static Future<List<Map<String, String>>> desglosarEnPasos({
    required String tarea,
    required String tiempoDisponible,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'desglosarTarea', // Nombre de la Cloud Function en Firebase
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 10), // Timeout agresivo para UX
            ),
          )
          .call(<String, dynamic>{
        'tarea':             tarea,
        'tiempoDisponible':  tiempoDisponible,
      });

      // La Cloud Function retorna data como List<Map<String, String>>.
      // La aserción de tipo en Dart no valida la estructura interna,
      // por eso se verifica explícitamente.
      final data = result.data as dynamic;
      if (data is! List) {
        throw _formatException('La respuesta del servidor no tiene el formato esperado.');
      }

      // Mapea cada elemento al tipo esperado con valores por defecto.
      return data.map<Map<String, String>>((item) {
        if (item is! Map) {
          return {'titulo': 'Paso sin nombre', 'tiempo_estimado': ''};
        }
        return {
          'titulo':          (item['titulo']          as String?)?.trim() ?? 'Paso sin nombre',
          'tiempo_estimado': (item['tiempo_estimado'] as String?)?.trim() ?? '',
        };
      }).toList();
    } on FirebaseFunctionsException catch (e) {
      // Mapea errores específicos de Firebase Functions a mensajes de usuario.
      throw _mapFirebaseError(e);
    } catch (e) {
      // Mapea errores genéricos de red/timeout.
      throw _mapGenericError(e);
    }
  }

  /// Traduce códigos de error de Firebase Functions a mensajes amigables en español.
  static String _mapFirebaseError(FirebaseFunctionsException e) {
    final code    = e.code;
    final message = e.message ?? '';

    switch (code) {
      case 'unauthenticated':
        // El usuario no tiene sesión activa en Firebase Auth.
        return 'Debes iniciar sesión para usar el Súper Experto.';
      case 'invalid-argument':
        // Parámetros inválidos enviados a la función.
        return message;
      case 'deadline-exceeded':
        // Gemini tardó más de 10 segundos en responder.
        return 'El experto tardó demasiado en responder. Verifica tu conexión e intenta de nuevo.';
      case 'unavailable':
        // Cloud Functions no está disponible (outage o región caída).
        return 'El servicio de IA no está disponible ahora. Intenta de nuevo en unos minutos.';
      case 'internal':
        // Puede ser un error de cuota de Gemini API.
        if (message.toLowerCase().contains('cuota') ||
            message.toLowerCase().contains('quota')) {
          return 'Se alcanzó el límite de uso del experto. Intenta de nuevo más tarde.';
        }
        return message.isNotEmpty
            ? message
            : 'Error interno del servicio de IA. Intenta de nuevo más tarde.';
      case 'cancelled':
        return 'La solicitud fue cancelada. Intenta de nuevo.';
      default:
        return 'Error al conectar con el experto: $message';
    }
  }

  /// Traduce errores genéricos de Dart/HTTP a mensajes de usuario.
  static String _mapGenericError(dynamic error) {
    final msg = error.toString().toLowerCase();

    // Detecta problemas de red por keywords en el mensaje de error.
    if (msg.contains('socket')     ||
        msg.contains('network')    ||
        msg.contains('connection') ||
        msg.contains('internet')) {
      return 'No hay conexión a internet. Conéctate e intenta de nuevo.';
    }

    // Detecta timeout por keywords.
    if (msg.contains('timeout') || msg.contains('deadline')) {
      return 'La solicitud tardó demasiado. Verifica tu conexión e intenta de nuevo.';
    }

    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  /// Envuelve un mensaje en una Exception para mantener el tipo de retorno consistente.
  static Exception _formatException(String message) => Exception(message);
}
