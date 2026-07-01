// ============================================================
// lib/features/tutor_dashboard/screens/tutor_vinculacion_screen.dart
// ============================================================
// Pantalla de gestión de vínculos entre tutor y pacientes.
//
// Permite al tutor:
//   1. Generar un código de invitación de 6 caracteres (expira en 7 días).
//      [_generateCode] → [AuthService.generateInvitationCode]
//   2. Ver y copiar el código generado al portapapeles. [_copyCode]
//   3. Ver la lista de usuarios vinculados en tiempo real via Stream.
//   4. Desvincular un usuario después de confirmación. [_removePatient]
//   5. Navegar al panel de supervisión tocando un usuario vinculado.
//
// ## Flujo de vinculación
//
//   Tutor genera código → comparte con el paciente → el paciente
//   lo ingresa en VinculacionTutorScreen → aceptación atómica en Firestore.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple/core/services/auth_service.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_supervise_screen.dart';

class TutorVinculacionScreen extends StatefulWidget {
  const TutorVinculacionScreen({super.key});

  @override
  State<TutorVinculacionScreen> createState() => _TutorVinculacionScreenState();
}

class _TutorVinculacionScreenState extends State<TutorVinculacionScreen> {
  // true mientras se está generando el código (muestra spinner en el botón)
  bool _isGenerating = false;

  // El código de invitación generado más recientemente; null si aún no se generó
  String? _currentCode;

  // ── Generar un nuevo código de invitación ─────────────────────────────────

