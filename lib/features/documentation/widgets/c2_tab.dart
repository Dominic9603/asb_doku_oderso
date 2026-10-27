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

class C2Tab extends StatefulWidget {
  const C2Tab({super.key});

  @override
  State<C2Tab> createState() => C2TabState();
}

class C2TabState extends State<C2Tab> {
  // Vitalwerte
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final List<String> _ivSitesPreset = ['Kubita', 'Handrücken', 'Unterarm'];

  // NEU: Notfallereignis
  final _eventDescriptionController = TextEditingController();

  // Kapillare Füllung
  String? _capRefill; // "<2s" oder ">2s"

  // Pulsqualität
  final List<String> _pulseOptions = ['kräftig', 'schwach', 'nicht tastbar'];
  String? _pulseQuality;

  // Puls-Lokalisation
  String? _pulseLocation; // 'zentral', 'peripher', 'beide'
  static const List<String> _pulseLocationOptions = ['zentral', 'peripher'];

  // Herzfrequenz-Eindruck
  String? _rateType; // 'normofrequent', 'tachykard', 'bradykard'
  static const List<String> _rateOptions = [
    'normofrequent',
    'tachykard',
    'bradykard',
  ];

  // Rhythmus
  String? _rhythmType; // 'rhythmisch', 'arrhythmisch'
  // Reihenfolge wichtig: 'arrhythmisch' muss vor 'rhythmisch' geprüft werden,
  // da 'rhythmisch' sonst fälschlich als Teilstring in 'arrhythmisch' matcht.
  static const List<String> _rhythmOptions = ['arrhythmisch', 'rhythmisch'];

  // Haut
  final List<String> _skinOptions = ['rosig', 'blass', 'kalt', 'feucht'];
  final Set<String> _selectedSkin = {};

  // Medikamente für Circulation (neues System)
  final List<Map<String, dynamic>> _circulationMedications = [];

  // Problem / Maßnahmen-Freitext
  final _circulationIssueController = TextEditingController();

  // Verdachtsdiagnose
  final _suspectedDiagnosisController = TextEditingController();

  // Zugang
  bool _ivAccess = false;
  final List<_CannulaSize> _cannulaSizes = const [
    _CannulaSize('14G', 'orange'),
    _CannulaSize('16G', 'grau'),
    _CannulaSize('18G', 'grün'),
    _CannulaSize('20G', 'rosa'),
    _CannulaSize('22G', 'blau'),
  ];
  _CannulaSize? _selectedCannula;
  final _ivSiteController = TextEditingController(); // z.B. Handrücken
  String? _ivSide; // 'links' / 'rechts'

  @override
  void initState() {
    super.initState();
    final provider = context.read<MissionProvider>();
    final abcde = provider.latestABCDE;
    if (abcde != null) {
      if (abcde.heartRate != null) {
        _heartRateController.text = abcde.heartRate.toString();
      }
      if (abcde.systolicBP != null) {
        _systolicController.text = abcde.systolicBP.toString();
      }
      if (abcde.diastolicBP != null) {
        _diastolicController.text = abcde.diastolicBP.toString();
      }

      _capRefill =
          abcde.capillaryRefill; // wir speichern direkt "<2s" oder ">2s"

      _pulseQuality = abcde.pulseQuality;
      if (abcde.skinColor != null) {
        // skinColor als kommagetrennter String, z.B. "blass, kalt"
        for (final s in abcde.skinColor!.split(',')) {
          final trimmed = s.trim();
          if (trimmed.isNotEmpty) _selectedSkin.add(trimmed);
        }
      }

      // Puls-Lokalisation/Frequenz/Rhythmus werden als strukturierte Tags im
      // Freitext "circulationIssue" mitgespeichert. Hier zurückparsen, damit sie
      // beim erneuten Öffnen korrekt vorausgewählt sind, statt beim nächsten
      // Speichern zusätzlich (dupliziert) angehängt zu werden.
      final rawIssue = abcde.circulationIssue ?? '';
      _pulseLocation = _extractPulseLocation(rawIssue);
      _rateType = _extractTag(rawIssue, 'Frequenz', _rateOptions);
      _rhythmType = _extractTag(rawIssue, 'Rhythmus', _rhythmOptions);
      _circulationIssueController.text = _stripStructuredTags(rawIssue);
      _suspectedDiagnosisController.text = abcde.suspectedDiagnosis ?? '';

      // Zugang: im circulationIntervention-Text suchen wir nach Mustern
      final ci = abcde.circulationIntervention ?? '';
      if (ci.contains('Zugang')) _ivAccess = true;
      for (final c in _cannulaSizes) {
        if (ci.contains(c.label)) _selectedCannula = c;
      }

      _eventDescriptionController.text = abcde.eventDescription ?? '';
      final siteMatch = RegExp(r'Ort:\s*([^,|]+)').firstMatch(ci);
      if (siteMatch != null)
        _ivSiteController.text = siteMatch.group(1)?.trim() ?? '';
      if (ci.contains('Seite: links')) _ivSide = 'links';
      if (ci.contains('Seite: rechts')) _ivSide = 'rechts';

      // Parse circulationMedications zurück in Liste (JSON oder altes Format)
      _circulationMedications.addAll(
        MedicationSerializer.deserialize(abcde.circulationMedications),
      );

      // Sync von Measures → IV-Zugang
      if (provider.currentMeasures.any(
        (m) => m.measureType == MeasureType.ivAccess,
      )) {
        _ivAccess = true;
      }
    }
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _circulationIssueController.dispose();
    _suspectedDiagnosisController.dispose();
    _eventDescriptionController.dispose();
    _ivSiteController.dispose();
    super.dispose();
  }

