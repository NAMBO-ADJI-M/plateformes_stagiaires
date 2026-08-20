import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';

/// Écran de messagerie pour un trajet : affiche les messages et permet d'en envoyer.
/// Support offline : les messages sont queued en local si sans réseau.
class MessagesScreen extends StatefulWidget {
  final String trajetId;
  final String trajetTitre;

  const MessagesScreen({
    super.key,
    required this.trajetId,
    required this.trajetTitre,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageCtrl = TextEditingController();
  Timer? _pollingTimer;

  List<Map<String, dynamic>> _messages = [];
  bool _chargement = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerMessages(initial: true);
    // Rafraîchissement automatique toutes les 5 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _chargerMessages());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerMessages({bool initial = false}) async {
    if (initial) setState(() => _chargement = true);

    try {
      final messages = await _apiService.getTrajetMessages(widget.trajetId);
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(
            messages.map(
                (m) => m is Map<String, dynamic> ? m : {'message': m.toString()}),
          );
          _chargement = false;
        });
      }
    } catch (e) {
      if (initial && mounted) {
        setState(() {
          _erreur = 'Impossible de charger les messages';
          _chargement = false;
        });
      }
    }
  }

  Future<void> _envoyer() async {
    final texte = _messageCtrl.text.trim();
    if (texte.isEmpty) return;

    setState(() => _erreur = null);
    _messageCtrl.clear();
    setState(() => _envoi = true);

    try {
      await _apiService.sendTrajetMessage(widget.trajetId, texte);

      // Recharger les messages après envoi
      await _chargerMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message envoyé'),
            backgroundColor: ColorConstants.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        // Offline : message mis en queue
        if (mounted) {
          setState(() {
            _messages.insert(0, {
              'message': texte,
              'auteur': 'Vous',
              'cree_a': DateTime.now().toIso8601String(),
              'offline': true,
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏳ Message en attente (hors ligne)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _erreur = e.userFriendlyMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = 'Erreur lors de l\'envoi du message');
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(date.year, date.month, date.day);

      if (msgDate == today) {
        return DateFormat('HH:mm').format(date);
      } else if (msgDate == today.subtract(const Duration(days: 1))) {
        return 'Hier ${DateFormat('HH:mm').format(date)}';
      } else {
        return DateFormat('dd/MM HH:mm').format(date);
      }
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.cardBackground,
        foregroundColor: ColorConstants.textPrimary,
        title: Text(widget.trajetTitre),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Affichage erreur globale (connexion)
          if (_erreur != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _erreur!,
                      style: TextStyle(
                          color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Liste des messages
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun message pour l\'instant',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _messageBubble(_messages[i]),
                      ),
          ),

          // Champ d'entrée + bouton envoi
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageCtrl,
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          isCollapsed: true,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_envoi,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: ColorConstants.primary,
                      foregroundColor: Colors.white,
                      onPressed: _envoi ? null : _envoyer,
                      child: _envoi
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final texte = message['message'] as String? ?? '';
    final auteur = message['auteur'] as String? ?? 'Utilisateur';
    final dateStr = message['cree_a'] as String?;
    final offline = message['offline'] as bool? ?? false;

    final isMe = auteur == 'Vous';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? ColorConstants.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              texte,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDate(dateStr),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              if (offline) ...[
                const SizedBox(width: 4),
                Icon(Icons.schedule, size: 12, color: Colors.orange),
              ],
            ],
          ),
        ],
      ),
    );
  }
}