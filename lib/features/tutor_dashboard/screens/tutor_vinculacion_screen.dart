import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple/core/services/auth_service.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_patient_detail_screen.dart';

class TutorVinculacionScreen extends StatefulWidget {
  const TutorVinculacionScreen({super.key});

  @override
  State<TutorVinculacionScreen> createState() => _TutorVinculacionScreenState();
}

class _TutorVinculacionScreenState extends State<TutorVinculacionScreen> {
  bool _isGenerating = false;
  String? _currentCode;

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await AuthService.generateInvitationCode();
      setState(() => _currentCode = code);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('¡Código generado con éxito!'),
            backgroundColor: Colors.green,
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
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  Future<void> _removePatient(String patientId, String patientName) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular paciente'),
        content: Text('¿Estás seguro de que deseas desvincular a $patientName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.removePatientLink(patientId);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Paciente desvinculado'),
              backgroundColor: Colors.orange,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Pacientes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGenerateCodeCard(),
            if (_currentCode != null) ...[
              const SizedBox(height: 16),
              _buildCodeDisplayCard(_currentCode!),
            ],
            const SizedBox(height: 24),
            const Text(
              'Pacientes vinculados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLinkedPatientsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
          const Text(
            'El paciente deberá ingresar este código para vincularse contigo. El código expira en 7 días.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateCode,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isGenerating ? 'Generando...' : 'Generar código'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF764BA2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDisplayCard(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667EEA), width: 2),
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
              Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _copyCode(code),
                icon: const Icon(Icons.copy, color: Color(0xFF667EEA)),
                tooltip: 'Copiar código',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Válido por 7 días',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedPatientsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AuthService.getLinkedPatientsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final patients = snapshot.data ?? [];

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
                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No tienes pacientes vinculados aún',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final patient = patients[index];
            final patientName = patient['name'] as String? ?? 'Paciente';
            final patientEmail = patient['email'] as String? ?? '';
            final patientAvatar = patient['avatar'] as String?;
            final linkedAt = patient['linkedAt'] as Timestamp?;

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

  Widget _buildPatientTile({
    required String patientId,
    required String name,
    required String email,
    String? avatar,
    Timestamp? linkedAt,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TutorPatientDetailScreen(
            patientId: patientId,
            patientName: name,
            patientAvatar: avatar,
            patientEmail: email,
          ),
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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8EEF2),
            backgroundImage: avatar != null
                ? AssetImage('assets/avatars/$avatar.png')
                : null,
            child: avatar == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
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
          IconButton(
            onPressed: () => _removePatient(patientId, name),
            icon: const Icon(Icons.link_off, color: Colors.red),
            tooltip: 'Desvincular',
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
