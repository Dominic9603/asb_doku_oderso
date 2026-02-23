import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../documentation/providers/mission_provider.dart';
import '../providers/isbar_provider.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class ISBARHandoverScreen extends StatefulWidget {
  const ISBARHandoverScreen({super.key});

  @override
  State<ISBARHandoverScreen> createState() => _ISBARHandoverScreenState();
}

class _ISBARHandoverScreenState extends State<ISBARHandoverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identificationController = TextEditingController();
  final _situationController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _assessmentController = TextEditingController();
  final _recommendationController = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final mission = context.read<MissionProvider>().currentMission;
    if (mission != null) {
      context.read<ISBARProvider>().loadForMission(mission.id).then((_) {
        final handover = context.read<ISBARProvider>().current;
        if (handover != null) {
          _identificationController.text = handover.identification ?? '';
          _situationController.text = handover.situation ?? '';
          _backgroundController.text = handover.background ?? '';
          _assessmentController.text = handover.assessment ?? '';
          _recommendationController.text = handover.recommendation ?? '';
        }
      });
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _identificationController.dispose();
    _situationController.dispose();
    _backgroundController.dispose();
    _assessmentController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mission = context.read<MissionProvider>().currentMission;
    if (mission == null) return;

    if (!_formKey.currentState!.validate()) return;

    await context.read<ISBARProvider>().saveForMission(
          missionId: mission.id,
          identification: _identificationController.text.trim().isEmpty
              ? null
              : _identificationController.text.trim(),
          situation: _situationController.text.trim().isEmpty
              ? null
              : _situationController.text.trim(),
          background: _backgroundController.text.trim().isEmpty
              ? null
              : _backgroundController.text.trim(),
          assessment: _assessmentController.text.trim().isEmpty
              ? null
              : _assessmentController.text.trim(),
          recommendation: _recommendationController.text.trim().isEmpty
              ? null
              : _recommendationController.text.trim(),
        );

    if (!mounted) return;
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('ISBAR gespeichert'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = context.read<MissionProvider>().currentMission;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISBAR Übergabe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: mission == null
          ? const Center(child: Text('Kein Einsatz ausgewählt'))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'ISBAR für Einsatz ${mission.missionNumber ?? mission.id}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _identificationController,
                      decoration: const InputDecoration(
                        labelText: 'I – Identification',
                        hintText:
                            'Wer ruft an? Wer ist der Patient? Station/Fahrzeug, Name, Alter …',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _situationController,
                      decoration: const InputDecoration(
                        labelText: 'S – Situation',
                        hintText:
                            'Aktuelle Situation: Warum rufst du an? Hauptproblem, Leitsymptom …',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _backgroundController,
                      decoration: const InputDecoration(
                        labelText: 'B – Background',
                        hintText:
                            'Wichtige Vorgeschichte: Vorerkrankungen, Medikamente, Allergien …',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _assessmentController,
                      decoration: const InputDecoration(
                        labelText: 'A – Assessment',
                        hintText:
                            'Deine Einschätzung: Befunde aus ABCDE, Vitalparameter, Risiko …',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _recommendationController,
                      decoration: const InputDecoration(
                        labelText: 'R – Recommendation',
                        hintText:
                            'Was wünschst du dir? Aufnahme, Diagnostik, Therapie, Konsil …',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('ISBAR speichern'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
