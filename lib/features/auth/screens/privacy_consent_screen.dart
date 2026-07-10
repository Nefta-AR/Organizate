import 'package:flutter/material.dart';

import 'package:simple/core/services/auth_service.dart';
import 'package:simple/core/services/privacy_policy_service.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _accepted = false;
  bool _isSaving = false;

  Future<void> _saveAcceptance() async {
    if (!_accepted) {
      _showMessage('Debes aceptar la Política de Privacidad para continuar.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await PrivacyPolicyService.recordAcceptance(
        source: 'privacy_consent_screen',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo registrar la aceptación. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Privacidad'),
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _logout,
            child: const Text('Salir'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      PrivacyPolicyService.policyText,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: CheckboxListTile(
                  value: _accepted,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _accepted = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    PrivacyPolicyService.shortConsentText,
                    style: TextStyle(fontSize: 13, height: 1.3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAcceptance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Aceptar y continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
