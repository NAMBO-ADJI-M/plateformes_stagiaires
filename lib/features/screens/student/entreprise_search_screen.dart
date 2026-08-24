import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class EntrepriseSearchScreen extends StatefulWidget {
  const EntrepriseSearchScreen({super.key});

  @override
  State<EntrepriseSearchScreen> createState() => _EntrepriseSearchScreenState();
}

class _EntrepriseSearchScreenState extends State<EntrepriseSearchScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.length >= 2) {
        _performSearch(query);
      } else {
        setState(() {
          _results = [];
          _error = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _api.rechercherEntreprises(query);
      setState(() {
        _results = results;
        if (_results.isEmpty) {
          _error = "Cette entreprise n'est pas encore inscrite sur la plateforme. Demandez à votre tuteur de créer un compte entreprise avant de continuer.";
        }
      });
    } catch (e) {
      setState(() => _error = "Erreur de recherche. Veuillez réessayer.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectEntreprise(dynamic ent) async {
    setState(() => _isSending = true);
    try {
      await _api.demanderRattachement(ent['id']);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Rechercher votre entreprise', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Où effectuez-vous votre stage ?",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: ColorConstants.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                "Saisissez le nom de l'entreprise pour envoyer une demande de rattachement.",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Nom de l'entreprise...",
                  prefixIcon: const Icon(Icons.search, color: ColorConstants.primary),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.orange))),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) {
                      final ent = _results[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.grey[50],
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(ent['raison_sociale'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(ent['adresse_libelle'] ?? ent['secteur'] ?? 'Secteur non précisé'),
                          trailing: _isSending 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right, color: ColorConstants.primary),
                          onTap: _isSending ? null : () => _selectEntreprise(ent),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
