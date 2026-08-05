import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class CodeLoginPage extends StatefulWidget {
  const CodeLoginPage({super.key});

  @override
  State<CodeLoginPage> createState() => _CodeLoginPageState();
}

class _CodeLoginPageState extends State<CodeLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _codeSent = false;
  bool _isLoading = false;
  String _message = '';

  UserType get userType {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserType) return args;
    return UserType.stagiaire;
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Veuillez saisir votre email.');
      return;
    }
    if (!_isEmailValid(email)) {
      setState(() => _message = 'Adresse email invalide.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Envoi du code en cours...';
    });

    try {
      await _authService.requestCode(userType, email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _message = 'Code envoyé sur $email.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is ApiException ? error.message : 'Erreur lors de l’envoi du code.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || code.isEmpty) {
      setState(() => _message = 'Veuillez saisir l’email et le code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyCode(userType, email, code);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is ApiException ? error.message : 'Erreur lors de la vérification du code.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    bool isActive = true;

    try {
      final GoogleSignInAccount? account = await GoogleSignIn().signIn();
      if (!mounted) {
        isActive = false;
      } else if (account != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion Google annulée.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur Google : $error')));
      }
    } finally {
      if (isActive && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = userType == UserType.stagiaire ? 'Stagiaire' : 'Entreprise';
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion $title'),
        backgroundColor: ColorConstants.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connexion ${title.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _message.contains('invalide') ||
                              _message.contains('Erreur')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              Text(
                _codeSent
                    ? 'Un code vous a été envoyé. Saisissez-le pour continuer.'
                    : 'Saisissez votre adresse email pour recevoir un code sécurisé.',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              if (!_codeSent) ...[
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'votre.email@exemple.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  label: 'Recevoir le code',
                  onPressed: _sendCode,
                ),
                const SizedBox(height: 24),
                _buildGoogleButton(),
              ] else ...[
                _buildTextField(
                  controller: _codeController,
                  label: 'Code',
                  hint: 'XXXXXX',
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  label: 'Valider le code',
                  onPressed: _verifyCode,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _codeSent = false),
                  child: const Text('Retour'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signInWithGoogle,
        icon: const Icon(Icons.login, color: Colors.black87),
        label: const Text('Se connecter avec Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}
