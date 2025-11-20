import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = FirebaseAuth.instance;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        await _saveCredentials(email, password);
      } else {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': email,
            'avatar': 'emoticon',
            'points': 0,
            'streak': 0,
            'hasCompletedOnboarding': false,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await _saveCredentials(email, password);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Ocurrió un error inesperado');
    } catch (e) {
      _showError('Ocurrió un error inesperado');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    if (!mounted) return;
    setState(() {
      if (savedEmail != null) _emailController.text = savedEmail;
      if (savedPassword != null) _passwordController.text = savedPassword;
    });
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresa tu correo para recuperar la contraseña');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revisa tu correo para restablecer la contraseña'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'No se pudo enviar el correo');
    } catch (_) {
      _showError('No se pudo enviar el correo');
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⭐ LOGO MÁS ARRIBA ⭐
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/logo.png',
                height: 110,
              ),

              const SizedBox(height: 16),

              const Text(
                'Organízate',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              // ⭐ FORMULARIO ⭐
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Ingresa un nombre válido';
                          }
                          return null;
                        },
                      ),

                    if (!_isLogin) const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _sendPasswordReset,
                        child: const Text('¿Olvidaste la contraseña?'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Ingresar' : 'Crear cuenta'),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                      child: Text(_isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : 'Ya tienes cuenta? Inicia sesión'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
