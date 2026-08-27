import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/carpool_service.dart';
import '../../widgets/common_widgets.dart';
import 'trajet_details_screen.dart';

/// Reproduit recherche-trajet.png : formulaire départ/destination/date/heure,
/// filtres rapides et résultats correspondants.
class RechercheTrajetScreen extends StatefulWidget {
  const RechercheTrajetScreen({super.key});

  @override
  State<RechercheTrajetScreen> createState() => _RechercheTrajetScreenState();
}

class _RechercheTrajetScreenState extends State<RechercheTrajetScreen> {
  final CarpoolService _apiService = CarpoolService();
  final TextEditingController _departCtrl = TextEditingController();
  final TextEditingController _arriveeCtrl = TextEditingController();

  int _filter = 0; // 0 = Aujourd'hui, 1 = Cette semaine, 2 = Tous / Personnalisé
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<dynamic> _allTrajets = [];
  List<dynamic> _filteredTrajets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrajets();
    _departCtrl.addListener(_applyFilters);
    _arriveeCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _departCtrl.dispose();
    _arriveeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTrajets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getTrajets();
      if (!mounted) return;
      setState(() {
        _allTrajets = data;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filter = 2; // Basculer sur le filtre personnalisé
      });
      _applyFilters();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final dep = _departCtrl.text.toLowerCase();
    final arr = _arriveeCtrl.text.toLowerCase();
    final now = DateTime.now();

    setState(() {
      _filteredTrajets = _allTrajets.where((t) {
        final tDep = (t['lieu_depart'] as String? ?? '').toLowerCase();
        final tArr = (t['lieu_arrivee'] as String? ?? '').toLowerCase();
        final tDateStr = t['date_depart'] as String?;
        final tDate = tDateStr != null ? DateTime.tryParse(tDateStr) : null;

        bool matchesText = tDep.contains(dep) && tArr.contains(arr);
        bool matchesFilter = true;

        if (tDate != null) {
          if (_filter == 0) {
            // Aujourd'hui
            matchesFilter = tDate.year == now.year &&
                tDate.month == now.month &&
                tDate.day == now.day;
          } else if (_filter == 1) {
            // Cette semaine (7 prochains jours)
            matchesFilter = tDate.isAfter(now.subtract(const Duration(days: 1))) &&
                tDate.isBefore(now.add(const Duration(days: 7)));
          } else if (_selectedDate != null) {
            // Date sélectionnée manuellement
            matchesFilter = tDate.year == _selectedDate!.year &&
                tDate.month == _selectedDate!.month &&
                tDate.day == _selectedDate!.day;
          }

          if (matchesFilter && _selectedTime != null) {
            // Filtrer par heure si sélectionnée
            matchesFilter = tDate.hour >= _selectedTime!.hour;
          }
        }

        return matchesText && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Rechercher un trajet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Départ'),
                _buildTextField(_departCtrl, Icons.location_on_outlined, 'Gare de Lyon, Paris'),
                const SizedBox(height: 14),
                const _FieldLabel('Destination'),
                _buildTextField(_arriveeCtrl, Icons.flag_outlined, 'Campus Ubisoft France', iconColor: ColorConstants.primary),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Date'),
                          _clickableField(
                            icon: Icons.calendar_today_outlined,
                            value: _selectedDate != null
                                ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                : 'Sélectionner date',
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Heure'),
                          _clickableField(
                            icon: Icons.access_time,
                            value: _selectedTime != null
                                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                : 'Toute heure',
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterChip(
                  label: "Aujourd'hui",
                  selected: _filter == 0,
                  onTap: () {
                    setState(() {
                      _filter = 0;
                      _selectedDate = null;
                    });
                    _applyFilters();
                  }),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Cette semaine',
                  selected: _filter == 1,
                  onTap: () {
                    setState(() {
                      _filter = 1;
                      _selectedDate = null;
                    });
                    _applyFilters();
                  }),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Tous / Dates',
                  selected: _filter == 2,
                  onTap: () {
                    setState(() => _filter = 2);
                    _applyFilters();
                  }),
            ],
          ),
          const SizedBox(height: 20),
          Text('Résultats correspondants (${_filteredTrajets.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredTrajets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Aucun trajet ne correspond à votre recherche.'),
              ),
            )
          else
            ..._filteredTrajets.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ResultCard(
                    trajet: t,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrajetDetailsScreen(trajet: t),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, IconData icon, String hint, {Color? iconColor}) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: iconColor ?? ColorConstants.textSecondary),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13.5, color: ColorConstants.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _clickableField({required IconData icon, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: ColorConstants.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ColorConstants.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 13.5, color: ColorConstants.textPrimary, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primary : ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? ColorConstants.primary : ColorConstants.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ColorConstants.textSecondary)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> trajet;
  final VoidCallback onTap;

  const _ResultCard({required this.trajet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chauffeur = trajet['chauffeur'] as Map<String, dynamic>?;
    final name = chauffeur?['nom'] as String? ?? 'Conducteur';
    final avatarUrl = chauffeur?['photo_profil_url'] as String? ??
        chauffeur?['photo_profil'] as String?;

    final dateDepartStr = trajet['date_depart'] as String?;
    DateTime? dateDepart;
    if (dateDepartStr != null) {
      dateDepart = DateTime.tryParse(dateDepartStr);
    }
    final departHeure =
        dateDepart != null ? DateFormat('HH:mm').format(dateDepart) : '--:--';

    final places = trajet['places_disponibles']?.toString() ?? '0';
    final priceVal = (trajet['tarif'] as dynamic)?.toDouble() ?? 0.0;
    final price = priceVal == 0 ? 'Gratuit' : '${priceVal.toStringAsFixed(2)} €';
    final isFree = priceVal == 0;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                Text('Départ à $departHeure',
                    style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
                const SizedBox(height: 2),
                Text('$places places restantes',
                    style: const TextStyle(fontSize: 11.5, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isFree ? ColorConstants.success : ColorConstants.primary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Détails', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
