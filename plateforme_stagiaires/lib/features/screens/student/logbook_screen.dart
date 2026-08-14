import 'package:flutter/material.dart';
import '../../../../../core/constants/constants_colors.dart';
import '../../../../../services/api_service.dart';
import '../../../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'carnet_creation_page.dart';

class LogbookScreen extends StatefulWidget {
  final String carnetId;

  /// Indique si CE carnet est déjà rattaché à une entreprise
  /// (carnet.entreprise_id != null). À passer par l'écran appelant,
  /// qui dispose déjà de la liste complète des carnets (sélecteur).
  final bool estRattache;

  const LogbookScreen({
    super.key,
    required this.carnetId,
    this.estRattache = false,
  });

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _api = ApiService();

  late bool _estRattache;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _estRattache = widget.estRattache;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // Menu d'actions (bottom sheet) : créer un carnet / rattacher
  // ============================================================
  void _ouvrirMenuActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Que voulez-vous faire ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              if (!_estRattache) ...[
                _ActionTile(
                  icon: Icons.link_rounded,
                  iconColor: ColorConstants.primary,
                  title: 'Rattacher ce carnet',
                  subtitle: "Saisir le code d'invitation de votre tuteur",
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _ouvrirRattachementBottomSheet();
                  },
                ),
                const SizedBox(height: 12),
              ],
              _ActionTile(
                icon: Icons.note_add_outlined,
                iconColor: ColorConstants.success,
                title: 'Créer un nouveau carnet',
                subtitle: 'Démarrer un carnet de stage indépendant',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _creerCarnet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // Créer un nouveau carnet (indépendant de celui affiché ici)
  // ============================================================
  Future<void> _creerCarnet() async {
    final cree = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CarnetCreationPage()),
    );
    if (cree == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nouveau carnet créé. Retrouvez-le dans le sélecteur de carnets.'),
          backgroundColor: ColorConstants.success,
        ),
      );
    }
  }

  // ============================================================
  // Rattachement via bottom sheet (saisie + validation du code)
  // ============================================================
  void _ouvrirRattachementBottomSheet() {
    final codeCtrl = TextEditingController();
    bool enCours = false;
    String? erreur;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> valider() async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) {
                setSheetState(() => erreur = 'Merci de saisir le code.');
                return;
              }
              setSheetState(() {
                enCours = true;
                erreur = null;
              });
              try {
                await _api.rattacherCarnet(code, carnetId: widget.carnetId);
                if (!mounted) return;
                Navigator.of(sheetContext).pop();
                setState(() => _estRattache = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Carnet rattaché avec succès.'),
                    backgroundColor: ColorConstants.success,
                  ),
                );
              } catch (e) {
                final message = e is ApiException
                    ? e.userFriendlyMessage
                    : 'Erreur lors du rattachement.';
                setSheetState(() {
                  enCours = false;
                  erreur = message;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                ColorConstants.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.link_rounded,
                              color: ColorConstants.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Rattacher ce carnet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Saisissez le code d'invitation transmis par votre tuteur pour lier ce carnet à son entreprise.",
                      style: TextStyle(
                          fontSize: 12.5,
                          color: ColorConstants.textSecondary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: codeCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: ColorConstants.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'CODE',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          letterSpacing: 6,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
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
                          borderSide: const BorderSide(
                              color: ColorConstants.primary, width: 1.6),
                        ),
                      ),
                      onSubmitted: (_) => valider(),
                    ),
                    if (erreur != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        erreur!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: enCours ? null : valider,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: enCours
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Valider',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        title: const Text('Mon carnet de stage'),
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: ColorConstants.primary,
          unselectedLabelColor: ColorConstants.textSecondary,
          indicatorColor: ColorConstants.primary,
          labelStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'Progression'),
            Tab(text: 'Présence'),
            Tab(text: 'Encouragements'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _JournalTab(api: _api, carnetId: widget.carnetId),
          _ProgressionTab(api: _api, carnetId: widget.carnetId),
          _PresenceTab(api: _api, carnetId: widget.carnetId),
          _EncouragementsTab(api: _api, carnetId: widget.carnetId),
          _DocumentsTab(api: _api),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        onPressed: _ouvrirMenuActions,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// Item d'action dans le menu (bottom sheet)
// ============================================================
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ColorConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Helper générique de chargement (évite de dupliquer le pattern
// loading/erreur/vide dans chaque onglet)
// ============================================================
class _AsyncTabBody<T> extends StatefulWidget {
  final Future<List<T>> Function() loader;
  final Widget Function(BuildContext, List<T>) builder;
  final String emptyMessage;

  const _AsyncTabBody({
    required this.loader,
    required this.builder,
    required this.emptyMessage,
  });

  @override
  State<_AsyncTabBody<T>> createState() => _AsyncTabBodyState<T>();
}

class _AsyncTabBodyState<T> extends State<_AsyncTabBody<T>> {
  late Future<List<T>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  Future<void> _reload() async {
    setState(() => _future = widget.loader());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<T>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Une erreur est survenue.';
            return ListView(
              children: [
                const SizedBox(height: 80),
                Icon(Icons.wifi_off_rounded,
                    size: 36, color: ColorConstants.textSecondary),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                      onPressed: _reload, child: const Text('Réessayer')),
                ),
              ],
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Icon(Icons.inbox_outlined,
                    size: 36, color: ColorConstants.textSecondary),
                const SizedBox(height: 12),
                Text(
                  widget.emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: ColorConstants.textSecondary, fontSize: 13),
                ),
              ],
            );
          }

          return widget.builder(context, items);
        },
      ),
    );
  }
}