  Future<void> _generateCode() async {
    // Activamos el estado de carga para deshabilitar el botón y mostrar spinner
    setState(() => _isGenerating = true);

    // Capturamos el messenger antes del await para evitar uso tras desmontaje
    final messenger = ScaffoldMessenger.of(context);

    try {
      // AuthService.generateInvitationCode() escribe en Firestore:
      // invitation_codes/{code} con tutorId, expiresAt (+7 días), isUsed: false
      final code = await AuthService.generateInvitationCode();

      // Guardamos el código en el estado local para mostrarlo en la tarjeta
      setState(() => _currentCode = code);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('¡Código generado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Error de Firestore o de permisos: mostramos el mensaje al usuario
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Siempre desactivamos el estado de carga, incluso si hubo un error
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Copiar el código al portapapeles del sistema ──────────────────────────

  void _copyCode(String code) {
    // Clipboard.setData es sincrónico y escribe en el portapapeles del SO
    Clipboard.setData(ClipboardData(text: code));

    // Confirmamos visualmente que el código fue copiado
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  // ── Desvincular un paciente (con confirmación) ────────────────────────────

  Future<void> _removePatient(String patientId, String patientName) async {
    final messenger = ScaffoldMessenger.of(context);

    // Mostramos un diálogo de confirmación antes de desvincular,
    // ya que la acción no se puede deshacer fácilmente
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular usuario'),
        content: Text('¿Estás seguro de que deseas desvincular a $patientName?'),
        actions: [
          // Cancelar: devuelve false (no se desvincula)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          // Confirmar: botón rojo para enfatizar que es una acción destructiva
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    // Solo procedemos si el usuario confirmó explícitamente
    if (confirmed == true) {
      try {
        // AuthService.removePatientLink elimina el ID del paciente del array
        // linkedPatients[] del tutor, y limita el tutorId del paciente en Firestore
        await AuthService.removePatientLink(patientId);

        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Usuario desvinculado'),
              backgroundColor: Colors.orange, // Naranja: acción no peligrosa pero notable
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ── Construcción del layout principal ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Usuarios'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta principal con gradiente para generar el código
            _buildGenerateCodeCard(),

            // La tarjeta del código solo aparece después de generar uno
            if (_currentCode != null) ...[
              const SizedBox(height: 16),
              _buildCodeDisplayCard(_currentCode!),
            ],

            const SizedBox(height: 24),

            // Encabezado de la sección de pacientes vinculados
            const Text(
              'Usuarios vinculados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista en tiempo real de pacientes vinculados
            _buildLinkedPatientsList(),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de generación de código (gradiente púrpura) ──────────────────

  Widget _buildGenerateCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Gradiente diagonal de azul-morado a púrpura oscuro
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono de QR como indicador visual del propósito
          const Icon(Icons.qr_code_2, color: Colors.white, size: 32),
          const SizedBox(height: 12),

          const Text(
            'Generar código de invitación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Instrucciones breves para el tutor
          const Text(
            'El usuario deberá ingresar este código para vincularse contigo. El código expira en 7 días.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // Botón de acción: deshabilitado durante la generación (_isGenerating)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateCode,

              // Icono cambia a spinner mientras se está generando
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),

              // Texto del botón cambia para feedback de estado
              label: Text(_isGenerating ? 'Generando...' : 'Generar código'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF764BA2), // Texto color acento
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta que muestra el código generado ────────────────────────────────

  Widget _buildCodeDisplayCard(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF), // Azul muy claro de fondo
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667EEA), width: 2), // Borde azul
      ),
      child: Column(
        children: [
          const Text(
            'Tu código de invitación:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Código con espaciado de letras amplio para facilitar la lectura
              Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4, // Separa los caracteres para leerlos fácilmente
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),

              // Botón para copiar el código al portapapeles del dispositivo
              IconButton(
                onPressed: () => _copyCode(code),
                icon: const Icon(Icons.copy, color: Color(0xFF667EEA)),
                tooltip: 'Copiar código',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Recordatorio de la caducidad del código
          const Text(
            'Válido por 7 días',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Lista de pacientes vinculados en tiempo real ──────────────────────────

  Widget _buildLinkedPatientsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // getLinkedPatientsStream: escucha el array linkedPatients del tutor
      // y retorna los documentos de usuario de cada paciente vinculado
      stream: AuthService.getLinkedPatientsStream(),
      builder: (context, snapshot) {
        // Cargando: spinner centrado
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error de lectura: mostramos el mensaje técnico para debugging
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        // Lista de pacientes (puede ser vacía si aún no hay vinculados)
        final patients = snapshot.data ?? [];

        // Estado vacío: icono + texto explicativo en contenedor gris
        if (patients.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Icono grande de personas para el estado vacío
                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No tienes usuarios vinculados aún',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Lista no scrolleable (está dentro de SingleChildScrollView)
        return ListView.separated(
          shrinkWrap: true, // Ocupa solo el espacio de sus ítems
          physics: const NeverScrollableScrollPhysics(), // Delega scroll al padre
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8), // Separador entre tarjetas
          itemBuilder: (context, index) {
            final patient = patients[index];

            // Extraemos los campos con valores por defecto seguros
            final patientName = patient['name'] as String? ?? 'Usuario';
            final patientEmail = patient['email'] as String? ?? '';
            final patientAvatar = patient['avatar'] as String?;
            final linkedAt = patient['linkedAt'] as Timestamp?; // Fecha de vinculación

            return _buildPatientTile(
              patientId: patient['id'] as String,
              name: patientName,
              email: patientEmail,
              avatar: patientAvatar,
              linkedAt: linkedAt,
            );
          },
        );
      },
    );
  }

  // ── Tarjeta de un paciente vinculado ─────────────────────────────────────

  Widget _buildPatientTile({
    required String patientId,
    required String name,
    required String email,
    String? avatar,
    Timestamp? linkedAt, // Fecha en que se realizó la vinculación
  }) {
    return InkWell(
      // Al tocar la tarjeta: navega al panel de supervisión del tutor
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TutorSupervisarScreen(),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Avatar circular del paciente (asset o icono de persona)
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8EEF2),
              backgroundImage: avatar != null
                  ? AssetImage('assets/avatars/$avatar.png')
                  : null,
              // child se muestra solo si no hay backgroundImage
              child: avatar == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),

            // Datos del paciente: nombre, email y fecha de vinculación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  // Fecha de vinculación (solo si está disponible en Firestore)
                  if (linkedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Vinculado: ${_formatDate(linkedAt.toDate())}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            // Botón para desvincular al paciente (con confirmación)
            IconButton(
              onPressed: () => _removePatient(patientId, name),
              icon: const Icon(Icons.link_off, color: Colors.red),
              tooltip: 'Desvincular',
            ),

            // Flecha indicando que la tarjeta es navegable
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── Helper de formato de fecha ────────────────────────────────────────────

  // Formatea un DateTime a "DD Mes AAAA" en español sin depender del paquete intl.
  // Ejemplo: DateTime(2025, 6, 12) → "12 Jun 2025"
  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    // month es 1-based → restamos 1 para indexar el array
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
