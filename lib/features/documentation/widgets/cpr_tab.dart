import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import '../../medications/providers/medication_provider.dart';
import '../../medications/models/medication.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class CPRTab extends StatefulWidget {
  const CPRTab({super.key});

  @override
  State<CPRTab> createState() => _CPRTabState();
}

class _CPRTabState extends State<CPRTab> {
  // Tubus-Typen
  final List<String> _tubusTypes = [
    'Guedeltubus',
    'Wendltubus',
    'Larynxmaske',
    'Endotrachealtubus'
  ];
  final Set<String> _selectedTubusTypes = {};

  // Größen pro Typ
  final Map<String, List<String>> _tubusSizesByType = {
    'Guedeltubus': ['0', '1', '2', '3', '4', '5'],
    'Wendltubus': ['28', '30', '32'],
    'Larynxmaske': ['1', '1.5', '2', '2.5', '3', '4', '5'],
    'Endotrachealtubus': ['6.0', '6.5', '7.0', '7.5', '8.0', '8.5', '9.0'],
  };
  final Set<String> _selectedTubusSizes = {};

  // Schocks
  final _shocksController = TextEditingController();

  // ROSC
  String? _roscValue; // 'ja' oder 'nein'

  // Medikamente
  List<String> _cprMedications = []; // Liste der hinzugefügten Medikamente mit Dosis
  String? _selectedMedId;
  final _medDoseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final abcde = context.read<MissionProvider>().latestABCDE;
    if (abcde != null) {
      if (abcde.cprShocks != null) {
        _shocksController.text = abcde.cprShocks.toString();
      }
      if (abcde.cprROSC != null && abcde.cprROSC == true) {
        _roscValue = 'ja';
      } else if (abcde.cprROSC != null && abcde.cprROSC == false) {
        _roscValue = 'nein';
      }
      if (abcde.cprTubusTypes != null && abcde.cprTubusTypes!.isNotEmpty) {
        _selectedTubusTypes.addAll(abcde.cprTubusTypes!.split(',').map((e) => e.trim()));
      }
      if (abcde.cprTubusSizes != null && abcde.cprTubusSizes!.isNotEmpty) {
        _selectedTubusSizes.addAll(abcde.cprTubusSizes!.split(',').map((e) => e.trim()));
      }
      if (abcde.cprMedications != null && abcde.cprMedications!.isNotEmpty) {
        _cprMedications = abcde.cprMedications!.split('|').toList();
      }
    }
  }

  @override
  void dispose() {
    _shocksController.dispose();
    _medDoseController.dispose();
    super.dispose();
  }

  Future<void> _addMedication(List<Medication> allMeds) async {
    if (_selectedMedId == null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Bitte Medikament auswählen')),
      );
      return;
    }

    final med = allMeds.firstWhere(
      (m) => m.id == _selectedMedId,
      orElse: () => Medication(
        id: _selectedMedId ?? '',
        name: 'Unbekannt',
        activeIngredient: '',
        sectionsCsv: '',
      ),
    );

    final dose = _medDoseController.text.isNotEmpty
        ? _medDoseController.text
        : 'nach Schema';

    final medEntry = '${med.name} ($dose)';

    setState(() {
      _cprMedications.add(medEntry);
      _selectedMedId = null;
      _medDoseController.clear();
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _cprMedications.removeAt(index);
    });
  }

  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;

    final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);

    final tubusTypesStr = _selectedTubusTypes.isEmpty
        ? null
        : _selectedTubusTypes.join(',');
    final tubusSizesStr = _selectedTubusSizes.isEmpty
        ? null
        : _selectedTubusSizes.join(',');
    final medicationsStr = _cprMedications.isEmpty
        ? null
        : _cprMedications.join('|');
    final rosc = _roscValue == 'ja' ? true : (_roscValue == 'nein' ? false : null);

    final updated = current.copyWith(
      cprTubusTypes: tubusTypesStr,
      cprTubusSizes: tubusSizesStr,
      cprShocks: _shocksController.text.isEmpty
          ? null
          : int.tryParse(_shocksController.text),
      cprROSC: rosc,
      cprMedications: medicationsStr,
    );

    try {
      await provider.addOrUpdateABCDE(updated);

      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('CPR gespeichert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Fehler beim Speichern von CPR: $e');
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
    final medProvider = context.read<MedicationProvider>();
    final medsForCPR = medProvider.medicationsForSection('CPR');

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
                  'CPR - Cardiopulmonary Resuscitation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reanimation, Tubus-Management, Schocks und Medikamente.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Tubus-Typen
                Text(
                  'Tubusarten',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tubusTypes.map((type) {
                    final selected = _selectedTubusTypes.contains(type);
                    return FilterChip(
                      label: Text(type),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedTubusTypes.add(type);
                          } else {
                            _selectedTubusTypes.remove(type);
                            // Entferne auch Größen dieses Typs
                            final sizesForType = _tubusSizesByType[type] ?? [];
                            _selectedTubusSizes
                                .removeWhere((s) => sizesForType.contains(s));
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                // Größen pro Typ
                if (_selectedTubusTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Größen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._selectedTubusTypes.map((type) {
                    final sizes = _tubusSizesByType[type] ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: sizes.map((size) {
                              final selected = _selectedTubusSizes.contains(size);
                              return ChoiceChip(
                                label: Text(size),
                                selected: selected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : null,
                                ),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedTubusSizes.add(size);
                                    } else {
                                      _selectedTubusSizes.remove(size);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Schocks
                TextFormField(
                  controller: _shocksController,
                  decoration: const InputDecoration(
                    labelText: 'Anzahl Schocks',
                    prefixIcon: Icon(Icons.bolt),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                const SizedBox(height: 16),

                // ROSC
                Text(
                  'ROSC (Rückkehr von Eigenkreislauf)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Ja'),
                        value: 'ja',
                        groupValue: _roscValue,
                        onChanged: (value) {
                          setState(() => _roscValue = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Nein'),
                        value: 'nein',
                        groupValue: _roscValue,
                        onChanged: (value) {
                          setState(() => _roscValue = value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Medikamente
                Text(
                  'CPR-Medikamente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                // Medikamenten-Liste
                if (_cprMedications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _cprMedications.asMap().entries.map((e) {
                        final index = e.key;
                        final med = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  med,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _removeMedication(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 12),

                // Medikament hinzufügen
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedMedId,
                        decoration: const InputDecoration(
                          labelText: 'Medikament',
                          prefixIcon: Icon(Icons.medication),
                          isDense: true,
                        ),
                        items: medsForCPR.map((med) {
                          return DropdownMenuItem(
                            value: med.id,
                            child: Text(med.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedMedId = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _medDoseController,
                        decoration: const InputDecoration(
                          labelText: 'Dosis',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _addMedication(medsForCPR),
                  icon: const Icon(Icons.add),
                  label: const Text('Hinzufügen'),
                ),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('CPR speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
