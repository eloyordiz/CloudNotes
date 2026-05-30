import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // CONTROLADORES DE EMAIL Y CONTRASEÑA
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // VARIABLE PARA ALTERNAR ENTRE LOGIN Y REGISTRO
  bool _isLogin = true;

  bool _isLoading = false;
  String _errorMessage = '';

  // FUNCIÓN PARA GESTIONAR EL ACCESO
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    dynamic result;
    if (_isLogin) {
      result = await _auth.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      result = await _auth.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (result == null) {
      setState(() {
        _errorMessage = _isLogin
            ? 'Error al iniciar sesión. Revisa tus datos.'
            : 'Error al registrarse. El correo podría ya estar en uso.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // VARIABLE PARA SABER SI ESTAMOS EN UN MÓVIL O DESKTOP
    // PONEMOS EL BREAKPOINT EN 1000 DE ANCHO
    final bool isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // DESKTOP: MENÚ LATERAL
          if (!isMobile)
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.blue.shade700,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo_border.png',
                      width: 300,
                      height: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'CloudNotes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tus notas sincronizadas en la nube',
                      style: TextStyle(
                        color: Colors.blue.shade100,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // DESKTOP Y MÓVIL: COLUMNA DERECHA PRINCIPAL
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isMobile) ...[
                        Image.asset('assets/logo.png', width: 300, height: 100),
                        const SizedBox(height: 16),
                        Text(
                          'Bienvenido a CloudNotes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      Text(
                        _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Introduce un correo' : null,
                      ),
                      const SizedBox(height: 16),

                      // Campo Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (val) =>
                            val!.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),

                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // BOTÓN DE LOGIN/REGISTRO
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'INGRESAR' : 'REGISTRARME',
                              ),
                            ),

                      const SizedBox(height: 16),

                      // BOTÓN DE CAMBIO ENTRE LOGIN/REGISTRO
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? '¿No tienes cuenta? Regístrate'
                              : '¿Ya tienes cuenta? Identifícate',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
