import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/medication_serializer.dart';
import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import 'medications_section_widget.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class DTab extends StatefulWidget {
  const DTab({super.key});

  @override
  State<DTab> createState() => _DTabState();
}

class _DTabState extends State<DTab> {
  int? _gcsEye;
  int? _gcsVerbal;
  int? _gcsMotor;
  final _bloodSugarController = TextEditingController();
  final _disabilityIssueController = TextEditingController();
  final _disabilityInterventionController = TextEditingController();

  // Pupillen
  String? _pupilState; // 'isochor' oder 'anisochor'
  String? _lightReaction; // 'normal' oder 'erloschen'
  String? _pupilSize; // 'weit', 'mittel', 'eng'

  // BEFAST
  String? _befastResult; // 'auffällig' oder 'unauffällig'

  // Bei anisochor: optional getrennte Beschreibung
  final _pupilLeftDetailController = TextEditingController();
  final _pupilRightDetailController = TextEditingController();
  
  // Medikamente für Disability (neues System)
  final List<Map<String, dynamic>> _disabilityMedications = [];

  @override
  void initState() {
    super.initState();
    final abcde = context.read<MissionProvider>().latestABCDE;
    if (abcde != null) {
      _gcsEye = abcde.gcsEye;
      _gcsVerbal = abcde.gcsVerbal;
      _gcsMotor = abcde.gcsMotor;

      if (abcde.bloodSugar != null) {
        _bloodSugarController.text = abcde.bloodSugar!.toStringAsFixed(0);
      }
      _disabilityIssueController.text = abcde.disabilityIssue ?? '';
      _disabilityInterventionController.text = abcde.disabilityIntervention ?? '';

      // BEFAST
      _befastResult = abcde.befastResult;

      // Pupillen aus Text rekonstruieren (so gut wie möglich)
      final left = abcde.pupilLeft ?? '';
      final right = abcde.pupilRight ?? '';
      final both = '$left | $right';

      if (both.contains('isochor')) _pupilState = 'isochor';
      if (both.contains('anisochor')) _pupilState = 'anisochor';
      if (both.contains('normal')) _lightReaction = 'normal';
      if (both.contains('erloschen')) _lightReaction = 'erloschen';
      if (both.contains('weit')) _pupilSize = 'weit';
      if (both.contains('mittel')) _pupilSize = 'mittel';
      if (both.contains('eng')) _pupilSize = 'eng';

      // bei Anisokorie Details wieder einsetzen
      _pupilLeftDetailController.text = left;
      _pupilRightDetailController.text = right;

      // Parse disabilityMedications zurück in Liste (JSON oder altes Format)
      _disabilityMedications.addAll(
        MedicationSerializer.deserialize(abcde.disabilityMedications),
      );
    }
  }

  @override
  void dispose() {
    _bloodSugarController.dispose();
    _disabilityIssueController.dispose();
    _disabilityInterventionController.dispose();
    _pupilLeftDetailController.dispose();
    _pupilRightDetailController.dispose();
    super.dispose();
  }

  int? get _gcsTotal {
    if (_gcsEye == null || _gcsVerbal == null || _gcsMotor == null) return null;
    return _gcsEye! + _gcsVerbal! + _gcsMotor!;
  }