// ============================================================
// Onglet Journal — missions & difficultés (EntreeCarnet)
// ============================================================
class _JournalTab extends StatelessWidget {
  final ApiService api;
  final String carnetId;

  const _JournalTab({required this.api, required this.carnetId});

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody<Map<String, dynamic>>(
      loader: () async =>
          (await api.getEntreesJournal(carnetId)).cast<Map<String, dynamic>>(),
      emptyMessage: 'Aucune mission ni difficulté enregistrée pour le moment.',
      builder: (context, entrees) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entrees.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final e = entrees[i];
          final type = e['type'] as String? ?? '';
          final isDifficulte = type == 'DIFFICULTE';
          final commentaire = (e['commentaire_tuteur'] as String?) ??
              (e['commentaire_stagiaire'] as String?) ??
              '';
          final dateFin = e['date_fin'] as String?;
          final enCours = dateFin == null;

          return AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isDifficulte
                            ? ColorConstants.accentOrange
                            : ColorConstants.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDifficulte
                        ? Icons.error_outline
                        : Icons.assignment_turned_in_outlined,
                    color: isDifficulte
                        ? ColorConstants.accentOrange
                        : ColorConstants.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDifficulte ? 'Difficulté signalée' : 'Mission',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: ColorConstants.textPrimary),
                      ),
                      if (commentaire.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(commentaire,
                            style: const TextStyle(
                                fontSize: 12,
                                color: ColorConstants.textSecondary)),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        enCours ? 'En cours' : _formatDate(dateFin),
                        style: TextStyle(
                          fontSize: 11,
                          color: enCours
                              ? ColorConstants.success
                              : ColorConstants.textSecondary,
                          fontWeight:
                              enCours ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Onglet Progression — reprend les stats agrégées du dashboard
// ============================================================
class _ProgressionTab extends StatefulWidget {
  final ApiService api;
  final String carnetId;

  const _ProgressionTab({required this.api, required this.carnetId});

  @override
  State<_ProgressionTab> createState() => _ProgressionTabState();
}

class _ProgressionTabState extends State<_ProgressionTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getCarnetStats(widget.carnetId);
  }

  Future<void> _reload() async {
    setState(() => _future = widget.api.getCarnetStats(widget.carnetId));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                const Center(
                    child: Text('Impossible de charger la progression.')),
              ],
            );
          }

          final stats = snapshot.data ?? {};
          final progression =
              ((stats['progression_globale'] ?? 0) as int) / 100;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  children: [
                    ProgressRing(percent: progression),
                    const SizedBox(height: 8),
                    Text(
                        '${(stats['progression_globale'] ?? 0)}% de progression globale',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: ColorConstants.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _StatLine(
                icon: Icons.calendar_today_rounded,
                color: ColorConstants.primary,
                label: 'Jours de présence',
                value:
                    '${stats['jours_presents'] ?? 0} / ${stats['jours_attendus'] ?? 0}',
              ),
              const SizedBox(height: 10),
              _StatLine(
                icon: Icons.checklist_rounded,
                color: ColorConstants.success,
                label: 'Missions complétées',
                value:
                    '${stats['missions_completees'] ?? 0} / ${stats['missions_totales'] ?? 0}',
              ),
              const SizedBox(height: 10),
              _StatLine(
                icon: Icons.workspace_premium_outlined,
                color: const Color(0xFF7F77DD),
                label: 'Compétences maîtrisées',
                value: '${stats['competences_validees'] ?? 0}',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatLine(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: ColorConstants.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }
}

// ============================================================
// Onglet Présence — historique des pointages (arrivée/départ)
// ============================================================
class _PresenceTab extends StatelessWidget {
  final ApiService api;
  final String carnetId;

  const _PresenceTab({required this.api, required this.carnetId});

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody<Map<String, dynamic>>(
      loader: () async => (await api.getHistoriquePointage(carnetId))
          .cast<Map<String, dynamic>>(),
      emptyMessage: 'Aucun pointage enregistré pour le moment.',
      builder: (context, pointages) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pointages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = pointages[i];
          final debut = DateTime.tryParse(p['date_debut'] as String? ?? '');
          final finStr = p['date_fin'] as String?;
          final fin = finStr != null ? DateTime.tryParse(finStr) : null;
          final enCours = fin == null;

          String? duree;
          if (debut != null && fin != null) {
            final d = fin.difference(debut);
            duree =
                '${d.inHours}h${(d.inMinutes % 60).toString().padLeft(2, '0')}';
          }

          return AppCard(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (enCours
                            ? ColorConstants.success
                            : ColorConstants.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.access_time_filled_rounded,
                      color: enCours
                          ? ColorConstants.success
                          : ColorConstants.primary,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debut != null ? _formatDateLong(debut) : '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: ColorConstants.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        debut != null
                            ? '${_formatHeure(debut)}  →  ${enCours ? "en cours" : _formatHeure(fin)}'
                            : '—',
                        style: const TextStyle(
                            fontSize: 12, color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (duree != null)
                  Text(duree,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.textPrimary))
                else if (enCours)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConstants.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('En cours',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.success)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Onglet Encouragements — NotificationEncouragement
// ============================================================
class _EncouragementsTab extends StatelessWidget {
  final ApiService api;
  final String carnetId;

  const _EncouragementsTab({required this.api, required this.carnetId});

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody<Map<String, dynamic>>(
      loader: () async =>
          (await api.getEncouragements(carnetId)).cast<Map<String, dynamic>>(),
      emptyMessage:
          'Vous n\'avez pas encore reçu d\'encouragement de votre tuteur.',
      builder: (context, notifs) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = notifs[i];
          final isFelicitation = n['type'] == 'FELICITATION';
          final date = DateTime.tryParse(n['date_envoi'] as String? ?? '');

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5D98B)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isFelicitation ? Icons.star_rounded : Icons.favorite_rounded,
                  color: const Color(0xFFD9A441),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFelicitation
                            ? 'Félicitations de votre tuteur'
                            : 'Encouragement de votre tuteur',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF8A6416)),
                      ),
                      const SizedBox(height: 4),
                      Text(n['contenu'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: ColorConstants.textPrimary)),
                      if (date != null) ...[
                        const SizedBox(height: 6),
                        Text(_formatDateLong(date),
                            style: const TextStyle(
                                fontSize: 10.5,
                                color: ColorConstants.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Onglet Documents — attestations (Attestation)
// ============================================================
class _DocumentsTab extends StatelessWidget {
  final ApiService api;

  const _DocumentsTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return _AsyncTabBody<Map<String, dynamic>>(
      loader: () async =>
          (await api.getMesAttestations()).cast<Map<String, dynamic>>(),
      emptyMessage: 'Aucune attestation disponible pour le moment.',
      builder: (context, attestations) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: attestations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final a = attestations[i];
          final disponible = a['document_genere'] != null;
          final date = DateTime.tryParse(a['date_generation'] as String? ?? '');

          return AppCard(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined,
                      color: ColorConstants.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attestation de stage',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: ColorConstants.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        date != null
                            ? 'Générée le ${_formatDateLong(date)}'
                            : '—',
                        style: const TextStyle(
                            fontSize: 12, color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (disponible)
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        color: ColorConstants.primary),
                    onPressed: () {
                      // À brancher sur url_launcher :
                      // launchUrl(Uri.parse(api.urlTelechargementAttestation(a['id'])))
                    },
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          ColorConstants.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('En cours',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.accentOrange)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Helpers de formatage de date
// ============================================================
String _formatDate(String? iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _formatDateLong(DateTime d) {
  const mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${d.day} ${mois[d.month - 1]} ${d.year}';
}

String _formatHeure(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