  /// Setzt den C-Tab (Circulation) auf den Ausgangszustand zurück (für
  /// "Baseline erneut erheben"). Notfallereignis und Verdachtsdiagnose
  /// bleiben erhalten, da sie unabhängig von der Kreislauf-Neubeurteilung
  /// sind. Die vorherige Erhebung bleibt als separater Datensatz mit eigenem
  /// Zeitstempel in der Dokumentation erhalten.
  void resetToDefaults() {
    setState(() {
      _heartRateController.clear();
      _systolicController.clear();
      _diastolicController.clear();
      _capRefill = null;
      _pulseQuality = null;
      _pulseLocation = null;
      _rateType = null;
      _rhythmType = null;
      _selectedSkin.clear();
      _circulationMedications.clear();
      _circulationIssueController.clear();
      _ivAccess = false;
      _selectedCannula = null;
      _ivSiteController.clear();
      _ivSide = null;
    });
  }

  String _buildCirculationIntervention() {
    final parts = <String>[];

    // Zugang
    if (_ivAccess && _selectedCannula != null) {
      var text =
          'Zugang: ${_selectedCannula!.label} (${_selectedCannula!.color})';
      if (_ivSiteController.text.isNotEmpty) {
        text += ', Ort: ${_ivSiteController.text}';
      }
      if (_ivSide != null) {
        text += ', Seite: $_ivSide';
      }
      parts.add(text);
    }

    return parts.join(' | ');
  }

  /// Sucht ein Tag der Form "Label: wert" (wert aus [options]) im Freitext.
  /// Es wird das letzte Vorkommen genommen, damit bei (alten, bereits
  /// doppelt gespeicherten) Datensätzen der zuletzt eingetragene Wert gilt.
  String? _extractTag(String text, String label, List<String> options) {
    final matches =
        RegExp('$label:\\s*(${options.join('|')})').allMatches(text);
    return matches.isEmpty ? null : matches.last.group(1);
  }

  /// Puls-Lokalisation ist als "Puls: zentral und peripher" gespeichert, wenn
  /// beide Optionen gewählt wurden, sonst "Puls: zentral" bzw. "Puls: peripher".
  String? _extractPulseLocation(String text) {
    final bothMatches = RegExp(r'Puls:\s*zentral und peripher').allMatches(text);
    final singleMatches =
        RegExp('Puls:\\s*(${_pulseLocationOptions.join('|')})').allMatches(text);
    if (bothMatches.isEmpty && singleMatches.isEmpty) return null;
    // Letztes Vorkommen über beide Varianten hinweg ermitteln.
    final lastBothEnd = bothMatches.isEmpty ? -1 : bothMatches.last.end;
    final lastSingleEnd = singleMatches.isEmpty ? -1 : singleMatches.last.end;
    if (lastBothEnd > lastSingleEnd) return 'beide';
    return singleMatches.last.group(1);
  }

