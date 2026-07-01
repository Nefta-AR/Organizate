// ============================================================
// lib/features/auth/screens/vinculacion_tutor_screen.dart
// ============================================================
// Pantalla de vinculación tutor ↔ usuario mediante código de 6 caracteres.
//
// Estados posibles de la pantalla:
//   A) Ya vinculado (_isLinked == true)  →  muestra tarjeta verde con datos del tutor
//   B) Sin vincular + código no validado →  muestra formulario de ingreso del código
//   C) Sin vincular + código válido      →  muestra tarjeta de confirmación + botón Aceptar
//
// Flujo normal:
//   1. El tutor genera un código desde su panel (TutorSupervisarScreen).
//   2. El usuario ingresa el código en esta pantalla.
//   3. _validateCode() verifica en Firestore que el código existe, no está vencido
//      y no fue usado por otro usuario.
//   4. Si es válido, muestra el nombre del tutor para confirmación.
//   5. _acceptCode() escribe el batch atómico en Firestore:
//      - Marca el código como 'used'
//      - Crea linkedTutors/{tutorId} en el documento del usuario
// ============================================================

import 'package:flutter/material.dart';
import 'package:simple/core/services/auth_service.dart';

class VinculacionTutorScreen extends StatefulWidget {
  const VinculacionTutorScreen({super.key});

  @override
  State<VinculacionTutorScreen> createState() =>
      _VinculacionTutorScreenState();
}

class _VinculacionTutorScreenState extends State<VinculacionTutorScreen> {
  // Controlador del campo de texto donde el usuario ingresa el código de 6 chars.
  final _codeController = TextEditingController();

  // Estados de carga para los dos botones asíncronos.
  bool _isValidating = false; // "Validar código" en proceso
  bool _isAccepting  = false; // "Aceptar y vincularme" en proceso

  // Resultado de la validación del código (null = no validado todavía).
  // Contiene: {'valid': true/false, 'tutorName': '...', 'tutorId': '...'}
  // o {'valid': false, 'reason': 'Mensaje de error'}
  Map<String, dynamic>? _validationResult;

  // True cuando el usuario ya tiene un tutor activo vinculado.
  bool _isLinked = false;

  @override
  void initState() {
    super.initState();
    // Consulta Firestore al iniciar para saber si ya hay vinculación activa.
    _checkIfAlreadyLinked();
  }

  /// Comprueba si el usuario ya está vinculado a un tutor.
  /// Consume el primer evento del stream (break) para no mantener una suscripción abierta.
  Future<void> _checkIfAlreadyLinked() async {
    final tutorStream = AuthService.getLinkedTutorStream();
    await for (final tutor in tutorStream) {
      if (mounted) {
        setState(() => _isLinked = tutor != null);
        break; // Solo necesitamos el estado actual, no seguir escuchando
      }
    }
  }

