import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/medication_serializer.dart';
import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import '../models/measure.dart';
import 'medications_section_widget.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class ATab extends StatefulWidget {
  const ATab({super.key});

  @override
  State<ATab> createState() => _ATabState();
}

class _ATabState extends State<ATab> {
  bool _airwayPatent = true;
  bool _airwayThreatened = false;
  final _airwayIssueController = TextEditingController();
  final List<Map<String, dynamic>> _airwayMedications = []; // [{name, dose}]
  
  // Maßnahmen Flags
  bool _mHeadTilt = false;
  bool _mChinLift = false;
  bool _mEsmarch = false;
  bool _mGuedel = false;
  bool _mWendl = false;
  bool _mSuction = false;
  
  // Guedel-Größen (vereinfachte gängige Größen)
  final List<String> _guedelSizes = ['0', '1', '2', '3', '4', '5'];
  String? _selectedGuedelSize;
  
  // Wendl-Größen (typische mm-Angaben)
  final List<String> _wendlSizes = ['28', '30','32'];
  String? _selectedWendlSize;
  
  @override
  void initState() {
    super.initState();
    final provider = context.read<MissionProvider>();
    final abcde = provider.latestABCDE;
    if (abcde != null) {
      _airwayPatent = abcde.airwayPatent;
      _airwayThreatened = abcde.airwayThreatened;
      _airwayIssueController.text = abcde.airwayIssue ?? '';
      
      // Parse airwayMedications zurück in Liste (JSON oder altes Format)
      _airwayMedications.addAll(
        MedicationSerializer.deserialize(abcde.airwayMedications),
      );
      
      // einfache Rückwärtszuordnung aus airwayIntervention
      final ai = abcde.airwayIntervention ?? '';
      _mHeadTilt = ai.contains('Kopf überstrecken');
      _mChinLift = ai.contains('Chin-Lift');
      _mEsmarch = ai.contains('Esmarch');
      _mGuedel = ai.contains('Guedel');
      _mWendl = ai.contains('Wendl');
      _mSuction = ai.contains('Absaugen');
      for (final s in _guedelSizes) {
        if (ai.contains('Guedel $s')) _selectedGuedelSize = s;
      }
      for (final s in _wendlSizes) {
        if (ai.contains('Wendl $s')) _selectedWendlSize = s;
      }
    }

    // Sync von Measures → Checkboxen
    final measures = provider.currentMeasures;
    if (measures.any((m) => m.measureType == MeasureType.guedeltubus)) {
      _mGuedel = true;
      if (_selectedGuedelSize == null) {
        final g = measures.where((m) => m.measureType == MeasureType.guedeltubus).last;
        final match = RegExp(r'Größe:\s*(\S+)').firstMatch(g.notes ?? '');
        if (match != null) _selectedGuedelSize = match.group(1);
      }
    }
    if (measures.any((m) => m.measureType == MeasureType.wendltubus)) {
      _mWendl = true;
      if (_selectedWendlSize == null) {
        final w = measures.where((m) => m.measureType == MeasureType.wendltubus).last;
        final match = RegExp(r'Größe:\s*(\S+)').firstMatch(w.notes ?? '');
        if (match != null) _selectedWendlSize = match.group(1);
      }
    }
    if (measures.any((m) => m.measureType == MeasureType.absaugen)) {
      _mSuction = true;
    }
  }
  
