import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../providers/mission_provider.dart';
import '../models/measure.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

/// Definitionen der Sub-Optionen pro Maßnahme
class _MeasureSubOption {
  final String label;
  final List<String> options;

  const _MeasureSubOption({required this.label, required this.options});
}

final Map<MeasureType, List<_MeasureSubOption>> _subOptions = {
  MeasureType.guedeltubus: [
    const _MeasureSubOption(label: 'Größe', options: ['000', '00', '0', '1', '2', '3', '4', '5']),
  ],
  MeasureType.wendltubus: [
    const _MeasureSubOption(label: 'Größe', options: ['28', '30', '32']),
  ],
  MeasureType.endotrachealIntubation: [
    const _MeasureSubOption(label: 'Tubusgröße', options: ['3.0', '3.5', '4.0', '4.5', '5.0', '5.5', '6.0', '6.5', '7.0', '7.5', '8.0', '8.5', '9.0']),
    const _MeasureSubOption(label: 'Weg', options: ['Oral', 'Nasal']),
  ],
  MeasureType.supraglotticAirway: [
    const _MeasureSubOption(label: 'Typ', options: ['Larynxmaske', 'Larynxtubus', 'i-gel']),
    const _MeasureSubOption(label: 'Größe', options: ['1', '1.5', '2', '2.5', '3', '4', '5']),
  ],
  MeasureType.absaugen: [
    const _MeasureSubOption(label: 'Weg', options: ['Oral', 'Nasal']),
  ],
  MeasureType.oxygenTherapy: [
    const _MeasureSubOption(label: 'Applikation', options: ['Nasenbrille', 'Maske', 'Reservoirmaske', 'High-Flow']),
    const _MeasureSubOption(label: 'Fluss (l/min)', options: ['2', '4', '6', '8', '10', '12', '15']),
  ],
  MeasureType.mechanicalVentilation: [
    const _MeasureSubOption(label: 'Modus', options: ['IPPV', 'SIMV', 'CPAP', 'BiPAP', 'ASB']),
    const _MeasureSubOption(label: 'FiO2 (%)', options: ['21', '40', '60', '80', '100']),
    const _MeasureSubOption(label: 'AF (/min)', options: ['8', '10', '12', '14', '16', '18', '20']),
    const _MeasureSubOption(label: 'Vt (ml)', options: ['300', '350', '400', '450', '500', '550', '600']),
    const _MeasureSubOption(label: 'PEEP (mbar)', options: ['0', '3', '5', '8', '10', '12', '15']),
    const _MeasureSubOption(label: 'Spitzendruck (mbar)', options: ['15', '20', '25', '30', '35']),
  ],
  MeasureType.ivAccess: [
    const _MeasureSubOption(label: 'Kanüle', options: ['24G', '22G', '20G', '18G', '17G', '16G', '14G']),
    const _MeasureSubOption(label: 'Ort', options: ['Handrücken', 'Unterarm', 'Ellenbeuge', 'V. jugularis ext.']),
  ],
  MeasureType.ioAccess: [
    const _MeasureSubOption(label: 'Ort', options: ['Tibia prox.', 'Tibia dist.', 'Humerus', 'Sternum']),
    const _MeasureSubOption(label: 'System', options: ['EZ-IO', 'BIG', 'FAST1']),
  ],
  MeasureType.fluidResuscitation: [
    const _MeasureSubOption(label: 'Lösung', options: ['NaCl 0.9%', 'Ringer', 'Sterofundin', 'Gelafundin', 'HyperHAES']),
    const _MeasureSubOption(label: 'Menge (ml)', options: ['100', '250', '500', '1000']),
  ],
  MeasureType.tourniquetApplication: [
    const _MeasureSubOption(label: 'Ort', options: ['OE rechts', 'OE links', 'UE rechts', 'UE links']),
  ],
  MeasureType.cervicalCollar: [
    const _MeasureSubOption(label: 'Größe', options: ['Pädiatrisch', 'S', 'M', 'L']),
  ],
  MeasureType.splinting: [
    const _MeasureSubOption(label: 'Lokalisation', options: ['OE rechts', 'OE links', 'UE rechts', 'UE links']),
    const _MeasureSubOption(label: 'Typ', options: ['SAM-Splint', 'Vakuumschiene', 'Traktionsschiene']),
  ],
  MeasureType.lagerung: [
    const _MeasureSubOption(label: 'Art', options: ['Flachlagerung', 'Oberkörperhochlagerung', 'Schocklagerung', 'Seitenlage', 'Bauchlage', 'Fritsch-Lagerung', 'Sitzend']),
  ],
  MeasureType.defibrillation: [
    const _MeasureSubOption(label: 'Energie (J)', options: ['120', '150', '200', '360']),
  ],
  MeasureType.ecgAbleitung: [
    const _MeasureSubOption(label: 'Ableitung', options: ['6-Kanal', '12-Kanal']),
  ],
};