  /// Valida el código de invitación en Firestore sin consumirlo.
  ///
  /// La validación verifica:
  ///   - Existencia del documento en 'invitationCodes'
  ///   - status == 'active' (no usado ni desactivado)
  ///   - expiresAt > ahora (no vencido, TTL de 7 días)
  Future<void> _validateCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un código')),
      );
      return;
    }

    setState(() => _isValidating = true);
    // Captura el messenger antes del await para evitar el warning de
    // "Don't use BuildContext across async gaps".
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await AuthService.validateInvitationCode(
        _codeController.text.trim(),
      );
      setState(() => _validationResult = result);
      // Si la validación falló, muestra el motivo.
      if (result == null || result['valid'] != true) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result?['reason'] ?? 'Código inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  /// Acepta el código validado y ejecuta el batch atómico de vinculación en Firestore.
  Future<void> _acceptCode() async {
    setState(() => _isAccepting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // AuthService.acceptInvitationCode hace:
      //   - Re-verifica el código para detectar condición de carrera
      //   - Batch: marca código 'used', crea linkedTutors/{tutorId}
      await AuthService.acceptInvitationCode(_codeController.text.trim());
      if (mounted) {
        setState(() => _isLinked = true); // Cambia a la vista de "ya vinculado"
        messenger.showSnackBar(
          const SnackBar(
            content: Text('¡Te has vinculado con tu tutor exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si ya está vinculado, muestra la vista de confirmación en lugar del formulario.
    if (_isLinked) {
      return _buildAlreadyLinkedView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular con Tutor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),      // Tarjeta explicativa del proceso
            const SizedBox(height: 24),
            _buildCodeInputCard(), // Campo de texto + botón Validar
            // El bloque de confirmación solo aparece cuando el código es válido.
            if (_validationResult != null && _validationResult!['valid'] == true)
              ...[
                const SizedBox(height: 16),
                _buildValidationSuccessCard(), // Nombre del tutor + botón Aceptar
              ],
            const SizedBox(height: 24),
            _buildHowItWorksCard(), // Guía de 4 pasos
          ],
        ),
      ),
    );
  }

  /// Vista mostrada cuando el usuario ya tiene un tutor vinculado.
  /// Lee el stream en tiempo real para mostrar los datos actualizados del tutor.
  Widget _buildAlreadyLinkedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Tutor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: StreamBuilder<Map<String, dynamic>?>(
          // Stream en tiempo real: si el tutor cambia su nombre, se actualiza aquí.
          stream: AuthService.getLinkedTutorStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final tutor = snapshot.data;
            if (tutor == null) {
              return const Text('No tienes un tutor vinculado');
            }

            // Extrae campos del documento del tutor.
            final tutorName   = tutor['name']   as String? ?? 'Tutor';
            final tutorEmail  = tutor['email']  as String? ?? '';
            final tutorAvatar = tutor['avatar'] as String?;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // Gradiente verde que indica vinculación exitosa.
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Estás vinculado!',
                      style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Avatar del tutor: imagen de assets si tiene uno, ícono genérico si no.
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withAlpha(50),
                      backgroundImage: tutorAvatar != null
                          ? AssetImage('assets/avatars/$tutorAvatar.png')
                          : null,
                      child: tutorAvatar == null
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tutorName,
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tutorEmail,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Tarjeta informativa que explica el propósito de la vinculación.
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.group_add, color: Colors.white, size: 32),
          SizedBox(height: 12),
          Text(
            'Vincúlate con tu tutor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresa el código que te proporcionó tu tutor para establecer la vinculación. '
            'Esto permitirá que tu tutor supervise tu progreso.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con el campo de texto para el código y el botón de validación.
  Widget _buildCodeInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de invitación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            // Convierte automáticamente a mayúsculas (los códigos son en mayúscula).
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Ej: A7K2NP',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2,
            ),
            maxLength: 6, // Los códigos tienen exactamente 6 caracteres
            onSubmitted: (_) => _validateCode(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isValidating ? null : _validateCode,
              // Muestra spinner en el ícono durante la validación.
              icon: _isValidating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isValidating ? 'Validando...' : 'Validar código'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta verde que aparece cuando el código es válido.
  /// Muestra el nombre del tutor y el botón de aceptar la vinculación.
  Widget _buildValidationSuccessCard() {
    final tutorName = _validationResult!['tutorName'] as String;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38EF7D), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF11998E), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Código válido!',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF11998E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Muestra el nombre del tutor para que el usuario confirme que es el correcto.
                    Text('Tutor: $tutorName', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAccepting ? null : _acceptCode,
              icon: _isAccepting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.link),
              label: Text(_isAccepting ? 'Vinculando...' : 'Aceptar y vincularme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11998E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta explicativa de 4 pasos de cómo funciona el proceso de vinculación.
  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cómo funciona?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStep(number: 1, title: 'Tu tutor genera un código',
            description: 'El tutor crea un código de 6 caracteres desde su panel.'),
          const SizedBox(height: 8),
          _buildStep(number: 2, title: 'Comparte el código contigo',
            description: 'Te lo envía por mensaje, email o te lo dice directamente.'),
          const SizedBox(height: 8),
          _buildStep(number: 3, title: 'Ingresa y valida el código',
            description: 'Escribe el código aquí y presiona "Validar".'),
          const SizedBox(height: 8),
          _buildStep(number: 4, title: '¡Listo!',
            description: 'Acepta la vinculación y tu tutor podrá ver tu progreso.'),
        ],
      ),
    );
  }

  /// Construye una fila de paso numerado (círculo verde + título + descripción).
  Widget _buildStep({required int number, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Círculo verde con el número del paso.
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF11998E),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