  /// Entfernt die von uns automatisch angehängten "Puls:/Frequenz:/Rhythmus:"
  /// Segmente wieder aus dem Freitext, damit beim erneuten Speichern nur der
  /// aktuell gewählte Zustand erscheint und sich alte Werte nicht duplizieren
  /// (z.B. versehentlich "arrhythmisch" gefolgt von korrigiertem "rhythmisch").
  String _stripStructuredTags(String text) {
    const structuredPrefixes = ['Puls:', 'Frequenz:', 'Rhythmus:'];
    final segments = text
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final kept = <String>[];
    for (final segment in segments) {
      final parts =
          segment.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
      final isStructured = parts.isNotEmpty &&
          parts.every(
            (p) => structuredPrefixes.any((prefix) => p.startsWith(prefix)),
          );
      if (!isStructured) kept.add(segment);
    }
    return kept.join(' | ');
  }

  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;

    final current = provider.latestABCDE ?? ABCDEAssessment.create(mission.id);

    final skinText = _selectedSkin.isEmpty ? null : _selectedSkin.join(', ');
    final intervention = _buildCirculationIntervention();

    // Pulszusatz in Problem C aufnehmen (optional, damit es im PDF sichtbar ist).
    // Zuerst eventuell noch vorhandene alte Tags entfernen, damit der
    // aktuell gewählte Zustand den alten ersetzt statt ihn zu duplizieren.
    String issue = _stripStructuredTags(_circulationIssueController.text);
    final extraParts = <String>[];

    if (_pulseLocation != null) {
      final pulseLocationLabel = _pulseLocation == 'beide'
          ? 'zentral und peripher'
          : _pulseLocation;
      extraParts.add('Puls: $pulseLocationLabel');
    }
    if (_rateType != null) {
      extraParts.add('Frequenz: $_rateType');
    }
    if (_rhythmType != null) {
      extraParts.add('Rhythmus: $_rhythmType');
    }

    if (extraParts.isNotEmpty) {
      final extraText = extraParts.join(', ');
      issue = issue.isEmpty ? extraText : '$issue | $extraText';
    }
    // Medikamente serialisieren
    final medicationsText = MedicationSerializer.serialize(
      _circulationMedications,
    );

    final updated = current.copyWith(
      heartRate: _heartRateController.text.isEmpty
          ? null
          : int.parse(_heartRateController.text),
      systolicBP: _systolicController.text.isEmpty
          ? null
          : int.parse(_systolicController.text),
      diastolicBP: _diastolicController.text.isEmpty
          ? null
          : int.parse(_diastolicController.text),
      pulseQuality: _pulseQuality,
      skinColor: skinText,
      capillaryRefill: _capRefill,
      circulationIssue: issue.isEmpty ? null : issue,
      circulationIntervention: intervention.isEmpty ? null : intervention,
      circulationMedications: medicationsText.isEmpty ? null : medicationsText,
      suspectedDiagnosis: _suspectedDiagnosisController.text.trim().isEmpty
          ? null
          : _suspectedDiagnosisController.text.trim(),
      eventDescription: _eventDescriptionController.text.isEmpty
          ? null
          : _eventDescriptionController.text,
    );

    await provider.addOrUpdateABCDE(updated);

    // Sync IV-Zugang → Measures-Tab
    if (_ivAccess && _selectedCannula != null) {
      final noteParts = <String>['Kanüle: ${_selectedCannula!.label}'];
      if (_ivSiteController.text.isNotEmpty)
        noteParts.add('Ort: ${_ivSiteController.text}');
      if (_ivSide != null) noteParts.add('Seite: $_ivSide');
      await provider.ensureMeasureExists(
        MeasureType.ivAccess,
        notes: noteParts.join(', '),
      );
    }

    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('C - Circulation gespeichert'),
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
                  'C - Circulation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kreislauf, Perfusion, Blutdruck, Zugang & Medikamente.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),