  Widget _buildGCSSelector({
    required String title,
    required List<int> values,
    required int? selected,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: values.map((v) {
            final isSelected = selected == v;
            return ChoiceChip(
              label: Text(v.toString()),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
              onSelected: (_) => onChanged(v),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _buildPupilTextIsochor() {
    final parts = <String>[];
    parts.add('isochor');
    if (_lightReaction != null) parts.add('Lichtreaktion: $_lightReaction');
    if (_pupilSize != null) parts.add('Größe: $_pupilSize');
    return parts.join(', ');
  }

  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;

    final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);

    // Pupillen-Text zusammenbauen
    String? pupilLeft;
    String? pupilRight;

    if (_pupilState == 'isochor') {
      final text = _buildPupilTextIsochor();
      pupilLeft = text;
      pupilRight = text;
    } else if (_pupilState == 'anisochor') {
      // Bei Anisokorie erlauben wir freie Beschreibung in den Detailfeldern
      pupilLeft = _pupilLeftDetailController.text.isEmpty
          ? 'anisochor (links)'
          : _pupilLeftDetailController.text;
      pupilRight = _pupilRightDetailController.text.isEmpty
          ? 'anisochor (rechts)'
          : _pupilRightDetailController.text;
    }

    final updated = current.copyWith(
      gcsEye: _gcsEye,
      gcsVerbal: _gcsVerbal,
      gcsMotor: _gcsMotor,
      pupilLeft: pupilLeft,
      pupilRight: pupilRight,
      bloodSugar: _bloodSugarController.text.isEmpty
          ? null
          : double.tryParse(_bloodSugarController.text),
      befastResult: _befastResult,
      disabilityIssue: _disabilityIssueController.text.isEmpty
          ? null
          : _disabilityIssueController.text,
      disabilityIntervention: _disabilityInterventionController.text.isEmpty
          ? null
          : _disabilityInterventionController.text,
      disabilityMedications: _disabilityMedications.isEmpty
          ? null
          : MedicationSerializer.serialize(_disabilityMedications),
    );

    await provider.addOrUpdateABCDE(updated);

    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('D - Disability gespeichert'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gcsTotal = _gcsTotal;

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
                  'D - Disability (Neurologie)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bewusstsein, Pupillen, Blutzucker.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // GCS
                _buildGCSSelector(
                  title: 'GCS - Augenöffnen (E)',
                  values: const [1, 2, 3, 4],
                  selected: _gcsEye,
                  onChanged: (v) => setState(() => _gcsEye = v),
                ),
                const SizedBox(height: 12),
                _buildGCSSelector(
                  title: 'GCS - Verbale Antwort (V)',
                  values: const [1, 2, 3, 4, 5],
                  selected: _gcsVerbal,
                  onChanged: (v) => setState(() => _gcsVerbal = v),
                ),
                const SizedBox(height: 12),
                _buildGCSSelector(
                  title: 'GCS - Motorische Antwort (M)',
                  values: const [1, 2, 3, 4, 5, 6],
                  selected: _gcsMotor,
                  onChanged: (v) => setState(() => _gcsMotor = v),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Text('Gesamt-GCS:'),
                    const SizedBox(width: 8),
                    Text(
                      gcsTotal?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pupillen
                const Text(
                  'Pupillen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('isochor'),
                      selected: _pupilState == 'isochor',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _pupilState == 'isochor' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _pupilState = 'isochor';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('anisochor'),
                      selected: _pupilState == 'anisochor',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _pupilState == 'anisochor' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _pupilState = 'anisochor';
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (_pupilState == 'isochor') ...[
                  const Text(
                    'Lichtreaktion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('normal'),
                        selected: _lightReaction == 'normal',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _lightReaction == 'normal' ? Colors.white : null,
                        ),
                        onSelected: (_) {
                          setState(() => _lightReaction = 'normal');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('erloschen'),
                        selected: _lightReaction == 'erloschen',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _lightReaction == 'erloschen' ? Colors.white : null,
                        ),
                        onSelected: (_) {
                          setState(() => _lightReaction = 'erloschen');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Größe',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('weit'),
                        selected: _pupilSize == 'weit',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _pupilSize == 'weit' ? Colors.white : null,
                        ),
                        onSelected: (_) {
                          setState(() => _pupilSize = 'weit');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('mittel'),
                        selected: _pupilSize == 'mittel',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _pupilSize == 'mittel' ? Colors.white : null,
                        ),
                        onSelected: (_) {
                          setState(() => _pupilSize = 'mittel');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('eng'),
                        selected: _pupilSize == 'eng',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _pupilSize == 'eng' ? Colors.white : null,
                        ),
                        onSelected: (_) {
                          setState(() => _pupilSize = 'eng');
                        },
                      ),
                    ],
                  ),
                ],

                if (_pupilState == 'anisochor') ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Details bei Anisokorie',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pupilLeftDetailController,
                          decoration: const InputDecoration(
                            labelText: 'Pupille links',
                            hintText: 'z.B. weit, keine Reaktion',
                            prefixIcon: Icon(Icons.visibility),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _pupilRightDetailController,
                          decoration: const InputDecoration(
                            labelText: 'Pupille rechts',
                            hintText: 'z.B. mittel, normal reagibel',
                            prefixIcon: Icon(Icons.visibility_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // BEFAST (Schlaganfall-Screening)
                const Text(
                  'BEFAST (Schlaganfall)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('unauffällig'),
                      selected: _befastResult == 'unauffällig',
                      selectedColor: AppColors.success,
                      labelStyle: TextStyle(
                        color: _befastResult == 'unauffällig' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _befastResult = _befastResult == 'unauffällig' ? null : 'unauffällig';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('auffällig'),
                      selected: _befastResult == 'auffällig',
                      selectedColor: AppColors.critical,
                      labelStyle: TextStyle(
                        color: _befastResult == 'auffällig' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _befastResult = _befastResult == 'auffällig' ? null : 'auffällig';
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _bloodSugarController,
                  decoration: const InputDecoration(
                    labelText: 'Blutzucker',
                    suffixText: 'mg/dl',
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _disabilityIssueController,
                  decoration: const InputDecoration(
                    labelText: 'Problem D',
                    prefixIcon: Icon(Icons.sick),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _disabilityInterventionController,
                  decoration: const InputDecoration(
                    labelText: 'Maßnahmen D',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                // Medikamente für Disability
                MedicationsSectionWidget(
                  title: 'Medikamente bei D',
                  bgColor: Colors.purple.shade50,
                  medications: _disabilityMedications,
                  onMedicationsChanged: () {
                    // Widget wird automatisch neu gerendert
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('D speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
