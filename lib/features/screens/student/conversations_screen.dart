import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'messages_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.userFriendlyMessage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger vos messages';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        title: const Text('Mes Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: ColorConstants.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Aucune conversation',
          subtitle: 'Vos messages liés à vos trajets de covoiturage apparaîtront ici.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final conv = _conversations[index] as Map<String, dynamic>;
        return _ConversationTile(
          conversation: conv,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessagesScreen(
                  trajetId: conv['trajet_id'],
                  trajetTitre: '${conv['lieu_depart']} → ${conv['lieu_arrivee']}',
                ),
              ),
            ).then((_) => _loadConversations());
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastMsg = conversation['dernier_message'] as Map<String, dynamic>?;
    final chauffeur = conversation['chauffeur'] as Map<String, dynamic>?;
    final photo = chauffeur?['photo_profil_url'] as String? ?? chauffeur?['photo_profil'] as String?;
    final nom = chauffeur?['nom'] as String? ?? 'Conducteur';

    String timeStr = '';
    if (lastMsg?['cree_a'] != null) {
      final date = DateTime.tryParse(lastMsg!['cree_a']);
      if (date != null) {
        timeStr = DateFormat('HH:mm').format(date);
      }
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
            child: (photo == null || photo.isEmpty)
                ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${conversation['lieu_depart']} → ${conversation['lieu_arrivee']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(timeStr, style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastMsg != null
                    ? '${lastMsg['auteur']}: ${lastMsg['contenu']}'
                    : 'Aucun message pour le moment',
                  style: TextStyle(
                    fontSize: 13,
                    color: lastMsg != null ? ColorConstants.textPrimary : ColorConstants.textSecondary,
                    fontStyle: lastMsg != null ? FontStyle.normal : FontStyle.italic
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: ColorConstants.textSecondary, size: 20),
        ],
      ),
    );
  }
}
