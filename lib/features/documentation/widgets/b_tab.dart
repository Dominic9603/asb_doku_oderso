import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/medication_serializer.dart';
import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import '../models/measure.dart';
import 'medications_section_widget.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class BTab extends StatefulWidget {
  const BTab({super.key});

  @override
  State<BTab> createState() => _BTabState();
}

class _BTabState extends State<BTab> {
  final _respRateController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _breathingSoundsController = TextEditingController();
  bool _symmetricBreathing = true;
  final _breathingIssueController = TextEditingController();

  // O2
  bool _o2Given = false;
  final _o2LitersController = TextEditingController();
  String? _o2MaskType; // 'ohne' | 'mit'

  // Medikamente für Breathing (neues System)
  final List<Map<String, dynamic>> _breathingMedications = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<MissionProvider>();
    final abcde = provider.latestABCDE;
    if (abcde != null) {
      if (abcde.respiratoryRate != null) {
        _respRateController.text = abcde.respiratoryRate.toString();
      }
      if (abcde.spo2 != null) {
        _spo2Controller.text = abcde.spo2!.toStringAsFixed(1);
      }
      _breathingSoundsController.text = abcde.breathingSounds ?? '';
      _symmetricBreathing = abcde.symmetricBreathing;
      _breathingIssueController.text = abcde.breathingIssue ?? '';

      final bi = abcde.breathingIntervention ?? '';

      // O2 rückwärts
      if (bi.contains('O2')) _o2Given = true;
      final maskOhne = bi.contains('Maske ohne Reservoir');
      final maskMit = bi.contains('Maske mit Reservoir');
      if (maskOhne) _o2MaskType = 'ohne';
      if (maskMit) _o2MaskType = 'mit';
      final litMatch = RegExp(r'O2\s+(\d+(?:\.\d+)?)\s*L/min').firstMatch(bi);
      if (litMatch != null) _o2LitersController.text = litMatch.group(1) ?? '';

      // Parse breathingMedications zurück in Liste (JSON oder altes Format)
      _breathingMedications.addAll(
        MedicationSerializer.deserialize(abcde.breathingMedications),
      );
    }

    // Sync von Measures → O2-Checkbox
    if (provider.currentMeasures.any((m) => m.measureType == MeasureType.oxygenTherapy)) {
      _o2Given = true;
    }
  }

  @override
  void dispose() {
    _respRateController.dispose();
    _spo2Controller.dispose();
    _breathingSoundsController.dispose();
    _breathingIssueController.dispose();
    _o2LitersController.dispose();
    super.dispose();
  }

  String _buildInterventionText() {
    final parts = <String>[];

    if (_o2Given) {
      String o2 = 'O2';
      if (_o2LitersController.text.isNotEmpty) {
        o2 += ' ${_o2LitersController.text} L/min';
      }
      if (_o2MaskType == 'ohne') {
        o2 += ' (Maske ohne Reservoir)';
      } else if (_o2MaskType == 'mit') {
        o2 += ' (Maske mit Reservoir)';
      }
      parts.add(o2);
    }

    return parts.join(' | ');
  }

  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;

    final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);

    final intervention = _buildInterventionText();
    
    // Neue Medikamente für Breathing speichern
    final medicationsText = MedicationSerializer.serialize(_breathingMedications);

    final updated = current.copyWith(
      respiratoryRate: _respRateController.text.isEmpty
          ? null
          : int.parse(_respRateController.text),
      spo2: _spo2Controller.text.isEmpty
          ? null
          : double.parse(_spo2Controller.text),
      breathingSounds: _breathingSoundsController.text.isEmpty
          ? null
          : _breathingSoundsController.text,
      symmetricBreathing: _symmetricBreathing,
      breathingIssue: _breathingIssueController.text.isEmpty
          ? null
          : _breathingIssueController.text,
      breathingIntervention: intervention.isEmpty ? null : intervention,
      breathingMedications: medicationsText.isEmpty ? null : medicationsText,
    );

    await provider.addOrUpdateABCDE(updated);

    // Sync O2-Maßnahme → Measures-Tab
    if (_o2Given) {
      String? notes;
      final noteParts = <String>[];
      if (_o2MaskType == 'ohne') noteParts.add('Applikation: Maske');
      if (_o2MaskType == 'mit') noteParts.add('Applikation: Reservoirmaske');
      if (_o2LitersController.text.isNotEmpty) noteParts.add('Fluss (l/min): ${_o2LitersController.text}');
      if (noteParts.isNotEmpty) notes = noteParts.join(', ');
      await provider.ensureMeasureExists(MeasureType.oxygenTherapy, notes: notes);
    }

    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('B - Breathing gespeichert'),
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
                  'B - Breathing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Atmung, Oxygenierung und Maßnahmen.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _respRateController,
                        decoration: const InputDecoration(
                          labelText: 'Atemfrequenz',
                          suffixText: '/min',
                          prefixIcon: Icon(Icons.wind_power),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _spo2Controller,
                        decoration: const InputDecoration(
                          labelText: 'SpO₂',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.air),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _breathingSoundsController,
                  decoration: const InputDecoration(
                    labelText: 'Auskultation',
                    hintText: 'z.B. vesikulär, Giemen, Rasseln',
                    prefixIcon: Icon(Icons.hearing),
                  ),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  value: _symmetricBreathing,
                  onChanged: (value) {
                    setState(() => _symmetricBreathing = value);
                  },
                  title: const Text('Symmetrische Thoraxexkursion'),
                  secondary: Icon(
                    Icons.sync_alt,
                    color:
                        _symmetricBreathing ? AppColors.success : AppColors.warning,
                  ),
                ),

                const SizedBox(height: 16),

                _buildO2Card(context),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _breathingIssueController,
                  decoration: const InputDecoration(
                    labelText: 'Problem B',
                    hintText: 'z.B. Asthma-Anfall, Pneumothorax',
                    prefixIcon: Icon(Icons.sick),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Medikamente für Breathing
                MedicationsSectionWidget(
                  title: 'Medikamente bei B',
                  bgColor: Colors.green.shade50,
                  medications: _breathingMedications,
                  onMedicationsChanged: () {
                    // Widget wird automatisch neu gerendert
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('B speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildO2Card(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: _o2Given,
              onChanged: (v) {
                setState(() => _o2Given = v ?? false);
              },
              title: const Text('O₂-Gabe'),
              dense: true,
            ),
            if (_o2Given) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _o2LitersController,
                      decoration: const InputDecoration(
                        labelText: 'Flow',
                        suffixText: 'L/min',
                        prefixIcon: Icon(Icons.local_fire_department),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Maske ohne Reservoir'),
                    selected: _o2MaskType == 'ohne',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _o2MaskType == 'ohne' ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _o2MaskType = 'ohne';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Maske mit Reservoir'),
                    selected: _o2MaskType == 'mit',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _o2MaskType == 'mit' ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _o2MaskType = 'mit';
                      });
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}
