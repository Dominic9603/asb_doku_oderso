import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/medication_serializer.dart';
import '../../documentation/models/vital_signs.dart';
import '../../documentation/providers/mission_provider.dart';
import '../../documentation/models/abcde_assessment.dart';

class ISBARScreen extends StatefulWidget {
  final String missionId;

  const ISBARScreen({
    super.key,
    required this.missionId,
  });

  @override
  State<ISBARScreen> createState() => _ISBARScreenState();
}

class _ISBARScreenState extends State<ISBARScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMissionIfNeeded();
  }

  Future<void> _loadMissionIfNeeded() async {
    final provider = context.read<MissionProvider>();
    if (provider.currentMission == null ||
        provider.currentMission!.id != widget.missionId) {
      await provider.loadMission(widget.missionId);
    }
    if (mounted) setState(() => _loading = false);
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month * 100 + now.day < dob.month * 100 + dob.day) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = context.read<MissionProvider>();
    return _buildISBARContent(context, provider);
  }

  Widget _buildISBARContent(BuildContext context, MissionProvider provider) {
    final mission = provider.currentMission;
    final patient = provider.currentPatient;
    final abcde = provider.latestABCDE;
    final vital = provider.latestVitalSigns;

    if (mission == null || patient == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dob = patient.dateOfBirth;
    final dobText =
        dob != null ? DateFormat('dd/MM/yyyy').format(dob) : '-';
    final age = _calculateAge(dob);
    final ageText = age != null ? '$age Jahre' : '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISBAR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // I: Name und Alter
            _buildSection(
              title: 'I – Identifikation (Name & Alter)',
              content: '''
Name: ${patient.firstName ?? ''} ${patient.lastName ?? ''}
Geburtsdatum: $dobText
Alter: $ageText
Einsatznummer: ${mission.missionNumber ?? mission.id}
''',
            ),

            // S: Notfallereignis, Erstbefund aus ABCDE, Verdachtsdiagnose
            _buildSection(
              title: 'S – Situation (Notfallereignis & Erstbefund)',
              content: '''
Notfallereignis:
${abcde?.eventDescription ?? patient.eventsLeadingToIllness ?? '-'}

Erstbefund nach cABCDE:
${_buildAbcdeSummary(abcde)}

Verdachtsdiagnose:
(noch als Freitext zu erfassen)
''',
            ),

            // CPR: Nur anzeigen, wenn Daten vorhanden
            if (_hasCPRData(abcde))
              _buildSection(
                title: 'CPR – Cardiopulmonary Resuscitation',
                content: _buildCPRSummary(abcde),
              ),

            // O: Letzte Messwerte + Maßnahmen (aus VitalSigns + ABCDE)
            _buildSection(
              title: 'O – Objektiv (Messwerte & Maßnahmen)',
              content: _buildObjectiveSummary(abcde, vital),
            ),

            // B: Background – SAMPLER aus Patient
            _buildSection(
              title: 'B – Background (SAMPLER)',
              content: '''
S – Symptome: ${patient.symptoms ?? '-'}
A – Allergien: ${patient.allergies ?? '-'}
M – Medikation: ${patient.medications ?? '-'}
P – Vorerkrankungen: ${patient.pastMedicalHistory ?? '-'}
L – Letzte orale Aufnahme: ${patient.lastOralIntake ?? '-'}
E – Ereignis: ${patient.eventsLeadingToIllness ?? '-'}
R – Risikofaktoren: ${patient.riskFactors ?? '-'}
''',
            ),

            // A: Nächste Schritte – aktuell Freitext / später Feld in Mission
            _buildSection(
              title: 'A – Assessment / Nächste Schritte',
              content: '''
Einschätzung / klinische Beurteilung:
(noch als Freitext zu erfassen)

Nächste Schritte / Plan:
(noch als Freitext zu erfassen)
''',
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Hilfsfunktionen ----------

  static Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$title\n\n',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: content,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _buildAbcdeSummary(ABCDEAssessment? abcde) {
    if (abcde == null) {
      return 'cABCDE noch nicht dokumentiert.';
    }

    final b = StringBuffer();

    // A – Airway
    b.writeln('A – Airway:');
    if (abcde.airwayThreatened) {
      b.writeln('Atemweg bedroht.');
    } else {
      b.writeln('Atemweg frei.');
    }
    if (abcde.airwayIssue != null) {
      b.writeln('Problem: ${abcde.airwayIssue}');
    }
    if (abcde.airwayIntervention != null) {
      b.writeln('Maßnahmen: ${abcde.airwayIntervention}');
    }
    _appendMedications(b, abcde.airwayMedications);
    b.writeln();

    // B – Breathing
    b.writeln('B – Breathing:');
    if (abcde.respiratoryRate != null) {
      b.writeln('AF: ${abcde.respiratoryRate} /min');
    }
    if (abcde.spo2 != null) {
      b.writeln('SpO₂: ${abcde.spo2!.toStringAsFixed(1)} %');
    }
    if (abcde.breathingSounds != null) {
      b.writeln('Auskultation: ${abcde.breathingSounds}');
    }
    b.writeln('Symmetrische Thoraxexkursion: '
        '${abcde.symmetricBreathing ? 'ja' : 'nein'}');
    if (abcde.breathingIssue != null) {
      b.writeln('Problem: ${abcde.breathingIssue}');
    }
    if (abcde.breathingIntervention != null) {
      b.writeln('Maßnahmen: ${abcde.breathingIntervention}');
    }
    _appendMedications(b, abcde.breathingMedications);
    b.writeln();

    // c – Critical Bleeding
    b.writeln('c – Critical Bleeding:');
    b.writeln('Starke äußere Blutung: '
        '${abcde.externalBleeding ? 'ja' : 'nein'}');
    if (abcde.bleedingLocation != null) {
      b.writeln('Blutungsort: ${abcde.bleedingLocation}');
    }
    if (abcde.bleedingControl != null) {
      b.writeln('Blutungskontrolle: ${abcde.bleedingControl}');
    }
    b.writeln();

    // C – Circulation
    b.writeln('C – Circulation:');
    if (abcde.heartRate != null) {
      b.writeln('HF: ${abcde.heartRate} /min');
    }
    if (abcde.systolicBP != null && abcde.diastolicBP != null) {
      b.writeln('RR: ${abcde.systolicBP}/${abcde.diastolicBP} mmHg');
    }
    if (abcde.capillaryRefill != null) {
      b.writeln('Kapilläre Füllung: ${abcde.capillaryRefill}');
    }
    if (abcde.pulseQuality != null) {
      b.writeln('Pulsqualität: ${abcde.pulseQuality}');
    }
    if (abcde.skinColor != null) {
      b.writeln('Haut: ${abcde.skinColor}');
    }
    if (abcde.circulationIssue != null) {
      b.writeln('Problem C: ${abcde.circulationIssue}');
    }
    if (abcde.circulationIntervention != null) {
      b.writeln('Maßnahmen C: ${abcde.circulationIntervention}');
    }
    _appendMedications(b, abcde.circulationMedications);
    b.writeln();

    // D – Disability
    b.writeln('D – Disability:');
    if (abcde.gcsEye != null &&
        abcde.gcsVerbal != null &&
        abcde.gcsMotor != null) {
      final gcsTotal = abcde.gcsEye! + abcde.gcsVerbal! + abcde.gcsMotor!;
      b.writeln(
          'GCS: $gcsTotal (E${abcde.gcsEye}/V${abcde.gcsVerbal}/M${abcde.gcsMotor})');
    }
    if (abcde.pupilLeft != null || abcde.pupilRight != null) {
      b.writeln('Pupillen: '
          'links: ${abcde.pupilLeft ?? '-'}, '
          'rechts: ${abcde.pupilRight ?? '-'}');
    }
    if (abcde.bloodSugar != null) {
      b.writeln('Blutzucker: ${abcde.bloodSugar!.toStringAsFixed(0)} mg/dl');
    }
    if (abcde.befastResult != null) {
      b.writeln('BE-FAST: ${abcde.befastResult}');
    }
    if (abcde.disabilityIssue != null) {
      b.writeln('Problem D: ${abcde.disabilityIssue}');
    }
    if (abcde.disabilityIntervention != null) {
      b.writeln('Maßnahmen D: ${abcde.disabilityIntervention}');
    }
    _appendMedications(b, abcde.disabilityMedications);
    b.writeln();

    // E – Exposure
    b.writeln('E – Exposure/Environment:');
    if (abcde.temperature != null) {
      b.writeln('Temperatur: ${abcde.temperature!.toStringAsFixed(1)} °C');
    }
    if (abcde.injuries != null) {
      b.writeln('Verletzungen: ${abcde.injuries}');
    }
    if (abcde.environmentalFactors != null) {
      b.writeln('Umgebungsfaktoren: ${abcde.environmentalFactors}');
    }
    if (abcde.exposureIssue != null) {
      b.writeln('Problem E: ${abcde.exposureIssue}');
    }
    if (abcde.exposureIntervention != null) {
      b.writeln('Maßnahmen E: ${abcde.exposureIntervention}');
    }
    _appendMedications(b, abcde.exposureMedications);
    if (abcde.situationNotes != null && abcde.situationNotes!.isNotEmpty) {
      b.writeln();
      b.writeln('Situation vor Ort / Einsatzablauf:');
      b.writeln(abcde.situationNotes);
    }

    return b.toString().trim();
  }

  /// Fügt Medikamente formatiert an den StringBuffer an
  static void _appendMedications(StringBuffer b, String? medicationsRaw) {
    if (medicationsRaw == null || medicationsRaw.isEmpty) return;
    final meds = MedicationSerializer.deserialize(medicationsRaw);
    if (meds.isEmpty) return;
    b.writeln('Medikamente:');
    for (final med in meds) {
      final name = med['name'] ?? '';
      final dose = med['dose'] ?? '';
      b.writeln('  • $name${dose.isNotEmpty ? ' – $dose' : ''}');
    }
  }

  static String _buildObjectiveSummary(
    ABCDEAssessment? abcde,
    VitalSigns? vital,
  ) {
    final b = StringBuffer();

    b.writeln('Letzte Messwerte:');
    if (vital == null || !vital.hasAnyData) {
      b.writeln('(noch keine Vitalparameter dokumentiert)');
    } else {
      if (vital.heartRate != null) {
        b.writeln('HF: ${vital.heartRate} /min');
      }
      if (vital.systolicBP != null && vital.diastolicBP != null) {
        b.writeln('RR: ${vital.bloodPressure} mmHg');
      }
      if (vital.respiratoryRate != null) {
        b.writeln('AF: ${vital.respiratoryRate} /min');
      }
      if (vital.spo2 != null) {
        b.writeln('SpO₂: ${vital.spo2!.toStringAsFixed(1)} %');
      }
      if (vital.temperature != null) {
        b.writeln('Temp: ${vital.temperature!.toStringAsFixed(1)} °C');
      }
      if (vital.bloodSugar != null) {
        b.writeln('BZ: ${vital.bloodSugar!.toStringAsFixed(0)} mg/dl');
      }
    }
    b.writeln();

    b.writeln('Durchgeführte Maßnahmen:');
    if (abcde != null) {
      final measures = <String>[];
      if (abcde.airwayIntervention != null &&
          abcde.airwayIntervention!.isNotEmpty) {
        measures.add('A: ${abcde.airwayIntervention}');
      }
      if (abcde.breathingIntervention != null &&
          abcde.breathingIntervention!.isNotEmpty) {
        measures.add('B: ${abcde.breathingIntervention}');
      }
      if (abcde.circulationIntervention != null &&
          abcde.circulationIntervention!.isNotEmpty) {
        measures.add('C/c: ${abcde.circulationIntervention}');
      }
      if (abcde.exposureIntervention != null &&
          abcde.exposureIntervention!.isNotEmpty) {
        measures.add('E: ${abcde.exposureIntervention}');
      }

      if (measures.isEmpty) {
        b.writeln('(noch keine Maßnahmen dokumentiert)');
      } else {
        b.writeln(measures.join('\n'));
      }
    } else {
      b.writeln('(noch keine Maßnahmen dokumentiert)');
    }

    return b.toString().trim();
  }

  static bool _hasCPRData(ABCDEAssessment? abcde) {
    if (abcde == null) return false;
    return (abcde.cprTubusTypes != null && abcde.cprTubusTypes!.isNotEmpty) ||
        abcde.cprShocks != null ||
        abcde.cprROSC != null ||
        (abcde.cprMedications != null && abcde.cprMedications!.isNotEmpty);
  }

  static String _buildCPRSummary(ABCDEAssessment? abcde) {
    if (abcde == null) return 'CPR noch nicht dokumentiert.';

    final b = StringBuffer();

    if (abcde.cprTubusTypes != null && abcde.cprTubusTypes!.isNotEmpty) {
      b.writeln('Tubusarten: ${abcde.cprTubusTypes}');
      if (abcde.cprTubusSizes != null && abcde.cprTubusSizes!.isNotEmpty) {
        b.writeln('Größen: ${abcde.cprTubusSizes}');
      }
    }

    if (abcde.cprShocks != null) {
      b.writeln('Schocks: ${abcde.cprShocks}');
    }

    if (abcde.cprROSC != null) {
      b.writeln('ROSC: ${abcde.cprROSC == true ? 'ja' : 'nein'}');
    }

    if (abcde.cprMedications != null && abcde.cprMedications!.isNotEmpty) {
      b.writeln('Medikamente:');
      final meds = abcde.cprMedications!.split('|');
      for (final med in meds) {
        b.writeln('  • $med');
      }
    }

    return b.toString().trim();
  }
}
