import 'package:flutter/material.dart';
import 'package:simple/core/services/auth_service.dart';

class PacienteVinculacionScreen extends StatefulWidget {
  const PacienteVinculacionScreen({super.key});

  @override
  State<PacienteVinculacionScreen> createState() =>
      _PacienteVinculacionScreenState();
}

class _PacienteVinculacionScreenState extends State<PacienteVinculacionScreen> {
  final _codeController = TextEditingController();
  bool _isValidating = false;
  bool _isAccepting = false;
  Map<String, dynamic>? _validationResult;
  bool _isLinked = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLinked();
  }

  Future<void> _checkIfAlreadyLinked() async {
    final tutorStream = AuthService.getLinkedTutorStream();
    await for (final tutor in tutorStream) {
      if (mounted) {
        setState(() => _isLinked = tutor != null);
        break;
      }
    }
  }

  Future<void> _validateCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un código')),
      );
      return;
    }

    setState(() => _isValidating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await AuthService.validateInvitationCode(
        _codeController.text.trim(),
      );
      setState(() => _validationResult = result);
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

  Future<void> _acceptCode() async {
    setState(() => _isAccepting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.acceptInvitationCode(_codeController.text.trim());
      if (mounted) {
        setState(() => _isLinked = true);
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
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildCodeInputCard(),
            if (_validationResult != null && _validationResult!['valid'] == true)
              ...[
                const SizedBox(height: 16),
                _buildValidationSuccessCard(),
              ],
            const SizedBox(height: 24),
            _buildHowItWorksCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyLinkedView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Tutor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: AuthService.getLinkedTutorStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final tutor = snapshot.data;
            if (tutor == null) {
              return const Text('No tienes un tutor vinculado');
            }

            final tutorName = tutor['name'] as String? ?? 'Tutor';
            final tutorEmail = tutor['email'] as String? ?? '';
            final tutorAvatar = tutor['avatar'] as String?;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
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
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Estás vinculado!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withAlpha(50),
                      backgroundImage: tutorAvatar != null
                          ? AssetImage('assets/avatars/$tutorAvatar.png')
                          : null,
                      child: tutorAvatar == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tutorName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ingresa el código que te proporcionó tu tutor para establecer la vinculación. Esto permitirá que tu tutor supervise tu progreso.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

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
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Ej: A7K2NP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            maxLength: 6,
            onSubmitted: (_) => _validateCode(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isValidating ? null : _validateCode,
              icon: _isValidating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF11998E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tutor: $tutorName',
                      style: const TextStyle(fontSize: 14),
                    ),
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
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(_isAccepting
                  ? 'Vinculando...'
                  : 'Aceptar y vincularme'),
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
          _buildStep(
            number: 1,
            title: 'Tu tutor genera un código',
            description: 'El tutor crea un código de 6 caracteres desde su panel.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: 2,
            title: 'Comparte el código contigo',
            description: 'Te lo envía por mensaje, email o te lo dice directamente.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: 3,
            title: 'Ingresa y valida el código',
            description: 'Escribe el código aquí y presiona "Validar".',
          ),
          const SizedBox(height: 8),
          _buildStep(
            number: 4,
            title: '¡Listo!',
            description: 'Acepta la vinculación y tu tutor podrá ver tu progreso.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF11998E),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
