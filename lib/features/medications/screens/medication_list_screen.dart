import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rescue_doc/core/services/database_service.dart';
import 'package:rescue_doc/features/medications/models/medication.dart';
import 'package:rescue_doc/features/medications/providers/medication_provider.dart';
import 'package:rescue_doc/features/medications/widgets/medication_edit_page.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _loadMedications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);

    try {
      final meds = await DatabaseService.instance.getAllMedications();
      meds.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      setState(() {
        _medications = meds;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Fehler beim Laden der Medikamente: $e');
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMedications = query.isEmpty
          ? _medications
          : _medications.where((med) {
              return med.name.toLowerCase().contains(query) ||
                  med.activeIngredient.toLowerCase().contains(query) ||
                  (med.category?.toLowerCase().contains(query) ?? false);
            }).toList();
    });
  }

  Future<void> _openNewMedication() async {
    final result = await Navigator.of(context).push<Medication>(
      MaterialPageRoute(
        builder: (_) => const MedicationEditPage(),
      ),
    );
    if (result != null) {
      await _loadMedications();
      _syncProvider();
    }
  }

  Future<void> _editMedication(Medication med) async {
    final result = await Navigator.of(context).push<Medication>(
      MaterialPageRoute(
        builder: (_) => MedicationEditPage(initial: med),
      ),
    );
    if (result != null) {
      await _loadMedications();
      _syncProvider();
    }
  }

  void _syncProvider() {
    // Provider im nächsten Frame synchronisieren, damit cABCDE-Tabs die Medikamente sehen
    // PostFrameCallback verhindert notifyListeners während eines Builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MedicationProvider>().loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medikamente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openNewMedication,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Medikament suchen…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _searchController.clear,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadMedications,
                    child: _filteredMedications.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _medications.isEmpty
                                      ? 'Noch keine Medikamente angelegt'
                                      : 'Keine Treffer für die Suche',
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredMedications.length,
                            itemBuilder: (context, index) {
                              final med = _filteredMedications[index];
                              return ListTile(
                                title: Text(med.name),
                                subtitle: Text(
                                  [
                                    med.activeIngredient,
                                    med.category,
                                  ]
                                      .where((e) => e != null && e.isNotEmpty)
                                      .join(' • '),
                                ),
                                onTap: () => _editMedication(med),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
