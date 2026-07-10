// ============================================================
// lib/features/auth/screens/login_screen.dart
// ============================================================
// Pantalla dual de autenticación: alterna entre modo LOGIN y REGISTRO
// mediante el booleano _isLogin. Ambos modos comparten el mismo Form
// pero el modo Registro muestra un campo extra para el nombre.
//
// Flujos de autenticación disponibles:
//   1. Email + Contraseña  (_handleLogin)
//   2. Google OAuth        (_handleGoogleLogin)
//   3. Recuperación de contraseña (_handleForgotPassword)
//
// Después de un login exitoso se navega a '/' (root), lo que dispara
// a AuthGate para que re-evalúe el estado y redirija correctamente.
//
// Persistencia: el último email usado se guarda en SharedPreferences
// para pre-rellenar el campo en el siguiente inicio de la app.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple/core/services/privacy_policy_service.dart';

/// Paleta de colores interna de la pantalla de login.
/// Se define como clase privada para que no contamine el namespace global.
class _Palette {
  _Palette._();
  static const background = Color(0xFFF5F7FA); // Fondo gris muy claro
  static const primary    = Color(0xFF4A90E2); // Azul principal
  static const surface    = Colors.white;       // Fondo de tarjetas / inputs
  static const textDark   = Color(0xFF2D3748); // Texto principal oscuro
  static const textMuted  = Color(0xFF718096); // Texto secundario gris
  static const border     = Color(0xFFE2E8F0); // Borde de inputs
}