                // Vitalwerte
                Column(
                  children: [
                    TextFormField(
                      controller: _heartRateController,
                      decoration: const InputDecoration(
                        labelText: 'Herzfrequenz',
                        suffixText: '/min',
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _systolicController,
                      decoration: const InputDecoration(
                        labelText: 'RR systolisch',
                        suffixText: 'mmHg',
                        prefixIcon: Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diastolicController,
                      decoration: const InputDecoration(
                        labelText: 'RR diastolisch',
                        suffixText: 'mmHg',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Kapillare Füllung
                const Text(
                  'Kapilläre Füllung',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('< 2 s'),
                      selected: _capRefill == '<2s',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _capRefill == '<2s' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() => _capRefill = '<2s');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('> 2 s'),
                      selected: _capRefill == '>2s',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _capRefill == '>2s' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() => _capRefill = '>2s');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pulsqualität
                const Text(
                  'Pulsqualität',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _pulseOptions.map((p) {
                    final selected = _pulseQuality == p;
                    return ChoiceChip(
                      label: Text(p),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() => _pulseQuality = p);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Puls-Lokalisation
                const Text(
                  'Puls tastbar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('zentral'),
                      selected: _pulseLocation == 'zentral',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _pulseLocation == 'zentral'
                            ? Colors.white
                            : null,
                      ),
                      onSelected: (_) {
                        setState(() => _pulseLocation = 'zentral');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('peripher'),
                      selected: _pulseLocation == 'peripher',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _pulseLocation == 'peripher'
                            ? Colors.white
                            : null,
                      ),
                      onSelected: (_) {
                        setState(() => _pulseLocation = 'peripher');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('zentral + peripher'),
                      selected: _pulseLocation == 'beide',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _pulseLocation == 'beide' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() => _pulseLocation = 'beide');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Frequenz-Eindruck
                const Text(
                  'Herzfrequenz-Eindruck',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('normofrequent'),
                      selected: _rateType == 'normofrequent',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _rateType == 'normofrequent'
                            ? Colors.white
                            : null,
                      ),
                      onSelected: (_) {
                        setState(() => _rateType = 'normofrequent');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('tachykard'),
                      selected: _rateType == 'tachykard',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _rateType == 'tachykard' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() => _rateType = 'tachykard');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('bradykard'),
                      selected: _rateType == 'bradykard',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _rateType == 'bradykard' ? Colors.white : null,
                      ),
                      onSelected: (_) {
                        setState(() => _rateType = 'bradykard');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Rhythmus
                const Text(
                  'Rhythmus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('rhythmisch'),
                      selected: _rhythmType == 'rhythmisch',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _rhythmType == 'rhythmisch'
                            ? Colors.white
                            : null,
                      ),
                      onSelected: (_) {
                        setState(() => _rhythmType = 'rhythmisch');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('arrhythmisch'),
                      selected: _rhythmType == 'arrhythmisch',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _rhythmType == 'arrhythmisch'
                            ? Colors.white
                            : null,
                      ),
                      onSelected: (_) {
                        setState(() => _rhythmType = 'arrhythmisch');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Haut
                const Text(
                  'Haut',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _skinOptions.map((s) {
                    final selected = _selectedSkin.contains(s);
                    return FilterChip(
                      label: Text(s),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                      ),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedSkin.add(s);
                          } else {
                            _selectedSkin.remove(s);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                _buildAccessCard(context),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _circulationIssueController,
                  decoration: const InputDecoration(
                    labelText: 'Problem C',
                    prefixIcon: Icon(Icons.sick),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _eventDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Notfallereignis',
                    hintText: 'z.B. Sturz aus 3 m, Thoraxschmerz, Dyspnoe',
                    prefixIcon: Icon(Icons.report),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Verdachtsdiagnose
                TextFormField(
                  controller: _suspectedDiagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Verdachtsdiagnose',
                    hintText: 'z.B. NSTEMI, Herzinsuffizienz, Sepsis …',
                    prefixIcon: Icon(Icons.search),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Medikamente für Circulation
                MedicationsSectionWidget(
                  title: 'Medikamente bei C',
                  sectionCode: 'C',
                  bgColor: Colors.red.shade50,
                  medications: _circulationMedications,
                  onMedicationsChanged: () {
                    // Widget wird automatisch neu gerendert
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('C speichern'),
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
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade50,
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
              title: const Text('Venen-/Knochenzugang gelegt'),
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
