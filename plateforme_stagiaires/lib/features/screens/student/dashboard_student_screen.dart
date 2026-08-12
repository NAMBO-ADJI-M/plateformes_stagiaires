import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'covoiturage_home_screen.dart';
import 'notifications_screen.dart';
import 'logbook_placeholder_screen.dart';

class DashboardStudentScreen extends StatefulWidget {
  const DashboardStudentScreen({super.key});

  @override
  State<DashboardStudentScreen> createState() => _DashboardStudentScreenState();
}

class _DashboardStudentScreenState extends State<DashboardStudentScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;

  // Profil
  String _prenom = '';
  String _ecole = '';
  String _filiere = '';
  String? _photoUrl;

  // Carnet
  bool _hasCarnet = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profileResponse = await _api.getProfile();
      final stagiaire = profileResponse['profile_data'] as Map<String, dynamic>?;

      _prenom = (stagiaire?['prenom'] as String?) ?? '';
      _ecole = (stagiaire?['ecole'] as String?) ?? '';
      _filiere = (stagiaire?['filiere'] as String?) ?? '';
      _photoUrl = stagiaire?['photo_profil'] as String?;

      final carnets = await _api.getCarnets();

      if (carnets.isEmpty) {
        setState(() {
          _hasCarnet = false;
          _loading = false;
        });
        return;
      }

      // On prend le carnet EN_COURS le plus récent, sinon le premier
      final carnet = carnets.firstWhere(
        (c) => c['statut'] == 'EN_COURS',
        orElse: () => carnets.first,
      ) as Map<String, dynamic>;

      final stats = await _api.getCarnetStats(carnet['id'] as String);

      setState(() {
        _hasCarnet = true;
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Une erreur est survenue. Vérifiez votre connexion.';
        _loading = false;
      });
    }
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  ({IconData icon, Color color}) _activityStyle(String type) {
    switch (type) {
      case 'mission':
        return (icon: Icons.check_circle, color: ColorConstants.success);
      case 'presence':
        return (icon: Icons.event_available_outlined, color: ColorConstants.primary);
      case 'difficulte':
        return (icon: Icons.error_outline, color: ColorConstants.accentOrange);
      case 'felicitation':
        return (icon: Icons.emoji_events_outlined, color: ColorConstants.accentOrange);
      case 'encouragement':
        return (icon: Icons.favorite_outline, color: ColorConstants.info);
      default:
        return (icon: Icons.notes_outlined, color: ColorConstants.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: ColorConstants.textSecondary),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadDashboard, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: GreetingHeader(
                  title: 'Bonjour, $_prenom 👋',
                  subtitle: [_ecole, _filiere].where((s) => s.isNotEmpty).join(' • '),
                  avatarUrl: _photoUrl ?? 'https://i.pravatar.cc/150?img=32',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: ColorConstants.textPrimary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_hasCarnet) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aucun carnet de stage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: ColorConstants.textPrimary)),
                  const SizedBox(height: 6),
                  const Text(
                    'Créez votre carnet de stage pour commencer à suivre votre progression.',
                    style: TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: brancher sur l'écran de création de carnet
                    },
                    child: const Text('Créer mon carnet'),
                  ),
                ],
              ),
            ),
          ] else ...[
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progression globale',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                                color: ColorConstants.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          '${_stats?['jours_presents'] ?? 0} jours de présence sur '
                          '${_stats?['jours_attendus'] ?? 0} attendus.',
                          style: const TextStyle(
                              fontSize: 12.5, color: ColorConstants.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ProgressRing(
                    percent: ((_stats?['progression_globale'] ?? 0) as int) / 100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                StatMiniCard(
                    icon: Icons.calendar_today_rounded,
                    iconColor: ColorConstants.primary,
                    value: '${_stats?['jours_presents'] ?? 0} / ${_stats?['jours_attendus'] ?? 0}',
                    label: 'Jours de stage'),
                const SizedBox(width: 10),
                StatMiniCard(
                    icon: Icons.check_circle_outline,
                    iconColor: ColorConstants.success,
                    value: '${_stats?['missions_completees'] ?? 0} / ${_stats?['missions_totales'] ?? 0}',
                    label: 'Missions complétées'),
                const SizedBox(width: 10),
                StatMiniCard(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: ColorConstants.accentOrange,
                    value: '${_stats?['competences_validees'] ?? 0}',
                    label: 'Compétences validées'),
              ],
            ),
          ],
          const SizedBox(height: 22),
          const Text('Raccourcis',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ShortcutTile(
                icon: Icons.menu_book_outlined,
                label: 'Carnet de stage',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LogbookPlaceholderScreen())),
              ),
              const SizedBox(width: 10),
              _ShortcutTile(
                icon: Icons.directions_car_outlined,
                label: 'Covoiturage',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CovoiturageHomeScreen())),
              ),
              const SizedBox(width: 10),
              const _ShortcutTile(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
              ),
            ],
          ),
          if (_hasCarnet) ...[
            const SizedBox(height: 22),
            const Text('Activités récentes',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            const SizedBox(height: 10),
            if ((_stats?['activites_recentes'] as List?)?.isEmpty ?? true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune activité pour le moment.',
                    style: TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary)),
              )
            else
              ...List.generate((_stats!['activites_recentes'] as List).length, (i) {
                final a = (_stats!['activites_recentes'] as List)[i] as Map<String, dynamic>;
                final style = _activityStyle(a['type'] as String? ?? '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActivityTile(
                    icon: style.icon,
                    iconColor: style.color,
                    bg: style.color,
                    title: a['title'] as String? ?? '',
                    subtitle: (a['subtitle'] as String?)?.isNotEmpty == true
                        ? a['subtitle'] as String
                        : '—',
                    time: _timeAgo(a['date'] as String?),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ShortcutTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: ColorConstants.primary),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primary)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback? onTap;

  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                  fontSize: 11, color: ColorConstants.textSecondary)),
        ],
      ),
    );
  }
}