/// Radio de borde estándar para inputs y botones en esta pantalla.
const double _kRadius = 14;
const String _kPasswordRuleError =
    'La contraseña debe contener mínimo 6 caracteres, incluyendo una letra '
    'y un número. Ej.: Simple8';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Clave global del Form para poder llamar a _formKey.currentState!.validate().
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos de texto.
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController(); // Solo visible en modo REGISTRO

  // Modo de la pantalla: true = Login, false = Registro.
  bool _isLogin          = true;
  // Indicadores de carga para deshabilitar botones durante peticiones async.
  bool _isLoading        = false; // Login / Registro con email
  bool _isGoogleLoading  = false; // Login con Google
  // Controla si la contraseña es visible o está oculta con puntos.
  bool _obscurePassword  = true;
  bool _hasAcceptedPrivacyPolicy = false;

  @override
  void initState() {
    super.initState();
    // Carga el email guardado de la sesión anterior para comodidad del usuario.
    _loadSavedEmail();
  }

  @override
  void dispose() {
    // Libera los controladores de texto al desmontar el widget para evitar memory leaks.
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Recupera el último email usado desde SharedPreferences y lo pone en el campo.
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_email');
    // Verifica mounted porque este método es async y el widget puede desmontarse
    // antes de que SharedPreferences resuelva.
    if (!mounted || saved == null) return;
    _emailController.text = saved;
  }

  /// Persiste el email en SharedPreferences para reutilizarlo la próxima vez.
  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  /// Maneja el flujo de login o registro con email y contraseña.
  ///
  /// En modo LOGIN: llama signInWithEmailAndPassword.
  /// En modo REGISTRO: crea la cuenta y luego escribe el documento Firestore
  /// inicial con rol 'usuario', puntos en 0, racha en 0.
  Future<void> _handleLogin() async {
    // Ejecuta todos los validators del Form antes de continuar.
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && !_hasAcceptedPrivacyPolicy) {
      _showError('Debes aceptar la Política de Privacidad para crear tu cuenta.');
      return;
    }
    setState(() => _isLoading = true);

    final auth     = FirebaseAuth.instance;
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        // ── LOGIN ──────────────────────────────────────────────────────
        await auth.signInWithEmailAndPassword(email: email, password: password);
        await _saveEmail(email);
      } else {
        // ── REGISTRO ───────────────────────────────────────────────────
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = cred.user;
        if (user != null) {
          // Actualiza el displayName de Firebase Auth para que aparezca
          // en otras partes de la app sin leer Firestore.
          await user.updateDisplayName(_nameController.text.trim());

          // Crea el documento Firestore del usuario con valores iniciales.
          // SetOptions(merge: true) por seguridad: si el doc ya existe no lo borra.
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name':                   _nameController.text.trim(),
            'email':                  email,
            'role':                   'usuario',       // Rol por defecto; cambiable en RoleSelectionScreen
            'avatar':                 'emoticon',      // Avatar por defecto
            'points':                 0,               // Puntos de gamificación
            'streak':                 0,               // Racha diaria de tareas
            'hasCompletedProfile':    true,            // El nombre ya está puesto en el registro
            'hasCompletedOnboarding': false,           // AuthGate redirigirá a RoleSelectionScreen
            'createdAt':              FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await PrivacyPolicyService.recordAcceptance(
            source: 'login_email_register',
            user: user,
          );
          await _saveEmail(email);
        }
      }
      // Navega a '/' limpiando el stack. AuthGate reacciona al nuevo estado de Auth.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      // Mapea los códigos de error de Firebase a mensajes en español.
      if (mounted) _showError(_mapAuthError(e.code));
    } catch (_) {
      if (mounted) _showError('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      // Siempre desactiva el spinner, haya error o no.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Maneja el login con Google en plataformas web y móvil.
  ///
  /// Web: usa signInWithPopup (abre ventana emergente del navegador).
  /// Móvil: usa el flujo nativo de GoogleSignIn que abre el selector de cuentas del SO.
  Future<void> _handleGoogleLogin() async {
    // Evita doble tap durante la carga.
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final UserCredential userCred;

      if (kIsWeb) {
        // kIsWeb es una constante de Flutter que es true solo en compilación web.
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'}); // Siempre muestra selector
        userCred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // En móvil, abre el selector nativo de cuentas de Google.
        final googleUser = await GoogleSignIn().signIn();
        // El usuario canceló el selector (no es un error, simplemente no hace nada).
        if (googleUser == null) return;

        // Obtiene los tokens OAuth2 de la cuenta seleccionada.
        final googleAuth = await googleUser.authentication;
        // Crea las credenciales de Firebase a partir de los tokens de Google.
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        );
        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCred.user;

      if (user != null) {
        // isNewUser es true solo en el PRIMER login de esta cuenta de Google.
        final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
        // Datos básicos que se actualizan en cada login para mantener el nombre sincronizado.
        final payload = {
          'name':  user.displayName ?? 'Usuario de Simple',
          'email': user.email,
        };
        if (isNew) {
          // Usuario nuevo: crea documento completo en Firestore.
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            ...payload,
            'role':                   'usuario',
            'avatar':                 'emoticon',
            'points':                 0,
            'streak':                 0,
            'hasCompletedProfile':    true,
            'hasCompletedOnboarding': false, // Irá a RoleSelectionScreen
            'createdAt':              FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          if (user.email != null) await _saveEmail(user.email!);
        } else {
          // Usuario existente: solo actualiza nombre y email (por si cambió en Google).
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(payload, SetOptions(merge: true));
          if (user.email != null) await _saveEmail(user.email!);
        }
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_mapAuthError(e.code));
    } catch (_) {
      if (mounted) _showError('No pudimos iniciar sesión con Google. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Envía un correo de recuperación de contraseña al email del campo.
  ///
  /// Requiere que el email ya esté escrito; si no, muestra un aviso.
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Escribe tu correo arriba para recibir el enlace.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Te enviamos el enlace para restablecer tu contraseña.'),
        behavior: SnackBarBehavior.floating,
      ));
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (_) {
      _showError('No se pudo enviar el correo.');
    }
  }

  /// Traduce los códigos de error de Firebase Auth a mensajes amigables en español.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Se agrupan para no revelar si el email existe (seguridad).
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Inicia sesión.';
      case 'weak-password':
        return _kPasswordRuleError;
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      default:
        return 'Error inesperado ($code). Intenta de nuevo.';
    }
  }

  /// Muestra un SnackBar flotante con el mensaje de error.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _showPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Política de Privacidad'),
        content: const SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              PrivacyPolicyService.policyText,
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyAcceptance() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isLogin
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _Palette.surface,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: _Palette.border, width: 1.5),
                ),
                child: CheckboxListTile(
                  value: _hasAcceptedPrivacyPolicy,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(
                            () => _hasAcceptedPrivacyPolicy = value ?? false,
                          ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Acepto la Política de Privacidad de Simple. ',
                        style: TextStyle(
                          color: _Palette.textDark,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                      TextButton(
                        onPressed: _showPrivacyPolicy,
                        style: TextButton.styleFrom(
                          foregroundColor: _Palette.primary,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Ver política',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Construye un campo de texto con estilo unificado para toda la pantalla.
  /// El diseño sigue las guías de accesibilidad WCAG 2.1 AA (contraste, tamaño).
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    bool centerError = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      errorBuilder: centerError
          ? (context, errorText) => SizedBox(
                width: double.infinity,
                child: Text(
                  errorText,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: Color(0xFFE53E3E),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              )
          : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: _Palette.textDark, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
        errorMaxLines: 3,
        filled: true,
        fillColor: _Palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        // Sin borde por defecto para un look más limpio.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: BorderSide.none,
        ),
        // Borde sutil cuando el campo no tiene foco.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: _Palette.border, width: 1.5),
        ),
        // Borde azul cuando el campo está activo.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: _Palette.primary, width: 2),
        ),
        // Borde rojo cuando hay un error de validación.
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: Color(0xFFE53E3E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      // Copyright al fondo de la pantalla, por encima del área del teclado.
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            '© 2026 Simple · Tu ayuda cognitiva',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _Palette.textMuted),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo y título ────────────────────────────────────
                  Image.asset('assets/images/logosimple.png', height: 140),
                  const SizedBox(height: 20),
                  const Text(
                    'Simple',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: _Palette.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu ayuda cognitiva',
                    style: TextStyle(fontSize: 15, color: _Palette.textMuted),
                  ),
                  const SizedBox(height: 36),

                  // ── Botón Google ─────────────────────────────────────
                  _GoogleButton(
                    isLoading: _isGoogleLoading,
                    onTap: _handleGoogleLogin,
                  ),
                  const SizedBox(height: 24),

                  // ── Separador "o continúa con correo" ────────────────
                  const Row(children: [
                    Expanded(child: Divider(color: _Palette.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o continúa con correo',
                        style: TextStyle(fontSize: 12, color: _Palette.textMuted),
                      ),
                    ),
                    Expanded(child: Divider(color: _Palette.border)),
                  ]),
                  const SizedBox(height: 20),

                  // ── Campo Nombre (solo en modo REGISTRO) ─────────────
                  // AnimatedSize anima la aparición/desaparición del campo.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _isLogin
                        ? const SizedBox.shrink() // Invisible en modo login
                        : Column(children: [
                            _buildInput(
                              controller: _nameController,
                              label: 'Tu nombre',
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Ingresa un nombre válido'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                          ]),
                  ),

                  // ── Campo Email ──────────────────────────────────────
                  _buildInput(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty || !v.contains('@'))
                            ? 'Ingresa un correo válido'
                            : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Campo Contraseña ─────────────────────────────────
                  _buildInput(
                    controller: _passwordController,
                    label: 'Contraseña',
                    obscureText: _obscurePassword,
                    centerError: true,
                    validator: (v) {
                      final password = v ?? '';
                      final hasLetter =
                          RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(password);
                      final hasNumber = RegExp(r'\d').hasMatch(password);
                      if (password.length < 6 || !hasLetter || !hasNumber) {
                        return _kPasswordRuleError;
                      }
                      return null;
                    },
                    // Botón ojo para alternar visibilidad de la contraseña.
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _Palette.textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // ── "¿Olvidaste tu contraseña?" (solo en modo LOGIN) ─
                  _buildPrivacyPolicyAcceptance(),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: _Palette.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // ── Botón principal de acción ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Deshabilita el botón durante la carga para evitar doble envío.
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: Colors.white,
                        // Color semitransparente cuando está deshabilitado.
                        disabledBackgroundColor:
                            _Palette.primary.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRadius),
                        ),
                        elevation: 0,
                      ),
                      // Muestra spinner mientras carga, texto cuando está listo.
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Toggle LOGIN ↔ REGISTRO ──────────────────────────
                  TextButton(
                    // Bloquea el toggle durante una operación en curso.
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isLogin = !_isLogin;
                              // Resetea errores de validación al cambiar de modo.
                              _formKey.currentState?.reset();
                            }),
                    style: TextButton.styleFrom(
                      foregroundColor: _Palette.primary,
                    ),
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de inicio de sesión con Google con estado de carga.
///
/// Se extrae como widget separado para mantener el árbol de build de
/// LoginScreen más legible y reutilizar el botón si se necesita en otra pantalla.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(_kRadius),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadius),
          // Deshabilita el tap durante la carga.
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
            child: isLoading
                // Spinner centrado mientras carga.
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _Palette.primary,
                      ),
                    ),
                  )
                // Fila con logo de Google y texto.
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/google.png', height: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Continuar con Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _Palette.textDark,
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
