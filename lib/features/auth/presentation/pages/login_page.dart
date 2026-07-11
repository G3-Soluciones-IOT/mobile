import 'package:flutter/material.dart';
import 'package:jameofit/app/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function({
    required String username,
    required String password,
  })
  onSignIn;
  final Future<void> Function({
    required String username,
    required String password,
  })
  onSignUp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || widget.isLoading) return;
    final action = _isSignUpMode ? widget.onSignUp : widget.onSignIn;
    await action(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                    maxWidth: 430,
                  ),
                  child: Column(
                    children: [
                      _HeroPanel(isSignUpMode: _isSignUpMode),
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 34,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSignUpMode
                                      ? 'Crea tu cuenta'
                                      : 'Bienvenido otra vez',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF1A2238),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSignUpMode
                                      ? 'Registra tu usuario para entrar a JameoFit desde mobile.'
                                      : 'Ingresa tus credenciales para conectar la app con los microservicios.',
                                  style: const TextStyle(
                                    color: Color(0xFF6E7A96),
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                                if (widget.errorMessage != null) ...[
                                  const SizedBox(height: 18),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E5),
                                      borderRadius: BorderRadius.circular(14),
                                      border: const Border(
                                        left: BorderSide(
                                          color: Color(0xFFFF9800),
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      widget.errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFD96A00),
                                        fontSize: 13.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _InputLabel(label: 'Usuario'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _usernameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    'Ingresa tu usuario',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu usuario.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _InputLabel(label: 'Contrasena'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  textInputAction: _isSignUpMode
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _inputDecoration(
                                    _isSignUpMode
                                        ? 'Minimo 8 caracteres'
                                        : 'Ingresa tu contrasena',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa tu contrasena.';
                                    }
                                    if (_isSignUpMode && value.length < 8) {
                                      return 'La contrasena debe tener al menos 8 caracteres.';
                                    }
                                    return null;
                                  },
                                ),
                                if (_isSignUpMode) ...[
                                  const SizedBox(height: 16),
                                  _InputLabel(label: 'Confirmar contrasena'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: _inputDecoration(
                                      'Repite tu contrasena',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Confirma tu contrasena.';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Las contrasenas no coinciden.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: widget.isLoading
                                        ? null
                                        : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.brandGreen,
                                      disabledBackgroundColor: const Color(
                                        0xFFCAD0D8,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: widget.isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _isSignUpMode
                                                ? 'Crear cuenta'
                                                : 'Iniciar sesion',
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: TextButton(
                                    onPressed: widget.isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isSignUpMode = !_isSignUpMode;
                                            });
                                          },
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFF5F6C84),
                                          fontSize: 13.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: _isSignUpMode
                                                ? 'Ya tienes cuenta. '
                                                : 'No tienes cuenta. ',
                                          ),
                                          const TextSpan(
                                            text: 'Cambia aqui',
                                            style: TextStyle(
                                              color: AppTheme.brandGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isSignUpMode) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Por ahora el registro mobile crea solo el usuario en IAM.',
                                    style: TextStyle(
                                      color: Color(0xFF8892A6),
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9AA5B5)),
      filled: true,
      fillColor: const Color(0xFFF1F4F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE46B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE46B6B), width: 1.2),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.isSignUpMode});

  final bool isSignUpMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 320,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF173F2D), Color(0xFF2E6B51), Color(0xFF456C5A)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -40,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -45,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 18,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                      text: 'Jameo',
                      style: TextStyle(color: Color(0xFF16B548)),
                    ),
                    TextSpan(
                      text: 'Fit',
                      style: TextStyle(color: Color(0xFF1E9ADF)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16B548),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 118),
                    Text(
                      isSignUpMode
                          ? 'Crea tu acceso seguro'
                          : 'Precision Health',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isSignUpMode
                          ? 'Empieza en JameoFit con una cuenta lista para conectarse al backend.'
                          : 'Inicia sesion y entra a tu experiencia fitness conectada con datos reales.',
                      style: const TextStyle(
                        color: Color(0xFFD7E5DE),
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.ink,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}
