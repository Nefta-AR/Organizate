import 'package:cloud_functions/cloud_functions.dart';

class IAService {
  IAService._();

  static final _functions = FirebaseFunctions.instance;

  static Future<List<Map<String, String>>> desglosarEnPasos({
    required String tarea,
    required String tiempoDisponible,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'desglosarTarea',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 25),
            ),
          )
          .call(<String, dynamic>{
        'tarea': tarea,
        'tiempoDisponible': tiempoDisponible,
      });

      final data = result.data as dynamic;
      if (data is! List) {
        throw _formatException('La respuesta del servidor no tiene el formato esperado.');
      }

      return data.map<Map<String, String>>((item) {
        if (item is! Map) {
          return {'titulo': 'Paso sin nombre', 'tiempo_estimado': ''};
        }
        return {
          'titulo': (item['titulo'] as String?)?.trim() ?? 'Paso sin nombre',
          'tiempo_estimado': (item['tiempo_estimado'] as String?)?.trim() ?? '',
        };
      }).toList();
    } on FirebaseFunctionsException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  static String _mapFirebaseError(FirebaseFunctionsException e) {
    final code = e.code;
    final message = e.message ?? '';

    switch (code) {
      case 'unauthenticated':
        return 'Debes iniciar sesión para usar el Súper Experto.';

      case 'invalid-argument':
        return message;

      case 'deadline-exceeded':
        return 'El experto tardó demasiado en responder. Verifica tu conexión e intenta de nuevo.';

      case 'unavailable':
        return 'El servicio de IA no está disponible ahora. Intenta de nuevo en unos minutos.';

      case 'internal':
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

  static String _mapGenericError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('internet')) {
      return 'No hay conexión a internet. Conéctate e intenta de nuevo.';
    }

    if (msg.contains('timeout') || msg.contains('deadline')) {
      return 'La solicitud tardó demasiado. Verifica tu conexión e intenta de nuevo.';
    }

    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  static Exception _formatException(String message) => Exception(message);
}