/// Kategorie-Definitionen für die Anzeige
class _MeasureCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<MeasureType> types;

  const _MeasureCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.types,
  });
}

final List<_MeasureCategory> _categories = [
  _MeasureCategory(
    name: 'Atemweg',
    icon: Icons.air,
    color: AppColors.critical,
    types: [
      MeasureType.guedeltubus,
      MeasureType.wendltubus,
      MeasureType.endotrachealIntubation,
      MeasureType.supraglotticAirway,
      MeasureType.absaugen,
    ],
  ),
  _MeasureCategory(
    name: 'Beatmung',
    icon: Icons.wind_power,
    color: AppColors.info,
    types: [
      MeasureType.oxygenTherapy,
      MeasureType.bagValveMask,
      MeasureType.mechanicalVentilation,
      MeasureType.auskultation,
    ],
  ),
  _MeasureCategory(
    name: 'Kreislauf',
    icon: Icons.favorite,
    color: const Color(0xFFE53935),
    types: [
      MeasureType.ivAccess,
      MeasureType.ioAccess,
      MeasureType.fluidResuscitation,
      MeasureType.tourniquetApplication,
      MeasureType.woundPacking,
      MeasureType.druckverband,
    ],
  ),
  _MeasureCategory(
    name: 'Monitoring',
    icon: Icons.monitor_heart,
    color: AppColors.success,
    types: [
      MeasureType.ecgAbleitung,
      MeasureType.pulseOximetry,
      MeasureType.capnography,
      MeasureType.bloodPressureMonitoring,
    ],
  ),
  _MeasureCategory(
    name: 'Immobilisation',
    icon: Icons.back_hand,
    color: AppColors.warning,
    types: [
      MeasureType.cervicalCollar,
      MeasureType.spinalBoard,
      MeasureType.splinting,
      MeasureType.pelvicBinder,
      MeasureType.vakuummatratze,
      MeasureType.schaufeltrage,
      MeasureType.rettungstuch,
    ],
  ),
  _MeasureCategory(
    name: 'Versorgung',
    icon: Icons.healing,
    color: const Color(0xFF8E24AA),
    types: [
      MeasureType.wundverband,
      MeasureType.waermeerhalt,
      MeasureType.kuehlen,
      MeasureType.lagerung,
    ],
  ),
  _MeasureCategory(
    name: 'Sonstige',
    icon: Icons.medical_services,
    color: AppColors.primary,
    types: [
      MeasureType.cpr,
      MeasureType.defibrillation,
      MeasureType.pacing,
      MeasureType.nasogastricTube,
      MeasureType.other,
    ],
  ),
];

class MeasuresTab extends StatefulWidget {
  const MeasuresTab({super.key});

  @override
  State<MeasuresTab> createState() => _MeasuresTabState();
}

class _MeasuresTabState extends State<MeasuresTab> {
  /// Aktuell expandierte Maßnahme für Sub-Optionen
  MeasureType? _expandedType;

  /// Gewählte Sub-Optionen für die expandierte Maßnahme
  final Map<String, String?> _selectedSubOptions = {};

  /// Zählt wie oft ein MeasureType in der aktuellen Mission gespeichert ist
  Map<MeasureType, int> _countByType(List<Measure> measures) {
    final map = <MeasureType, int>{};
    for (final m in measures) {
      map[m.measureType] = (map[m.measureType] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MissionProvider>();
    final measures = provider.currentMeasures;
    final counts = _countByType(measures);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Maßnahmen-Auswahl nach Kategorien
        ..._categories.map((cat) => _buildCategorySection(context, cat, provider, counts)),
      ],
    );
  }

