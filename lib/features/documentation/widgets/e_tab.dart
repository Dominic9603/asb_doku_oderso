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
  final _situationNotesController = TextEditingController();

  // SAMPLER Schema (Anamnese)
  final _samplerSymptomsController = TextEditingController();
  final _samplerAllergiesController = TextEditingController();
  final _samplerMedicationsController = TextEditingController();
  final _samplerPastMedicalHistoryController = TextEditingController();
  final _samplerLastOralIntakeController = TextEditingController();
  final _samplerEventsController = TextEditingController();
  final _samplerRiskFactorsController = TextEditingController();

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
      _situationNotesController.text = abcde.situationNotes ?? '';

      _samplerSymptomsController.text = abcde.samplerSymptoms ?? '';
      _samplerAllergiesController.text = abcde.samplerAllergies ?? '';
      _samplerMedicationsController.text = abcde.samplerMedications ?? '';
      _samplerPastMedicalHistoryController.text =
          abcde.samplerPastMedicalHistory ?? '';
      _samplerLastOralIntakeController.text = abcde.samplerLastOralIntake ?? '';
      _samplerEventsController.text = abcde.samplerEvents ?? '';
      _samplerRiskFactorsController.text = abcde.samplerRiskFactors ?? '';

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
    _situationNotesController.dispose();
    _samplerSymptomsController.dispose();
    _samplerAllergiesController.dispose();
    _samplerMedicationsController.dispose();
    _samplerPastMedicalHistoryController.dispose();
    _samplerLastOralIntakeController.dispose();
    _samplerEventsController.dispose();
    _samplerRiskFactorsController.dispose();
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
          : double.tryParse(_temperatureController.text),
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
      situationNotes: _situationNotesController.text.isEmpty
          ? null
          : _situationNotesController.text,
      samplerSymptoms: _samplerSymptomsController.text.isEmpty
          ? null
          : _samplerSymptomsController.text,
      samplerAllergies: _samplerAllergiesController.text.isEmpty
          ? null
          : _samplerAllergiesController.text,
      samplerMedications: _samplerMedicationsController.text.isEmpty
          ? null
          : _samplerMedicationsController.text,
      samplerPastMedicalHistory:
          _samplerPastMedicalHistoryController.text.isEmpty
          ? null
          : _samplerPastMedicalHistoryController.text,
      samplerLastOralIntake: _samplerLastOralIntakeController.text.isEmpty
          ? null
          : _samplerLastOralIntakeController.text,
      samplerEvents: _samplerEventsController.text.isEmpty
          ? null
          : _samplerEventsController.text,
      samplerRiskFactors: _samplerRiskFactorsController.text.isEmpty
          ? null
          : _samplerRiskFactorsController.text,
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

  Widget _buildSAMPLERField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String noneText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
        suffixIcon: TextButton(
          onPressed: () {
            setState(() {
              controller.text = noneText;
            });
          },
          child: const Text('Keine'),
        ),
      ),
      maxLines: 3,
      minLines: 1,
    );
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
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

                const Divider(),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _situationNotesController,
                  decoration: const InputDecoration(
                    labelText:
                        'Situation vor Ort / Einsatzablauf / Ergänzungen',
                    hintText:
                        'Zusammenfassung des Einsatzgeschehens, besondere Umstände, Anmerkungen …',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // SAMPLER Schema (Anamnese) - wie im ISBAR-Bericht sichtbar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SAMPLER Schema',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Anamnese',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSAMPLERField(
                  controller: _samplerSymptomsController,
                  label: 'S - Symptoms (Symptome)',
                  hint: 'Hauptbeschwerde, Leitsymptom',
                  icon: Icons.sick,
                  noneText: 'Keine aktuellen Beschwerden',
                ),
                const SizedBox(height: 12),

                _buildSAMPLERField(
                  controller: _samplerAllergiesController,
                  label: 'A - Allergies (Allergien)',
                  hint: 'Bekannte Allergien',
                  icon: Icons.coronavirus,
                  noneText: 'Keine bekannten Allergien',
                ),
                const SizedBox(height: 12),

                _buildSAMPLERField(
                  controller: _samplerMedicationsController,
                  label: 'M - Medications (Medikamente)',
                  hint: 'Aktuelle Medikation',
                  icon: Icons.medication,
                  noneText: 'Keine regelmäßige Medikation',
                ),
                const SizedBox(height: 12),

                _buildSAMPLERField(
                  controller: _samplerPastMedicalHistoryController,
                  label: 'P - Past Medical History (Vorerkrankungen)',
                  hint: 'Relevante Vorerkrankungen',
                  icon: Icons.history,
                  noneText: 'Keine relevanten Vorerkrankungen bekannt',
                ),
                const SizedBox(height: 12),

                _buildSAMPLERField(
                  controller: _samplerLastOralIntakeController,
                  label: 'L - Last Oral Intake (Letzte Nahrungsaufnahme)',
                  hint: 'Zeitpunkt und Art',
                  icon: Icons.restaurant,
                  noneText: 'Nicht erhoben',
                ),
                const SizedBox(height: 12),

                _buildSAMPLERField(
                  controller: _samplerEventsController,
                  label: 'E - Events (Ereignisse)',
                  hint: 'Ereignisse die zum aktuellen Zustand führten',
                  icon: Icons.event,
                  noneText: 'Keine besonderen Ereignisse berichtet',
                ),
                const SizedBox(height: 12),

                _buildSAMPLERField(
                  controller: _samplerRiskFactorsController,
                  label: 'R - Risk Factors (Risikofaktoren)',
                  hint: 'Weitere Risikofaktoren',
                  icon: Icons.warning_amber,
                  noneText: 'Keine relevanten Risikofaktoren bekannt',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('E speichern'),
        ),
      ],
    );
  }
}
