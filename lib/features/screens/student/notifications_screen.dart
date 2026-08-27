import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/internship_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final InternshipService _api = InternshipService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsAsRead();
      if (!mounted) return;
      _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _repondreSuivi(String notificationId, String autorisationId, bool accepter) async {
    try {
      await _api.repondreDemandeSuivi(autorisationId, accepter);
      await _api.markNotificationAsRead(notificationId);
      if (!mounted) return;
      _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accepter ? 'Demande acceptée !' : 'Demande refusée.'))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tout lire',
                  style: TextStyle(color: ColorConstants.primary, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return _NotifCard(
                        notification: n,
                        onAcceptSuivi: (autoId) => _repondreSuivi(n['id'], autoId, true),
                        onRefuseSuivi: (autoId) => _repondreSuivi(n['id'], autoId, false),
                        onTap: () async {
                          if (n['read_at'] == null) {
                            await _api.markNotificationAsRead(n['id']);
                            _loadNotifications();
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'Aucune notification',
      subtitle: 'Vous êtes à jour ! Vos prochaines notifications apparaîtront ici.',
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final Function(String)? onAcceptSuivi;
  final Function(String)? onRefuseSuivi;

  const _NotifCard({
    required this.notification,
    required this.onTap,
    this.onAcceptSuivi,
    this.onRefuseSuivi,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification['data'] ?? {};
    final type = notification['type'] ?? '';
    final isRead = notification['read_at'] != null;
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now();

    // Style par défaut
    IconData icon = Icons.notifications_none_rounded;
    Color iconColor = ColorConstants.textSecondary;
    String title = data['title'] ?? 'Notification';
    String body = data['message'] ?? '';

    // Personnalisation selon le type (logique Laravel Notification)
    final isInvitation = type.contains('InvitationRattachement') || data['type'] == 'invitation_rattachement';
    final isDemandeSuivi = data['type'] == 'DEMANDE_SUIVI';

    if (type.contains('Encouragement')) {
      icon = Icons.favorite;
      iconColor = const Color(0xFFEC4899);
    } else if (type.contains('new_reservation') || data['type'] == 'new_reservation') {
      icon = Icons.directions_car_rounded;
      iconColor = ColorConstants.success;
      title = '🚗 Nouvelle réservation !';
    } else if (isInvitation) {
      icon = Icons.handshake_rounded;
      iconColor = ColorConstants.primary;
      title = '🤝 Invitation Reçue';
    } else if (isDemandeSuivi) {
      icon = Icons.visibility_outlined;
      iconColor = ColorConstants.accent;
    } else if (type.contains('CarnetValide')) {
      icon = Icons.check_circle;
      iconColor = ColorConstants.success;
    } else if (type.contains('Covoiturage')) {
      icon = Icons.directions_car_outlined;
      iconColor = ColorConstants.info;
    }

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12.5, color: ColorConstants.textSecondary)),
                const SizedBox(height: 6),
                Text(_timeAgo(createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: ColorConstants.textSecondary)),
                if (isInvitation && data['code'] != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      final code = data['code'].toString().trim();
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Code copié !')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: Text('Copier le code : ${data['code']}',
                      style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
                if (isDemandeSuivi && data['autorisation_id'] != null && !isRead) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onRefuseSuivi?.call(data['autorisation_id'].toString()),
                          style: OutlinedButton.styleFrom(foregroundColor: ColorConstants.error),
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => onAcceptSuivi?.call(data['autorisation_id'].toString()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: ColorConstants.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return DateFormat('dd/MM').format(date);
  }
}
