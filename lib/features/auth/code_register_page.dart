import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/auth_service.dart';

class CodeRegisterPage extends StatefulWidget {
  final String email;
  final UserType userType;

  const CodeRegisterPage({
    super.key,
    this.email = '',
    this.userType = UserType.stagiaire,
  });

  @override
  State<CodeRegisterPage> createState() => _CodeRegisterPageState();
}

class _CodeRegisterPageState extends State<CodeRegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    if (widget.email.isNotEmpty) {
      _emailController.text = widget.email;
    }
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _handleRequestCode() async {
    final email = _emailController.text.trim().toLowerCase();

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
      // Le backend crée le compte automatiquement s'il n'existe pas
      // et envoie un code de vérification par email dans tous les cas.
      await _authService.requestCode(email, widget.userType);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/verify-code',
        arguments: {
          'email': email,
          'userType': widget.userType,
        },
      );
    } on ApiException catch (e) {
      setState(() {
        _message = e.userFriendlyMessage;
      });
    } catch (e) {
      setState(() {
        _message = 'Erreur lors de l\'envoi du code. Veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.userType == UserType.stagiaire ? 'Stagiaire' : 'Entreprise';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: ColorConstants.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: ColorConstants.glowShadow(ColorConstants.primary),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Carnet de Stage',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Accès $title',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Connexion',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saisissez votre adresse email pour recevoir un code à 6 chiffres.',
                  style: GoogleFonts.poppins(
                    color: ColorConstants.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.alternate_email_rounded,
                  hint: 'votre@email.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                // Bouton d'envoi du code
                _buildActionButton(
                  label: 'RECEVOIR MON CODE',
                  onPressed: _handleRequestCode,
                  isLoading: _isLoading,
                ),

                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _message.contains('✅') || _message.contains('📧')
                            ? Colors.blue.shade50
                            : _message.contains('Erreur') ||
                                    _message.contains('incorrect') ||
                                    _message.contains('invalide')
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _message.contains('✅') || _message.contains('📧')
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
                          color: _message.contains('✅') || _message.contains('📧')
                              ? Colors.blue.shade700
                              : _message.contains('Erreur') ||
                                      _message.contains('incorrect') ||
                                      _message.contains('invalide')
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    Widget? suffixIcon,
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
          suffixIcon: suffixIcon,
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
        shadowColor: ColorConstants.primary.withValues(alpha: 0.39),
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
