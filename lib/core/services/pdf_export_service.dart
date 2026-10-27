import 'dart:typed_data';
import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../features/documentation/models/mission.dart';
import '../../features/documentation/models/patient.dart';
import '../../features/documentation/models/abcde_assessment.dart';
import '../../features/documentation/models/vital_signs.dart';
import '../../features/documentation/models/measure.dart';
import '../../features/authentication/models/user_info.dart';
import '../../features/isbar/models/isbar_handover.dart';
import '../utils/medication_serializer.dart';

/// Service zur PDF-Generierung von Einsatzberichten
class PDFExportService {
  /// Generiert PDF-Bytes ohne Druckdialog (z.B. für Upload/Email)
  static Future<Uint8List> generatePdfBytes({
    required Mission mission,
    required Patient? patient,
    required List<ABCDEAssessment> abcdeAssessments,
    required List<VitalSigns> vitalSigns,
    required List<Measure> measures,
    required UserInfo? userInfo,
    ISBARHandover? isbar,
  }) async {
    print('📋 PDF Export - userInfo: $userInfo');
    print('📋 PDF Export - shortSign: "${userInfo?.shortSign}"');
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 0;
    PdfPage page = document.pages.add();

    const double pageWidth = 595;
    const double pageHeight = 842;
    const double margin = 20;
    const double signatureBlockHeight = 90;
    const double contentBottomY = pageHeight - margin - signatureBlockHeight;
    double currentY = margin;

    final PdfFont headingFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      16,
      style: PdfFontStyle.bold,
    );
    final PdfFont subHeadingFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );
    final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final PdfFont boldNormalFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );

    void ensureSpace(double height) {
      if (currentY + height > contentBottomY) {
        page = document.pages.add();
        currentY = margin;
      }
    }

    // ignore: no_leading_underscores_for_local_identifiers
    double _drawField(
      PdfPage ignoredPage,
      String label,
      String? value,
      PdfFont font,
      double ignoredMargin,
      double ignoredY,
      double ignoredPageWidth,
    ) {
      if (value?.isNotEmpty ?? false) {
        final text = '$label: $value';
        final width = pageWidth - 2 * margin - 10;
        final height = _measureWrappedTextHeight(text, font, width);
        ensureSpace(height);
        currentY += _drawWrappedText(
          page,
          text,
          font,
          margin + 10,
          currentY,
          width,
        );
      }
      return currentY;
    }

    // ignore: no_leading_underscores_for_local_identifiers
    double _drawMedications(
      PdfPage ignoredPage,
      String? medicationsText,
      PdfFont ignoredNormalFont,
      PdfFont ignoredSmallFont,
      double ignoredMargin,
      double ignoredY,
      double ignoredPageWidth,
    ) {
      if (medicationsText == null || medicationsText.isEmpty) return currentY;

      final meds = MedicationSerializer.parseForPdf(medicationsText);
      for (final med in meds) {
        final name = med['name'] ?? '';
        final dose = med['dose'] ?? '';
        final ki = (med['contraindications'] ?? '').toString();
        final kiChecked = med['kiChecked'] == true;
        var line = '\u2022 $name \u2013 $dose';
        if (ki.isNotEmpty) {
          line += ' | KI: $ki';
          line += kiChecked ? ' (geprüft)' : ' (nicht geprüft)';
        }

        final width = pageWidth - 2 * margin - 20;
        final height = _measureWrappedTextHeight(line, smallFont, width);
        ensureSpace(height + 2);
        currentY += _drawWrappedText(
          page,
          line,
          smallFont,
          margin + 20,
          currentY,
          width,
        ) + 2;
      }
      return currentY;
    }

    // Titel
    final String missionNr =
        mission.missionNumber ?? mission.id.substring(0, 8);
    _drawString(page, 
      'Einsatzbericht - $missionNr',
      headingFont,
      bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 20),
    );
    currentY += 25;

    final String startTimeStr = DateFormat(
      'dd.MM.yyyy HH:mm',
    ).format(mission.startTime);
    final String endTimeStr = mission.endTime != null
        ? DateFormat('HH:mm').format(mission.endTime!)
        : 'Noch aktiv';

    _drawString(page, 
      'Einsatzzeit: $startTimeStr - $endTimeStr Uhr',
      normalFont,
      bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 15),
    );
    currentY += 20;

    // Neuester ABCDE-Datensatz (unabhängig von der Sortierung der übergebenen Liste)
    final ABCDEAssessment? latestAssessment = abcdeAssessments.isEmpty
        ? null
        : abcdeAssessments.reduce(
            (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
          );

    // Patientendaten
    ensureSpace(18);
    _drawString(page, 
      'Patientendaten',
      subHeadingFont,
      bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
    );
    currentY += 18;

    if (patient != null) {
      final nameStr =
          '${patient.firstName ?? ''} ${patient.lastName ?? ''}'.trim();
      if (nameStr.isNotEmpty) {
        ensureSpace(16);
        _drawString(page, 
          'Name: $nameStr',
          normalFont,
          bounds: Rect.fromLTWH(
            margin + 10,
            currentY,
            pageWidth - 2 * margin - 10,
            15,
          ),
        );
        currentY += 16;
      }

      if (patient.dateOfBirth != null) {
        ensureSpace(16);
        final ageStr = patient.age != null ? ' (${patient.age} Jahre)' : '';
        _drawString(page, 
          'Geburtsdatum: ${DateFormat('dd.MM.yyyy').format(patient.dateOfBirth!)}$ageStr',
          normalFont,
          bounds: Rect.fromLTWH(
            margin + 10,
            currentY,
            pageWidth - 2 * margin - 10,
            15,
          ),
        );
        currentY += 16;
      }

      if (patient.gender != null) {
        ensureSpace(16);
        const genderLabels = {
          Gender.male: 'Männlich',
          Gender.female: 'Weiblich',
          Gender.diverse: 'Divers',
          Gender.unknown: 'Unbekannt',
        };
        _drawString(page, 
          'Geschlecht: ${genderLabels[patient.gender]}',
          normalFont,
          bounds: Rect.fromLTWH(
            margin + 10,
            currentY,
            pageWidth - 2 * margin - 10,
            15,
          ),
        );
        currentY += 16;
      }

      currentY = _drawField(
        page,
        'Adresse',
        patient.address,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawField(
        page,
        'Krankenkasse',
        patient.insurance,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
    }

    currentY += 5;

    // ABCDE Assessments
    if (abcdeAssessments.isNotEmpty) {
      ensureSpace(18);
      _drawString(page, 
        'ABCDE Assessments',
        subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
      );
      currentY += 18;

      final assessment = latestAssessment!;

      // Notfallereignis
      if (assessment.eventDescription?.isNotEmpty ?? false) {
        currentY = _drawField(
          page,
          'Notfallereignis',
          assessment.eventDescription,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
      }

      // Verdachtsdiagnose
      currentY = _drawField(
        page,
        'Verdachtsdiagnose',
        assessment.suspectedDiagnosis,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );

      // c - Critical Bleeding
      if (assessment.externalBleeding) {
        final bleedingInfo = [
          assessment.bleedingLocation,
          assessment.bleedingControl,
        ].where((e) => e?.isNotEmpty ?? false).join(', ');
        currentY = _drawField(
          page,
          'Krit. Blutung',
          bleedingInfo.isNotEmpty ? bleedingInfo : 'Ja',
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
      }

      // A - Airway: Status, Problem und Maßnahmen als eine zusammenhängende
      // Zeile, damit kein leeres "Problem"-Label erscheint, wenn dort nichts
      // eingetragen wurde.
      final airwayParts = <String>[
        if (assessment.aDocumented)
          assessment.airwayThreatened ? 'bedroht' : 'frei',
        if (assessment.airwayIssue?.isNotEmpty ?? false)
          assessment.airwayIssue!,
        if (assessment.airwayIntervention?.isNotEmpty ?? false)
          assessment.airwayIntervention!,
      ];
      currentY = _drawField(
        page,
        'A',
        airwayParts.isNotEmpty ? airwayParts.join(' | ') : null,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawMedications(
        page,
        assessment.airwayMedications,
        normalFont,
        smallFont,
        margin,
        currentY,
        pageWidth,
      );

      // B - Breathing
      final breathingParts = <String>[
        if (assessment.respiratoryRate != null)
          'AF: ${assessment.respiratoryRate}/min',
        if (assessment.spo2 != null) 'SpO2: ${assessment.spo2}%',
        if (assessment.breathingSounds?.isNotEmpty ?? false)
          'Ausku.: ${assessment.breathingSounds}',
        if (!assessment.symmetricBreathing) 'Thoraxexkursion asymmetrisch',
        if (assessment.breathingIssue?.isNotEmpty ?? false)
          assessment.breathingIssue!,
        if (assessment.breathingIntervention?.isNotEmpty ?? false)
          assessment.breathingIntervention!,
      ];
      currentY = _drawField(
        page,
        'B',
        breathingParts.isNotEmpty ? breathingParts.join(' | ') : null,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawMedications(
        page,
        assessment.breathingMedications,
        normalFont,
        smallFont,
        margin,
        currentY,
        pageWidth,
      );

      // C - Circulation
      final circParts = <String>[
        if (assessment.heartRate != null) 'HF: ${assessment.heartRate}/min',
        if (assessment.systolicBP != null)
          'RR: ${assessment.systolicBP}/${assessment.diastolicBP ?? '-'} mmHg',
        if (assessment.pulseQuality?.isNotEmpty ?? false)
          'Puls: ${assessment.pulseQuality}',
        if (assessment.skinColor?.isNotEmpty ?? false)
          'Haut: ${assessment.skinColor}',
        if (assessment.capillaryRefill?.isNotEmpty ?? false)
          'KFZ: ${assessment.capillaryRefill}',
        if (assessment.circulationIssue?.isNotEmpty ?? false)
          assessment.circulationIssue!,
        if (assessment.circulationIntervention?.isNotEmpty ?? false)
          assessment.circulationIntervention!,
        if (assessment.ecgRhythm?.isNotEmpty ?? false)
          'EKG: ${assessment.ecgRhythm}',
      ];
      currentY = _drawField(
        page,
        'C',
        circParts.isNotEmpty ? circParts.join(' | ') : null,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawMedications(
        page,
        assessment.circulationMedications,
        normalFont,
        smallFont,
        margin,
        currentY,
        pageWidth,
      );

      // D - Disability
      final gcsTotal = (assessment.gcsEye ?? 0) +
          (assessment.gcsVerbal ?? 0) +
          (assessment.gcsMotor ?? 0);
      final disParts = <String>[
        if (gcsTotal > 0)
          'GCS: $gcsTotal (E${assessment.gcsEye}/V${assessment.gcsVerbal}/M${assessment.gcsMotor})',
        if (assessment.pupilSummary != null) assessment.pupilSummary!,
        if (assessment.bloodSugar != null) 'BZ: ${assessment.bloodSugar} mg/dl',
        if (assessment.befastResult?.isNotEmpty ?? false)
          'BE-FAST: ${assessment.befastResult}',
        if (assessment.disabilityIssue?.isNotEmpty ?? false)
          assessment.disabilityIssue!,
        if (assessment.disabilityIntervention?.isNotEmpty ?? false)
          assessment.disabilityIntervention!,
      ];
      currentY = _drawField(
        page,
        'D',
        disParts.isNotEmpty ? disParts.join(' | ') : null,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawMedications(
        page,
        assessment.disabilityMedications,
        normalFont,
        smallFont,
        margin,
        currentY,
        pageWidth,
      );

      // E - Exposure
      final expParts = <String>[
        if (assessment.temperature != null)
          'Temp: ${assessment.temperature!.toStringAsFixed(1)} °C',
        if (assessment.injuries?.isNotEmpty ?? false)
          'Verletz.: ${assessment.injuries}',
        if (assessment.environmentalFactors?.isNotEmpty ?? false)
          'Umgebung: ${assessment.environmentalFactors}',
        if (assessment.exposureIssue?.isNotEmpty ?? false)
          assessment.exposureIssue!,
        if (assessment.exposureIntervention?.isNotEmpty ?? false)
          assessment.exposureIntervention!,
      ];
      currentY = _drawField(
        page,
        'E',
        expParts.isNotEmpty ? expParts.join(' | ') : null,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawMedications(
        page,
        assessment.exposureMedications,
        normalFont,
        smallFont,
        margin,
        currentY,
        pageWidth,
      );

      // CPR
      if (assessment.cprShocks != null || assessment.cprROSC != null) {
        final cprInfo = [
          if (assessment.cprShocks != null) 'Schocks: ${assessment.cprShocks}',
          if (assessment.cprROSC == true) 'ROSC: Ja',
          if (assessment.cprMedications?.isNotEmpty ?? false)
            assessment.cprMedications,
        ].join(', ');
        currentY = _drawField(
          page,
          'CPR',
          cprInfo.isNotEmpty ? cprInfo : null,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        final tubusInfo = [
          if (assessment.cprTubusTypes?.isNotEmpty ?? false)
            assessment.cprTubusTypes,
          if (assessment.cprTubusSizes?.isNotEmpty ?? false)
            assessment.cprTubusSizes,
        ].join(', ');
        currentY = _drawField(
          page,
          'CPR Tubus',
          tubusInfo.isNotEmpty ? tubusInfo : null,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
      }

      // SAMPLER Schema (Anamnese, dokumentiert bei E)
      if ([
        assessment.samplerSymptoms,
        assessment.samplerAllergies,
        assessment.samplerMedications,
        assessment.samplerPastMedicalHistory,
        assessment.samplerLastOralIntake,
        assessment.samplerEvents,
        assessment.samplerRiskFactors,
      ].any((v) => v?.isNotEmpty ?? false)) {
        currentY += 5;
        ensureSpace(18);
        _drawString(page, 
          'SAMPLER Schema (Anamnese)',
          subHeadingFont,
          bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
        );
        currentY += 18;
        currentY = _drawField(
          page,
          'S - Symptome',
          assessment.samplerSymptoms,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        currentY = _drawField(
          page,
          'A - Allergien',
          assessment.samplerAllergies,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        currentY = _drawField(
          page,
          'M - Medikation',
          assessment.samplerMedications,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        currentY = _drawField(
          page,
          'P - Vorerkrankungen',
          assessment.samplerPastMedicalHistory,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        currentY = _drawField(
          page,
          'L - Letzte orale Aufnahme',
          assessment.samplerLastOralIntake,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        currentY = _drawField(
          page,
          'E - Ereignisse',
          assessment.samplerEvents,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
        currentY = _drawField(
          page,
          'R - Risikofaktoren',
          assessment.samplerRiskFactors,
          normalFont,
          margin,
          currentY,
          pageWidth,
        );
      }

      // ABC-Verlauf: Bei mehreren Erhebungen (z.B. nach "Baseline erneut
      // erheben") werden alle A/B/C-Beurteilungen chronologisch mit
      // Zeitstempel aufgeführt, damit auch frühere/korrigierte Erhebungen
      // nachvollziehbar in der Dokumentation sichtbar bleiben.
      if (abcdeAssessments.length > 1) {
        final history = [...abcdeAssessments]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        currentY += 5;
        ensureSpace(18);
        _drawString(
          page,
          'ABC-Verlauf (Baseline-Erhebungen)',
          subHeadingFont,
          bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
        );
        currentY += 18;

        for (final entry in history) {
          final timeLabel = DateFormat('HH:mm').format(entry.timestamp);
          final isLatest = entry.id == assessment.id;
          ensureSpace(15);
          _drawString(
            page,
            '$timeLabel Uhr${isLatest ? ' (aktuell)' : ''}',
            boldNormalFont,
            bounds: Rect.fromLTWH(
              margin + 5,
              currentY,
              pageWidth - 2 * margin - 5,
              14,
            ),
          );
          currentY += 15;

          if (entry.aDocumented) {
            currentY = _drawField(
              page,
              'A',
              entry.airwayThreatened ? 'bedroht' : 'frei',
              normalFont,
              margin,
              currentY,
              pageWidth,
            );
          }
          final historyBreathingParts = <String>[
            if (entry.respiratoryRate != null)
              'AF: ${entry.respiratoryRate}/min',
            if (entry.spo2 != null) 'SpO2: ${entry.spo2}%',
            if (entry.breathingSounds?.isNotEmpty ?? false)
              'Ausku.: ${entry.breathingSounds}',
            if (!entry.symmetricBreathing) 'Thoraxexkursion asymmetrisch',
          ];
          currentY = _drawField(
            page,
            'B',
            historyBreathingParts.isNotEmpty
                ? historyBreathingParts.join(' | ')
                : null,
            normalFont,
            margin,
            currentY,
            pageWidth,
          );
          final historyCircParts = <String>[
            if (entry.heartRate != null) 'HF: ${entry.heartRate}/min',
            if (entry.systolicBP != null)
              'RR: ${entry.systolicBP}/${entry.diastolicBP ?? '-'} mmHg',
            if (entry.pulseQuality?.isNotEmpty ?? false)
              'Puls: ${entry.pulseQuality}',
            if (entry.skinColor?.isNotEmpty ?? false)
              'Haut: ${entry.skinColor}',
            if (entry.capillaryRefill?.isNotEmpty ?? false)
              'KFZ: ${entry.capillaryRefill}',
          ];
          currentY = _drawField(
            page,
            'C',
            historyCircParts.isNotEmpty ? historyCircParts.join(' | ') : null,
            normalFont,
            margin,
            currentY,
            pageWidth,
          );
          currentY += 4;
        }
      }
    }

    // Messwerttabelle (Vitalparameter)
    if (vitalSigns.isNotEmpty) {
      currentY += 5;
      ensureSpace(18);
      _drawString(page, 
        'Vitalparameter',
        subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
      );
      currentY += 18;

      final double tableWidth = pageWidth - 2 * margin;
      const int colCount = 8;
      final double colWidth = tableWidth / colCount;
      final List<String> headers = [
        'Zeit',
        'HF',
        'RR sys.',
        'RR dia.',
        'AF',
        'SpO2',
        'BZ',
        'Temp',
      ];
      double colX = margin;

      // Header-Zeile
      ensureSpace(16);
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(230, 230, 230)),
        pen: PdfPen(PdfColor(0, 0, 0), width: 1),
        bounds: Rect.fromLTWH(margin, currentY, tableWidth, 16),
      );

      for (int i = 0; i < headers.length; i++) {
        _drawString(page, 
          headers[i],
          smallFont,
          bounds: Rect.fromLTWH(colX + 2, currentY + 3, colWidth - 4, 12),
        );
        colX += colWidth;
      }
      currentY += 16;

      // Chronologisch sortieren: ältester Wert zuerst
      final sortedVitals = List<VitalSigns>.from(vitalSigns)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final int maxRows = 10;
      for (int i = 0; i < sortedVitals.length && i < maxRows; i++) {
        ensureSpace(14);
        final vital = sortedVitals[i];
        final String timeStr = DateFormat('HH:mm').format(vital.timestamp);

        colX = margin;
        page.graphics.drawRectangle(
          pen: PdfPen(PdfColor(200, 200, 200), width: 0.5),
          bounds: Rect.fromLTWH(margin, currentY, tableWidth, 14),
        );

        final List<String> values = [
          timeStr,
          '${vital.heartRate ?? '-'}',
          '${vital.systolicBP ?? '-'}',
          '${vital.diastolicBP ?? '-'}',
          '${vital.respiratoryRate ?? '-'}',
          '${vital.spo2 ?? '-'}',
          '${vital.bloodSugar ?? '-'}',
          '${vital.temperature ?? '-'}',
        ];

        for (int j = 0; j < values.length; j++) {
          _drawString(page, 
            values[j],
            smallFont,
            bounds: Rect.fromLTWH(colX + 2, currentY + 1, colWidth - 4, 12),
          );
          colX += colWidth;
        }

        currentY += 14;
      }
      currentY += 8;
    }

    // Freitextfeld aus E - Situation vor Ort / Einsatzablauf
    if (latestAssessment?.situationNotes?.isNotEmpty ?? false) {
      currentY += 4;
      ensureSpace(16);
      _drawString(page, 
        'Situation vor Ort / Einsatzablauf:',
        subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
      );
      currentY += 16;
      // Mehrzeiligen Text zeichnen
      final double availW = pageWidth - 2 * margin - 10;
      final double textHeight = _measureWrappedTextHeight(
        latestAssessment!.situationNotes!,
        normalFont,
        availW,
      );
      ensureSpace(textHeight + 8);
      final double textH = _drawWrappedText(
        page,
        latestAssessment!.situationNotes!,
        normalFont,
        margin + 10,
        currentY,
        availW,
      );
      currentY += textH + 8;
    }

    // ISBAR - Einschätzung & Empfehlung
    if (isbar != null &&
        ((isbar.assessment?.isNotEmpty ?? false) ||
            (isbar.recommendation?.isNotEmpty ?? false))) {
      currentY += 5;
      ensureSpace(18);
      _drawString(page, 
        'ISBAR - Einschätzung & Empfehlung',
        subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
      );
      currentY += 18;
      currentY = _drawField(
        page,
        'A - Assessment',
        isbar.assessment,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
      currentY = _drawField(
        page,
        'R - Recommendation',
        isbar.recommendation,
        normalFont,
        margin,
        currentY,
        pageWidth,
      );
    }

    // Massnahmen
    if (measures.isNotEmpty) {
      // Chronologisch: älteste zuerst
      final sortedMeasures = List<Measure>.from(measures)
        ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

      currentY += 5;
      ensureSpace(18);
      _drawString(page, 
        'Massnahmen',
        subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14),
      );
      currentY += 18;

      for (final measure in sortedMeasures.take(10)) {
        final String timeStr = DateFormat('HH:mm').format(measure.performedAt);
        final String label = measure.displayName;
        final String notesPart =
            (measure.notes?.isNotEmpty ?? false) ? ' - ${measure.notes}' : '';
        final String text = '\u2022 $timeStr: $label$notesPart';
        final double width = pageWidth - 2 * margin - 10;
        final double height = _measureWrappedTextHeight(
          text,
          normalFont,
          width,
        );
        ensureSpace(height + 2);
        final double lineHeight = _drawWrappedText(
          page,
          text,
          normalFont,
          margin + 10,
          currentY,
          width,
        );
        currentY += lineHeight + 2;
      }
    }

    // ==================== UNTERSCHRIFTSBEREICH ====================
    final double bottomY = pageHeight - margin - signatureBlockHeight;

    // Trennlinie
    page.graphics.drawLine(
      PdfPen(PdfColor(180, 180, 180), width: 0.5),
      Offset(margin, bottomY),
      Offset(pageWidth - margin, bottomY),
    );

    // ---- LINKS: Sanitäter Name ----
    const double leftBlockWidth = 200;
    final double leftX = margin;

    if (userInfo != null) {
      _drawString(page, 
        userInfo.fullName,
        normalFont,
        bounds: Rect.fromLTWH(leftX, bottomY + 58, leftBlockWidth, 14),
      );
    }

    // ---- RECHTS: Empfänger / Übergabe ----
    const double rightBlockWidth = 200;
    final double rightX = pageWidth - margin - rightBlockWidth;

    // Unterschriftslinie Empfänger
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      Offset(rightX, bottomY + 60),
      Offset(rightX + rightBlockWidth, bottomY + 60),
    );

    if (userInfo != null && userInfo.shortSign.isNotEmpty) {
      _drawString(page, 
        userInfo.shortSign,
        normalFont,
        bounds: Rect.fromLTWH(rightX, bottomY + 65, rightBlockWidth, 14),
      );
    }

    final List<int> bytes = document.saveSync();
    document.dispose();

    return Uint8List.fromList(bytes);
  }

  /// Generiert PDF und öffnet Druckdialog
  static Future<void> exportMissionToPDF({
    required Mission mission,
    required Patient? patient,
    required List<ABCDEAssessment> abcdeAssessments,
    required List<VitalSigns> vitalSigns,
    required List<Measure> measures,
    required UserInfo? userInfo,
    ISBARHandover? isbar,
  }) async {
    final pdfBytes = await generatePdfBytes(
      mission: mission,
      patient: patient,
      abcdeAssessments: abcdeAssessments,
      vitalSigns: vitalSigns,
      measures: measures,
      userInfo: userInfo,
      isbar: isbar,
    );

    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  /// Zeichen außerhalb von Windows-1252, die sinnvoll ersetzt werden können.
  static const Map<int, String> _pdfCharReplacements = {
    0x2080: '0', 0x2081: '1', 0x2082: '2', 0x2083: '3', 0x2084: '4',
    0x2085: '5', 0x2086: '6', 0x2087: '7', 0x2088: '8', 0x2089: '9',
    0x2070: '0', 0x2074: '4', 0x2075: '5', 0x2076: '6', 0x2077: '7',
    0x2078: '8', 0x2079: '9',
    0x2010: '-', 0x2011: '-', 0x2012: '-', 0x2212: '-',
    0x2264: '<=', 0x2265: '>=', 0x2260: '!=', 0x2248: '~',
    0x2190: '<-', 0x2192: '->', 0x2194: '<->', 0x21D2: '=>',
    0x2191: '^', 0x2193: 'v',
    0x2713: 'x', 0x2714: 'x', 0x2715: '-', 0x2717: '-', 0x2718: '-',
    0x2103: '°C', 0x2116: 'Nr.',
    0x200B: '', 0x200C: '', 0x200D: '', 0xFEFF: '', 0xFE0F: '',
  };

  /// Zusätzliche (>= 256) Zeichen, die Windows-1252 bzw. PdfStandardFont kennt.
  static const String _cp1252Extras =
      '€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ';

  /// PdfStandardFont (Helvetica) unterstützt nur Windows-1252. Andere Zeichen
  /// (z.B. „₂“, „✓“, Emojis) führen in Syncfusion zu einem RangeError.
  static String _pdfSafe(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune < 256 || _cp1252Extras.contains(String.fromCharCode(rune))) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(_pdfCharReplacements[rune] ?? '?');
      }
    }
    return buffer.toString();
  }

  static void _drawString(
    PdfPage page,
    String text,
    PdfFont font, {
    required Rect bounds,
    PdfStringFormat? format,
  }) {
    page.graphics.drawString(
      _pdfSafe(text),
      font,
      bounds: bounds,
      format: format,
    );
  }

  static double _drawWrappedText(
    PdfPage page,
    String text,
    PdfFont font,
    double x,
    double y,
    double width,
  ) {
    final format = PdfStringFormat(wordWrap: PdfWordWrapType.word);
    final double height = _measureWrappedTextHeight(text, font, width);

    _drawString(page, 
      text,
      font,
      bounds: Rect.fromLTWH(x, y, width, height),
      format: format,
    );
    return height;
  }

  static double _measureWrappedTextHeight(
    String text,
    PdfFont font,
    double width,
  ) {
    final safeText = _pdfSafe(text);
    final format = PdfStringFormat(wordWrap: PdfWordWrapType.word);
    final textSize = font.measureString(
      safeText,
      layoutArea: Size(width, 10000),
      format: format,
    );
    return textSize.height > 0 ? textSize.height + 2 : 14;
  }
}
