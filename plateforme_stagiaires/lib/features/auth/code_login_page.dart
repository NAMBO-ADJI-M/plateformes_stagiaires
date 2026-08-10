// lib/features/auth/code_login_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/auth_service.dart';

class CodeLoginPage extends StatefulWidget {
  final UserType userType;

  const CodeLoginPage({
    super.key,
    this.userType = UserType.stagiaire,
  });

  @override
  State<CodeLoginPage> createState() => _CodeLoginPageState();
}

class _CodeLoginPageState extends State<CodeLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _codeSent = false;
  bool _isLoading = false;
  String _message = '';
  String? _currentEmail;

  // ✅ SUPPRIMER _userType - Utiliser widget.userType directement
  // UserType _userType = UserType.stagiaire;  // ❌ À SUPPRIMER

  bool _isEmailValid(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _message = 'Veuillez saisir votre email.');
      return;
    }
    if (!_isEmailValid(email)) {
      setState(() => _message = 'Adresse email invalide.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _message = 'Veuillez saisir votre mot de passe.');
      return;
    }
    if (password.length < 8) {
      setState(() => _message = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Connexion en cours...';
      _currentEmail = email;
    });

    try {
      // ✅ Utiliser widget.userType
      final result = await _authService.login(email, password, widget.userType);

      if (!mounted) return;

      if (result.containsKey('token') && result['token'] != null && result['token'].toString().isNotEmpty) {
        _navigateToDashboard();
        return;
      }

      if (result['requires_verification'] == true) {
        setState(() {
          _codeSent = true;
          _message = '📧 Un code de vérification a été envoyé à $email.';
        });
        return;
      }

      setState(() {
        _message = result['message'] ?? 'Une erreur est survenue.';
      });
    } on ApiException catch (e) {
      setState(() {
        _message = e.userFriendlyMessage;
      });
    } catch (e) {
      setState(() {
        _message = 'Erreur lors de la connexion. Veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final email = _currentEmail ?? _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty) {
      setState(() => _message = 'Email requis.');
      return;
    }
    if (code.isEmpty) {
      setState(() => _message = 'Veuillez saisir le code à 6 chiffres.');
      return;
    }
    if (code.length != 6) {
      setState(() => _message = 'Le code doit contenir 6 chiffres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Vérification en cours...';
    });

    try {
      final result = await _authService.verifyCode(email, code);

      if (!mounted) return;

      if (result.containsKey('token') && result['token'] != null && result['token'].toString().isNotEmpty) {
        _navigateToDashboard();
      } else {
        setState(() {
          _message = result['message'] ?? 'Erreur lors de la vérification.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _message = e.userFriendlyMessage;
      });
    } catch (e) {
      setState(() {
        _message = 'Erreur lors de la vérification du code.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    final email = _currentEmail ?? _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _message = 'Email requis.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Envoi du code...';
    });

    try {
      await _authService.resendCode(email);
      setState(() {
        _message = '📧 Un nouveau code a été envoyé à $email.';
      });
    } on ApiException catch (e) {
      setState(() {
        _message = e.userFriendlyMessage;
      });
    } catch (e) {
      setState(() {
        _message = 'Erreur lors de l\'envoi du code.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _goBackToLogin() {
    setState(() {
      _codeSent = false;
      _message = '';
      _codeController.clear();
    });
  }

  void _goToRegister() {
  Navigator.pushReplacementNamed(
    context,
    '/register-code',
    arguments: {'userType': widget.userType},  // ✅ Map au lieu de UserType brut
  );
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Utiliser widget.userType
    final title = widget.userType == UserType.stagiaire ? 'Stagiaire' : 'Entreprise';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 40),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: ColorConstants.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PS',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connexion $title',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _codeSent ? 'Vérification' : 'Bienvenue !',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Saisissez le code à 6 chiffres reçu par email.'
                        : 'Entrez vos identifiants pour continuer.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_codeSent) ...[
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.alternate_email,
                      hint: 'votre@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline,
                      hint: 'Minimum 8 caractères',
                      obscureText: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '💡 Si vous n\'avez pas de compte, il sera créé automatiquement.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      label: 'SE CONNECTER',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ?',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _goToRegister,
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _codeController,
                      label: 'Code de vérification',
                      icon: Icons.pin_outlined,
                      hint: '000000',
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '📧 Code envoyé à ${_currentEmail ?? _emailController.text}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      label: 'VALIDER LE CODE',
                      onPressed: _verifyCode,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : _resendCode,
                          child: const Text('Renvoyer le code'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isLoading ? null : _goBackToLogin,
                          child: const Text('Modifier l\'email'),
                        ),
                      ],
                    ),
                  ],

                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _message.contains('📧')
                              ? Colors.blue.shade50
                              : _message.contains('Erreur') ||
                                      _message.contains('incorrect') ||
                                      _message.contains('invalide')
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _message.contains('📧')
                                ? Colors.blue.shade200
                                : _message.contains('Erreur') ||
                                        _message.contains('incorrect') ||
                                        _message.contains('invalide')
                                    ? Colors.red.shade200
                                    : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _message.contains('📧')
                                ? Colors.blue.shade700
                                : _message.contains('Erreur') ||
                                        _message.contains('incorrect') ||
                                        _message.contains('invalide')
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: ColorConstants.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 4,
        shadowColor: ColorConstants.primary.withAlpha(100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}