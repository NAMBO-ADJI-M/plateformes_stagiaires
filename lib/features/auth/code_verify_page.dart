import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/auth_service.dart';

class CodeVerifyPage extends StatefulWidget {
  final String email;
  final UserType userType;

  const CodeVerifyPage({
    super.key,
    required this.email,
    required this.userType,
  });

  @override
  State<CodeVerifyPage> createState() => _CodeVerifyPageState();
}

class _CodeVerifyPageState extends State<CodeVerifyPage> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _message = '';
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
          }
        });
      }
      return _resendCountdown > 0 && mounted;
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

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
      final result = await _authService.verifyCode(widget.email, code);

      if (!mounted) return;

      if (result.containsKey('token') && result['token'] != null) {
        // ✅ Connexion réussie
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return; // on quitte avant le finally : la page n'existe plus dans la pile
      } else {
        // ❌ Réponse OK mais pas de token exploitable
        setState(() {
          _message = 'Code invalide ou expiré. Veuillez réessayer.';
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
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _message = 'Envoi du code...';
    });

    try {
      await _authService.resendCode(widget.email);
      setState(() {
        _message = '📧 Un nouveau code a été envoyé à ${widget.email}.';
        _canResend = false;
        _resendCountdown = 60;
      });
      _startCountdown();
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

 void _goBackToLogin() {
  Navigator.pushReplacementNamed(
    context,
    '/register-code',
    arguments: {
      'email': widget.email,
      'userType': widget.userType,
    },
  );
}

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                'Vérification',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Sous-titre
              Text(
                'Un code de vérification a été envoyé à',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                widget.email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Code
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  hintText: '000000',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorConstants.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton vérifier
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('VÉRIFIER'),
                ),
              ),
              const SizedBox(height: 16),

              // Renvoyer le code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vous n\'avez pas reçu le code ?',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  if (_canResend)
                    TextButton(
                      onPressed: _resendCode,
                      child: const Text('Renvoyer'),
                    )
                  else
                    Text(
                      '($_resendCountdown s)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Retour
              TextButton(
                onPressed: _goBackToLogin,
                child: const Text('Retour à la connexion'),
              ),

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
      ),
    );
  }
}