  /// Baut eine Kategorie-Sektion mit Chips (Badge + Long-Press)
  Widget _buildCategorySection(
    BuildContext context,
    _MeasureCategory category,
    MissionProvider provider,
    Map<MeasureType, int> counts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(category.icon, color: category.color, size: 20),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: category.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: category.types.map((type) {
            final tempMeasure = Measure.create('', type);
            final count = counts[type] ?? 0;
            final hasSaved = count > 0;
            final isExpanded = _expandedType == type;

            return GestureDetector(
              onLongPress: hasSaved
                  ? () => _handleLongPress(context, type, provider)
                  : null,
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tempMeasure.displayName),
                    if (hasSaved) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isExpanded || hasSaved
                              ? Colors.white.withOpacity(0.3)
                              : category.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${count}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasSaved && !isExpanded
                                ? Colors.white
                                : isExpanded
                                    ? Colors.white
                                    : category.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: hasSaved || isExpanded,
                selectedColor: category.color,
                labelStyle: TextStyle(
                  color: (hasSaved || isExpanded) ? Colors.white : null,
                  fontSize: 13,
                ),
                onSelected: (_) => _onMeasureTapped(context, type, provider),
              ),
            );
          }).toList(),
        ),

        // Sub-Optionen anzeigen wenn expandiert
        if (_expandedType != null && category.types.contains(_expandedType!))
          _buildSubOptions(context, _expandedType!, provider),

        const SizedBox(height: 4),
      ],
    );
  }

  /// Wenn ein Maßnahmen-Chip getippt wird → neue Instanz hinzufügen
  void _onMeasureTapped(BuildContext context, MeasureType type, MissionProvider provider) {
    final hasSubOptions = _subOptions.containsKey(type);

    if (hasSubOptions) {
      // Sub-Optionen anzeigen (toggle)
      setState(() {
        if (_expandedType == type) {
          _expandedType = null;
          _selectedSubOptions.clear();
        } else {
          _expandedType = type;
          _selectedSubOptions.clear();
        }
      });
    } else {
      // Sofort neue Instanz hinzufügen
      _saveMeasure(context, type, null, provider);
    }
  }

  /// Long-Press → Löschen-Dialog
  Future<void> _handleLongPress(BuildContext context, MeasureType type, MissionProvider provider) async {
    final measures = provider.currentMeasures
        .where((m) => m.measureType == type)
        .toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

    if (measures.isEmpty) return;

    final displayName = Measure.create('', type).displayName;

    if (measures.length == 1) {
      // Nur eine Instanz → einfacher Lösch-Dialog
      final m = measures.first;
      final timeStr = DateFormat('HH:mm').format(m.performedAt);
      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Maßnahme löschen'),
          content: Text('„$displayName" ($timeStr) löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
              child: const Text('Löschen'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await provider.deleteMeasure(m.id);
        if (mounted) setState(() {});
      }
    } else {
      // Mehrere Instanzen → Auswahl: eine oder alle löschen
      final result = await showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: Text('$displayName (${measures.length}x)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Was möchtest du löschen?'),
              const SizedBox(height: 16),
              ...measures.map((m) {
                final timeStr = DateFormat('HH:mm').format(m.performedAt);
                final notesStr = m.notes?.isNotEmpty == true ? '\n${m.notes}' : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text('$timeStr$notesStr', style: const TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: AppColors.critical),
                      onPressed: () => Navigator.pop(ctx, m.id),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, '_all'),
                  icon: const Icon(Icons.delete_sweep, color: AppColors.critical),
                  label: const Text('Alle löschen', style: TextStyle(color: AppColors.critical)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      );

      if (result == null || !mounted) return;

      if (result == '_all') {
        for (final m in measures) {
          await provider.deleteMeasure(m.id);
        }
      } else {
        await provider.deleteMeasure(result);
      }
      if (mounted) setState(() {});
    }
  }

  /// Baut die Sub-Optionen für eine expandierte Maßnahme
  Widget _buildSubOptions(BuildContext context, MeasureType type, MissionProvider provider) {
    final options = _subOptions[type];
    if (options == null) return const SizedBox.shrink();

    final tempMeasure = Measure.create('', type);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tempMeasure.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          ...options.map((sub) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sub.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: sub.options.map((opt) {
                  final selected = _selectedSubOptions[sub.label] == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedSubOptions[sub.label] = opt;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          )),

          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Notes aus Sub-Optionen zusammenbauen
                final notes = _selectedSubOptions.entries
                    .where((e) => e.value != null)
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', ');
                _saveMeasure(context, type, notes.isEmpty ? null : notes, provider);
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Speichern'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Speichert eine neue Maßnahmen-Instanz mit aktuellem Zeitstempel
  Future<void> _saveMeasure(BuildContext context, MeasureType type, String? notes, MissionProvider provider) async {
    final mission = provider.currentMission;
    if (mission == null) return;

    final measure = Measure(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      missionId: mission.id,
      measureType: type,
      performedAt: DateTime.now(),
      notes: notes,
    );

    await provider.addMeasure(measure);

    if (!mounted) return;

    setState(() {
      _expandedType = null;
      _selectedSubOptions.clear();
    });

    final displayName = Measure.create('', type).displayName;
    final timeStr = DateFormat('HH:mm').format(measure.performedAt);
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('✓ $displayName um $timeStr gespeichert'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
