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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);

    try {
      final meds = await DatabaseService.instance.getAllMedications();

      setState(() {
        _medications = meds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Fehler beim Laden der Medikamente: $e');
    }
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
          : RefreshIndicator(
              onRefresh: _loadMedications,
              child: _medications.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Noch keine Medikamente angelegt')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _medications.length,
                      itemBuilder: (context, index) {
                        final med = _medications[index];
                        return ListTile(
                          title: Text(med.name),
                          subtitle: Text(
                            [
                              med.activeIngredient,
                              med.category,
                            ].where((e) => e != null && e.isNotEmpty).join(' • '),
                          ),
                          onTap: () => _editMedication(med),
                        );
                      },
                    ),
            ),
    );
  }
}
