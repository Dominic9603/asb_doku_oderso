import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/medication_serializer.dart';
import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import '../../../core/utils/scaffold_messenger_key.dart';
import 'medications_section_widget.dart';

class ETab extends StatefulWidget {
  const ETab({super.key});

  @override
  State<ETab> createState() => _ETabState();
}

class _ETabState extends State<ETab> {
  final _temperatureController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _envFactorsController = TextEditingController();
  final _exposureIssueController = TextEditingController();
  final _exposureInterventionController = TextEditingController();
  
  // Medikamente für Exposure (neues System)
  final List<Map<String, dynamic>> _exposureMedications = [];
  
  @override
  void initState() {
    super.initState();
    final abcde = context.read<MissionProvider>().latestABCDE;
    if (abcde != null) {
      if (abcde.temperature != null) {
        _temperatureController.text = abcde.temperature!.toStringAsFixed(1);
      }
      _injuriesController.text = abcde.injuries ?? '';
      _envFactorsController.text = abcde.environmentalFactors ?? '';
      _exposureIssueController.text = abcde.exposureIssue ?? '';
      _exposureInterventionController.text = abcde.exposureIntervention ?? '';

      // Parse exposureMedications zurück in Liste (JSON oder altes Format)
      _exposureMedications.addAll(
        MedicationSerializer.deserialize(abcde.exposureMedications),
      );
    }
  }
  
  @override
  void dispose() {
    _temperatureController.dispose();
    _injuriesController.dispose();
    _envFactorsController.dispose();
    _exposureIssueController.dispose();
    _exposureInterventionController.dispose();
    super.dispose();
  }
  
  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;
    
    final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);
    
    final updated = current.copyWith(
      temperature: _temperatureController.text.isEmpty
          ? null
          : double.parse(_temperatureController.text),
      injuries: _injuriesController.text.isEmpty
          ? null
          : _injuriesController.text,
      environmentalFactors: _envFactorsController.text.isEmpty
          ? null
          : _envFactorsController.text,
      exposureIssue: _exposureIssueController.text.isEmpty
          ? null
          : _exposureIssueController.text,
      exposureIntervention: _exposureInterventionController.text.isEmpty
          ? null
          : _exposureInterventionController.text,
      exposureMedications: _exposureMedications.isEmpty
          ? null
          : MedicationSerializer.serialize(_exposureMedications),
    );
    
    await provider.addOrUpdateABCDE(updated);
    
    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('E - Exposure gespeichert'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E - Exposure/Environment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Körpertemperatur, Verletzungen, Umgebung.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _temperatureController,
                  decoration: const InputDecoration(
                    labelText: 'Temperatur',
                    suffixText: '°C',
                    prefixIcon: Icon(Icons.thermostat),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _injuriesController,
                  decoration: const InputDecoration(
                    labelText: 'Verletzungen',
                    hintText: 'z.B. Frakturen, Wunden',
                    prefixIcon: Icon(Icons.health_and_safety),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _envFactorsController,
                  decoration: const InputDecoration(
                    labelText: 'Umgebungsfaktoren',
                    hintText: 'z.B. Kälte, Hitze, Wasser',
                    prefixIcon: Icon(Icons.terrain),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _exposureIssueController,
                  decoration: const InputDecoration(
                    labelText: 'Problem E',
                    prefixIcon: Icon(Icons.sick),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _exposureInterventionController,
                  decoration: const InputDecoration(
                    labelText: 'Maßnahmen E',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                
                // Medikamente für Exposure
                MedicationsSectionWidget(
                  title: 'Medikamente bei E',
                  bgColor: Colors.red.shade50,
                  medications: _exposureMedications,
                  onMedicationsChanged: () {
                    // Widget wird automatisch neu gerendert
                  },
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('E speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
