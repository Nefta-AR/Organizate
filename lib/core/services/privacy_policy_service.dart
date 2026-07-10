import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Versión vigente de la Política de Privacidad de Simple.
///
/// Si el texto cambia de forma relevante, se debe crear una nueva versión.
/// AuthGate pedirá una nueva aceptación a los usuarios con versión anterior.
class PrivacyPolicyService {
  PrivacyPolicyService._();

  static const appName = 'Simple';
  static const currentVersion = '2026-07-10';
  static const contactEmail = 'soporte.simpleapp@gmail.com';
  static const contactPhone = '+56-972745654';

  static const shortConsentText =
      'Acepto la Política de Privacidad de Simple y autorizo el tratamiento '
      'de mis datos personales para crear y administrar mi cuenta, usar las '
      'funciones de apoyo cognitivo, vinculación tutor-usuario, seguridad, '
      'notificaciones, respaldos y soporte, según la versión vigente.';

  static const policyText = '''
Política de Privacidad de Simple
Versión: 2026-07-10

Simple es una aplicación de apoyo cognitivo para personas neurodivergentes, especialmente usuarios TEA y TDAH, con funciones de tareas, foco, pictogramas, avatar, configuración, SOS, vinculación con tutor y supervisión.

1. Responsable y contacto
El equipo responsable de Simple puede ser contactado en soporte.simpleapp@gmail.com o al teléfono +56-972745654.

2. Datos que podemos tratar
Podemos tratar datos de cuenta como nombre, correo electrónico, identificador de usuario, rol, avatar, configuraciones de la app, vinculaciones entre tutor y usuario, tareas, progreso, pictogramas, registros de actividad, preferencias, notificaciones, contacto de emergencia y respaldos solicitados por el usuario.

3. Finalidad
Usamos los datos para crear y administrar cuentas, permitir el funcionamiento de la app, vincular tutor y usuario, mostrar progreso, enviar recordatorios, activar funciones de apoyo cognitivo, entregar soporte, mejorar la seguridad y mantener continuidad del servicio.

4. Datos sensibles
Simple puede contener información relacionada con rutinas, necesidades de apoyo, actividad, salud o neurodivergencia. Por eso se trata con especial cuidado y solo para las finalidades propias de la aplicación.

5. Tutores
Cuando un usuario se vincula con un tutor, el tutor puede acceder a información necesaria para acompañamiento y supervisión dentro de la app. La vinculación se realiza mediante código de invitación y puede ser desactivada.

6. Servicios externos
Simple usa servicios de Firebase/Google para autenticación, base de datos, notificaciones, funciones en la nube, almacenamiento y, cuando corresponda, respaldos en Google Drive o funciones de inteligencia artificial mediante Cloud Functions.

7. Seguridad
Simple usa Firebase Authentication, reglas de seguridad de Firestore, control de acceso por rol, comunicación cifrada mediante HTTPS/TLS y funciones backend para proteger claves de API. Ningún sistema es infalible, pero aplicamos medidas razonables de seguridad para el nivel del proyecto.

8. Derechos del titular
El usuario puede solicitar información, rectificación, eliminación, bloqueo u oposición al tratamiento de sus datos escribiendo a soporte.simpleapp@gmail.com. Estas solicitudes se revisarán según la normativa chilena aplicable.

9. Conservación
Los datos se conservan mientras la cuenta esté activa o mientras sean necesarios para las finalidades informadas, salvo obligaciones legales o solicitudes válidas de eliminación.

10. Cambios
Si la política cambia de forma relevante, Simple podrá solicitar una nueva aceptación dentro de la aplicación.
''';

  static bool hasAcceptedCurrentPolicy(Map<String, dynamic> data) {
    return data['privacyPolicyAccepted'] == true &&
        data['privacyPolicyVersion'] == currentVersion;
  }

  static Map<String, dynamic> userAcceptanceFields() {
    return {
      'privacyPolicyAccepted': true,
      'privacyPolicyVersion': currentVersion,
      'privacyPolicyAcceptedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> recordAcceptance({
    required String source,
    User? user,
  }) async {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw StateError('No hay usuario autenticado para registrar aceptación.');
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(currentUser.uid);
    final consentRef =
        userRef.collection('legalConsents').doc(currentVersion);

    final batch = firestore.batch();
    batch.set(userRef, userAcceptanceFields(), SetOptions(merge: true));
    batch.set(
      consentRef,
      {
        'type': 'privacy_policy',
        'appName': appName,
        'policyVersion': currentVersion,
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedByUid': currentUser.uid,
        'acceptedEmail': currentUser.email,
        'source': source,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'consentText': shortConsentText,
      },
      SetOptions(merge: false),
    );

    await batch.commit();
  }
}
