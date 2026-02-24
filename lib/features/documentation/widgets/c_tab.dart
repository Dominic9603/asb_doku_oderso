import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/medication_serializer.dart';
import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import 'medications_section_widget.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class CTab extends StatefulWidget {
  const CTab({super.key});

  @override
  State<CTab> createState() => _CTabState();
}

class _CTabState extends State<CTab> {
  bool _externalBleeding = false;
  final _bleedingLocationController = TextEditingController();
  final _bleedingControlController = TextEditingController();

  // Zugang (wie in C)
  bool _ivAccess = false;
  final List<_CannulaSize> _cannulaSizes = const [
    _CannulaSize('14G', 'orange'),
    _CannulaSize('16G', 'grau'),
    _CannulaSize('18G', 'grün'),
    _CannulaSize('20G', 'rosa'),
    _CannulaSize('22G', 'blau'),
  ];
  _CannulaSize? _selectedCannula;
  final List<String> _ivSitesPreset = ['Kubita', 'Handrücken', 'Unterarm'];
  final _ivSiteController = TextEditingController();
  String? _ivSide; // 'links' / 'rechts'
  
  // Medikamente für Circulation (neues System)
  final List<Map<String, dynamic>> _circulationMedications = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<MissionProvider>();
    final abcde = provider.latestABCDE;
    if (abcde != null) {
      _externalBleeding = abcde.externalBleeding;
      _bleedingLocationController.text = abcde.bleedingLocation ?? '';
      _bleedingControlController.text = abcde.bleedingControl ?? '';

      final ci = abcde.circulationIntervention ?? '';
      // Zugang aus circulationIntervention rekonstruieren
      if (ci.contains('Zugang (c)')) _ivAccess = true;
      for (final c in _cannulaSizes) {
        if (ci.contains(c.label)) _selectedCannula = c;
      }
      final siteMatch = RegExp(r'Ort \(c\):\s*([^,|]+)').firstMatch(ci);
      if (siteMatch != null) {
        _ivSiteController.text = siteMatch.group(1)?.trim() ?? '';
      }
      if (ci.contains('Seite \(c\): links')) _ivSide = 'links';
      if (ci.contains('Seite \(c\): rechts')) _ivSide = 'rechts';

      // Parse circulationMedications zurück in Liste (JSON oder altes Format)
      _circulationMedications.addAll(
        MedicationSerializer.deserialize(abcde.circulationMedications),
      );
    }
  }

  @override
  void dispose() {
    _bleedingLocationController.dispose();
    _bleedingControlController.dispose();
    _ivSiteController.dispose();
    super.dispose();
  }

  String _buildCirculationInterventionC() {
    final parts = <String>[];

    if (_ivAccess && _selectedCannula != null) {
      var text =
          'Zugang (c): ${_selectedCannula!.label} (${_selectedCannula!.color})';
      if (_ivSiteController.text.isNotEmpty) {
        text += ', Ort (c): ${_ivSiteController.text}';
      }
      if (_ivSide != null) {
        text += ', Seite (c): $_ivSide';
      }
      parts.add(text);
    }

    return parts.join(' | ');
  }

  Future<void> _save() async {
    try {
      final provider = context.read<MissionProvider>();
      final mission = provider.currentMission;
      if (mission == null) return;

      final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);

    final bleedingControl = _bleedingControlController.text.isEmpty
        ? null
        : _bleedingControlController.text;

    final cInterventionC = _buildCirculationInterventionC();
    // Bestehende circulationIntervention aus anderen Abschnitten nicht überschreiben:
    final existingCirc = current.circulationIntervention;
    String? newCirc;
    if (existingCirc == null || existingCirc.isEmpty) {
      newCirc = cInterventionC.isEmpty ? null : cInterventionC;
    } else if (cInterventionC.isEmpty) {
      newCirc = existingCirc;
    } else {
      newCirc = '$existingCirc | $cInterventionC';
    }
    
    // Neue Medikamente für Circulation speichern
    final medicationsText = MedicationSerializer.serialize(_circulationMedications);

    final updated = current.copyWith(
      externalBleeding: _externalBleeding,
      bleedingLocation: _bleedingLocationController.text.isEmpty
          ? null
          : _bleedingLocationController.text,
      bleedingControl: bleedingControl,
      circulationIntervention: newCirc,
      circulationMedications: medicationsText.isEmpty ? null : medicationsText,
    );

      await provider.addOrUpdateABCDE(updated);

      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('c - Critical Bleeding gespeichert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Fehler beim Speichern: $e');
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMeasures = true; // bei c immer Maßnahmenblock sichtbar

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
                  'c - Critical Bleeding',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lebensbedrohliche Blutungen zuerst kontrollieren.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  value: _externalBleeding,
                  onChanged: (value) {
                    setState(() => _externalBleeding = value);
                  },
                  title: const Text('Starke äußere Blutung vorhanden'),
                  secondary: Icon(
                    Icons.bloodtype,
                    color:
                        _externalBleeding ? AppColors.critical : Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _bleedingLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Blutungsort',
                    hintText: 'z.B. Oberschenkel rechts',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _bleedingControlController,
                  decoration: const InputDecoration(
                    labelText: 'Blutungskontrolle / Maßnahmen',
                    hintText: 'z.B. Tourniquet, Druckverband, Wundtamponade',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                if (showMeasures) ...[
                  _buildAccessCard(context),
                ],

                const SizedBox(height: 16),

                // Medikamente für Critical Bleeding
                MedicationsSectionWidget(
                  title: 'Medikamente bei c',
                  bgColor: Colors.orange.shade50,
                  medications: _circulationMedications,
                  onMedicationsChanged: () {
                    // Widget wird automatisch neu gerendert
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('c speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessCard(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: _ivAccess,
              onChanged: (v) {
                setState(() => _ivAccess = v ?? false);
              },
              title: const Text('Venen-/Knochenzugang (c) gelegt'),
              dense: true,
            ),
            if (_ivAccess) ...[
              const SizedBox(height: 8),
              const Text(
                'Größe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: _cannulaSizes.map((c) {
                  final selected = _selectedCannula == c;
                  return ChoiceChip(
                    label: Text('${c.label} (${c.color})'),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCannula = c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Applikationsort',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: _ivSitesPreset.map((s) {
                  final selected = _ivSiteController.text == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _ivSiteController.text = s;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seite',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('links'),
                    selected: _ivSide == 'links',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _ivSide == 'links' ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() => _ivSide = 'links');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('rechts'),
                    selected: _ivSide == 'rechts',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _ivSide == 'rechts' ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() => _ivSide = 'rechts');
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

class _CannulaSize {
  final String label;
  final String color;
  const _CannulaSize(this.label, this.color);
}