  @override
  void dispose() {
    _airwayIssueController.dispose();
    for (final med in _airwayMedications) {
      if (med['controller'] != null) {
        (med['controller'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }
  
  String _buildInterventionText() {
    final parts = <String>[];
    if (_mHeadTilt) parts.add('Kopf überstrecken');
    if (_mChinLift) parts.add('Chin-Lift');
    if (_mEsmarch) parts.add('Esmarch');
    if (_mGuedel) {
      if (_selectedGuedelSize != null) {
        parts.add('Guedel $_selectedGuedelSize');
      } else {
        parts.add('Guedeltubus');
      }
    }
    if (_mWendl) {
      if (_selectedWendlSize != null) {
        parts.add('Wendl $_selectedWendlSize');
      } else {
        parts.add('Wendltubus');
      }
    }
    if (_mSuction) parts.add('Absaugen');
    if (parts.isEmpty) return '';
    return parts.join(', ');
  }

  String _buildMedicationsText() {
    return MedicationSerializer.serialize(_airwayMedications);
  }
  
  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;

    final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);

    final intervention = _buildInterventionText();
    final medications = _buildMedicationsText();

    final updated = current.copyWith(
      airwayPatent: _airwayPatent,
      airwayThreatened: _airwayThreatened,
      airwayIssue: _airwayIssueController.text.isEmpty
          ? null
          : _airwayIssueController.text,
      airwayIntervention: intervention.isEmpty ? null : intervention,
      airwayMedications: medications.isEmpty ? null : medications,
      aDocumented: true, // << wichtig
    );

    try {
      await provider.addOrUpdateABCDE(updated);

      // Sync Maßnahmen → Measures-Tab
      if (_mGuedel) {
        final notes = _selectedGuedelSize != null ? 'Größe: $_selectedGuedelSize' : null;
        await provider.ensureMeasureExists(MeasureType.guedeltubus, notes: notes);
      }
      if (_mWendl) {
        final notes = _selectedWendlSize != null ? 'Größe: $_selectedWendlSize' : null;
        await provider.ensureMeasureExists(MeasureType.wendltubus, notes: notes);
      }
      if (_mSuction) {
        await provider.ensureMeasureExists(MeasureType.absaugen);
      }

      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('A - Airway gespeichert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Fehler beim Speichern von A-Assessment: $e');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    final showMeasures = _airwayThreatened;
    
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
                  'A - Airway',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Atemwegskontrolle und -sicherung.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  value: _airwayPatent,
                  onChanged: (value) {
                    setState(() {
                      _airwayPatent = value;
                      if (value) _airwayThreatened = false;
                    });
                  },
                  title: const Text('Atemweg frei'),
                  secondary: Icon(
                    Icons.done,
                    color: _airwayPatent ? AppColors.success : Colors.grey,
                  ),
                ),
                
                SwitchListTile(
                  value: _airwayThreatened,
                  onChanged: (value) {
                    setState(() {
                      _airwayThreatened = value;
                      if (value) _airwayPatent = false;
                    });
                  },
                  title: const Text('Atemweg bedroht'),
                  secondary: Icon(
                    Icons.warning_amber,
                    color: _airwayThreatened ? AppColors.warning : Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _airwayIssueController,
                  decoration: const InputDecoration(
                    labelText: 'Atemwegsproblem',
                    hintText: 'z.B. Aspiration, Fremdkörper, Stridor',
                    prefixIcon: Icon(Icons.sick),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),                
                // Medikamente Sektion mit Widget
                MedicationsSectionWidget(
                  title: 'Medikamente bei A',
                  bgColor: Colors.blue.shade50,
                  medications: _airwayMedications,
                  onMedicationsChanged: () {
                    // Widget wird automatisch neu gerendert
                  },
                ),
                
                const SizedBox(height: 16),                
                if (showMeasures) _buildMeasuresCard(context),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('A speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMeasuresCard(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maßnahmen bei bedrohtem Atemweg',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            CheckboxListTile(
              value: _mHeadTilt,
              onChanged: (v) => setState(() => _mHeadTilt = v ?? false),
              title: const Text('Kopf überstrecken'),
              dense: true,
            ),
            CheckboxListTile(
              value: _mChinLift,
              onChanged: (v) => setState(() => _mChinLift = v ?? false),
              title: const Text('Chin-Lift'),
              dense: true,
            ),
            CheckboxListTile(
              value: _mEsmarch,
              onChanged: (v) => setState(() => _mEsmarch = v ?? false),
              title: const Text('Esmarch-Handgriff'),
              dense: true,
            ),
            CheckboxListTile(
              value: _mSuction,
              onChanged: (v) => setState(() => _mSuction = v ?? false),
              title: const Text('Absaugen'),
              dense: true,
            ),
            
            const Divider(height: 24),
            
            CheckboxListTile(
              value: _mGuedel,
              onChanged: (v) => setState(() => _mGuedel = v ?? false),
              title: const Text('Guedeltubus'),
              dense: true,
            ),
            if (_mGuedel) Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Wrap(
                spacing: 8,
                children: _guedelSizes.map((s) {
                  final selected = _selectedGuedelSize == s;
                  return ChoiceChip(
                    label: Text('Größe $s'),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedGuedelSize = s;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            
            CheckboxListTile(
              value: _mWendl,
              onChanged: (v) => setState(() => _mWendl = v ?? false),
              title: const Text('Wendltubus'),
              dense: true,
            ),
            if (_mWendl) Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Wrap(
                spacing: 8,
                children: _wendlSizes.map((s) {
                  final selected = _selectedWendlSize == s;
                  return ChoiceChip(
                    label: Text('$s'),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedWendlSize = s;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
