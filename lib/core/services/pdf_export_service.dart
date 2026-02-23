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
  }) async {
    print('📋 PDF Export - userInfo: $userInfo');
    print('📋 PDF Export - shortSign: "${userInfo?.shortSign}"');
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 0;
    final PdfPage page = document.pages.add();

    const double pageWidth = 595;
    const double pageHeight = 842;
    const double margin = 20;
    double currentY = margin;

    final PdfFont headingFont =
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final PdfFont subHeadingFont =
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    // Titel
    final String missionNr = mission.missionNumber ?? mission.id.substring(0, 8);
    page.graphics.drawString('Einsatzbericht - $missionNr', headingFont,
      bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 20));
    currentY += 25;

    final String startTimeStr = DateFormat('dd.MM.yyyy HH:mm').format(mission.startTime);
    final String endTimeStr = mission.endTime != null
        ? DateFormat('HH:mm').format(mission.endTime!)
        : 'Noch aktiv';
    
    page.graphics.drawString('Einsatzzeit: $startTimeStr - $endTimeStr Uhr', normalFont,
      bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 15));
    currentY += 20;

    // Patientendaten
    page.graphics.drawString('Patientendaten', subHeadingFont,
      bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14));
    currentY += 18;

    if (patient != null) {
      final nameStr = '${patient.firstName ?? ''} ${patient.lastName ?? ''}'.trim();
      if (nameStr.isNotEmpty) {
        page.graphics.drawString('Name: $nameStr', normalFont,
          bounds: Rect.fromLTWH(margin + 10, currentY, pageWidth - 2 * margin - 10, 15));
        currentY += 16;
      }

      if (patient.dateOfBirth != null) {
        page.graphics.drawString(
          'Geburtsdatum: ${DateFormat('dd.MM.yyyy').format(patient.dateOfBirth!)}',
          normalFont,
          bounds: Rect.fromLTWH(margin + 10, currentY, pageWidth - 2 * margin - 10, 15));
        currentY += 16;
      }

      if (patient.symptoms?.isNotEmpty ?? false) {
        page.graphics.drawString('Symptome: ${patient.symptoms}', normalFont,
          bounds: Rect.fromLTWH(margin + 10, currentY, pageWidth - 2 * margin - 10, 15));
        currentY += 16;
      }

      if (patient.allergies?.isNotEmpty ?? false) {
        page.graphics.drawString('Allergien: ${patient.allergies}', normalFont,
          bounds: Rect.fromLTWH(margin + 10, currentY, pageWidth - 2 * margin - 10, 15));
        currentY += 16;
      }
    }
    
    currentY += 5;

    // Vitale Zeichen
    if (vitalSigns.isNotEmpty) {
      page.graphics.drawString('Vitalparameter', subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14));
      currentY += 18;

      final double tableWidth = pageWidth - 2 * margin;
      const int colCount = 8;
      final double colWidth = tableWidth / colCount;
      final List<String> headers = ['Zeit', 'HF', 'RR sys.', 'RR dia.', 'AF', 'SpO2', 'BZ', 'Temp'];
      double colX = margin;

      // Header-Zeile
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(230, 230, 230)),
        pen: PdfPen(PdfColor(0, 0, 0), width: 1),
        bounds: Rect.fromLTWH(margin, currentY, tableWidth, 16));

      for (int i = 0; i < headers.length; i++) {
        page.graphics.drawString(headers[i], smallFont,
          bounds: Rect.fromLTWH(colX + 2, currentY + 3, colWidth - 4, 12));
        colX += colWidth;
      }
      currentY += 16;

      // Chronologisch sortieren: ältester Wert zuerst
      final sortedVitals = List<VitalSigns>.from(vitalSigns)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final int maxRows = 10;
      for (int i = 0; i < sortedVitals.length && i < maxRows; i++) {
        final vital = sortedVitals[i];
        final String timeStr = DateFormat('HH:mm').format(vital.timestamp);

        colX = margin;
        page.graphics.drawRectangle(
          pen: PdfPen(PdfColor(200, 200, 200), width: 0.5),
          bounds: Rect.fromLTWH(margin, currentY, tableWidth, 14));

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
          page.graphics.drawString(values[j], smallFont,
            bounds: Rect.fromLTWH(colX + 2, currentY + 1, colWidth - 4, 12));
          colX += colWidth;
        }

        currentY += 14;
      }
      currentY += 8;
    }

    // ABCDE Assessments
    if (abcdeAssessments.isNotEmpty) {
      page.graphics.drawString('ABCDE Assessments', subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14));
      currentY += 18;

      final assessment = abcdeAssessments.last;

      // c - Critical Bleeding
      if (assessment.externalBleeding) {
        final bleedingInfo = [assessment.bleedingLocation, assessment.bleedingControl]
            .where((e) => e?.isNotEmpty ?? false).join(', ');
        currentY = _drawField(page, 'Krit. Blutung', bleedingInfo.isNotEmpty ? bleedingInfo : 'Ja', normalFont, margin, currentY, pageWidth);
      }

      // A - Airway
      currentY = _drawField(page, 'Atemweg', assessment.airwayIssue, normalFont, margin, currentY, pageWidth);
      currentY = _drawField(page, 'Atemweg Maßn.', assessment.airwayIntervention, normalFont, margin, currentY, pageWidth);
      currentY = _drawMedications(page, assessment.airwayMedications, normalFont, smallFont, margin, currentY, pageWidth);

      // B - Breathing
      final breathingInfo = [
        if (assessment.respiratoryRate != null) 'AF: ${assessment.respiratoryRate}',
        if (assessment.spo2 != null) 'SpO₂: ${assessment.spo2}%',
        if (assessment.breathingIssue?.isNotEmpty ?? false) assessment.breathingIssue,
      ].join(', ');
      currentY = _drawField(page, 'Atmung', breathingInfo.isNotEmpty ? breathingInfo : null, normalFont, margin, currentY, pageWidth);
      currentY = _drawMedications(page, assessment.breathingMedications, normalFont, smallFont, margin, currentY, pageWidth);

      // C - Circulation
      final circInfo = [
        if (assessment.heartRate != null) 'HF: ${assessment.heartRate}',
        if (assessment.systolicBP != null) 'RR: ${assessment.systolicBP}/${assessment.diastolicBP ?? '-'}',
        if (assessment.circulationIssue?.isNotEmpty ?? false) assessment.circulationIssue,
      ].join(', ');
      currentY = _drawField(page, 'Zirkulation', circInfo.isNotEmpty ? circInfo : null, normalFont, margin, currentY, pageWidth);
      currentY = _drawMedications(page, assessment.circulationMedications, normalFont, smallFont, margin, currentY, pageWidth);

      // D - Disability
      final gcsTotal = (assessment.gcsEye ?? 0) + (assessment.gcsVerbal ?? 0) + (assessment.gcsMotor ?? 0);
      final disInfo = [
        if (gcsTotal > 0) 'GCS: $gcsTotal',
        if (assessment.bloodSugar != null) 'BZ: ${assessment.bloodSugar}',
        if (assessment.disabilityIssue?.isNotEmpty ?? false) assessment.disabilityIssue,
      ].join(', ');
      currentY = _drawField(page, 'Neurologie', disInfo.isNotEmpty ? disInfo : null, normalFont, margin, currentY, pageWidth);
      currentY = _drawMedications(page, assessment.disabilityMedications, normalFont, smallFont, margin, currentY, pageWidth);

      // E - Exposure
      currentY = _drawField(page, 'Exposition', assessment.exposureIssue, normalFont, margin, currentY, pageWidth);
      currentY = _drawField(page, 'Verletzungen', assessment.injuries, normalFont, margin, currentY, pageWidth);
      currentY = _drawMedications(page, assessment.exposureMedications, normalFont, smallFont, margin, currentY, pageWidth);

      // CPR
      if (assessment.cprShocks != null || assessment.cprROSC != null) {
        final cprInfo = [
          if (assessment.cprShocks != null) 'Schocks: ${assessment.cprShocks}',
          if (assessment.cprROSC == true) 'ROSC: Ja',
          if (assessment.cprMedications?.isNotEmpty ?? false) assessment.cprMedications,
        ].join(', ');
        currentY = _drawField(page, 'CPR', cprInfo.isNotEmpty ? cprInfo : null, normalFont, margin, currentY, pageWidth);
      }
    }

    // Massnahmen
    if (measures.isNotEmpty) {
      // Chronologisch: älteste zuerst
      final sortedMeasures = List<Measure>.from(measures)
        ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

      currentY += 5;
      page.graphics.drawString('Massnahmen', subHeadingFont,
        bounds: Rect.fromLTWH(margin, currentY, pageWidth - 2 * margin, 14));
      currentY += 18;

      for (final measure in sortedMeasures.take(10)) {
        final String timeStr = DateFormat('HH:mm').format(measure.performedAt);
        final String label = measure.displayName;
        final String notesPart = (measure.notes?.isNotEmpty ?? false) ? ' - ${measure.notes}' : '';
        page.graphics.drawString('\u2022 $timeStr: $label$notesPart', normalFont,
          bounds: Rect.fromLTWH(margin + 10, currentY, pageWidth - 2 * margin - 10, 12));
        currentY += 14;
      }
    }

    // ==================== UNTERSCHRIFTSBEREICH ====================
    const double signatureBlockHeight = 90;
    final double bottomY = pageHeight - margin - signatureBlockHeight;

    // Trennlinie
    page.graphics.drawLine(
      PdfPen(PdfColor(180, 180, 180), width: 0.5),
      Offset(margin, bottomY),
      Offset(pageWidth - margin, bottomY));

    // ---- LINKS: Sanitäter Name ----
    const double leftBlockWidth = 200;
    final double leftX = margin;

    if (userInfo != null) {
      page.graphics.drawString(userInfo.fullName, normalFont,
        bounds: Rect.fromLTWH(leftX, bottomY + 58, leftBlockWidth, 14));
    }

    // ---- RECHTS: Empfänger / Übergabe ----
    const double rightBlockWidth = 200;
    final double rightX = pageWidth - margin - rightBlockWidth;

    // Unterschriftslinie Empfänger
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0), width: 1),
      Offset(rightX, bottomY + 60),
      Offset(rightX + rightBlockWidth, bottomY + 60));

    if (userInfo != null && userInfo.shortSign.isNotEmpty) {
      page.graphics.drawString(userInfo.shortSign, normalFont,
        bounds: Rect.fromLTWH(rightX, bottomY + 65, rightBlockWidth, 14));
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
  }) async {
    final pdfBytes = await generatePdfBytes(
      mission: mission,
      patient: patient,
      abcdeAssessments: abcdeAssessments,
      vitalSigns: vitalSigns,
      measures: measures,
      userInfo: userInfo,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
    );
  }

  static double _drawField(PdfPage page, String label, String? value,
      PdfFont font, double margin, double currentY, double pageWidth) {
    if (value?.isNotEmpty ?? false) {
      page.graphics.drawString('$label: $value', font,
        bounds: Rect.fromLTWH(margin + 10, currentY, pageWidth - 2 * margin - 10, 12));
      return currentY + 14;
    }
    return currentY;
  }

  /// Zeichnet Medikamenten-Auflistung mit Kontraindikationen im PDF
  static double _drawMedications(PdfPage page, String? medicationsText,
      PdfFont normalFont, PdfFont smallFont, double margin, double currentY, double pageWidth) {
    if (medicationsText == null || medicationsText.isEmpty) return currentY;

    final meds = MedicationSerializer.parseForPdf(medicationsText);
    if (meds.isEmpty) return currentY;

    for (final med in meds) {
      final name = med['name'] ?? '';
      final dose = med['dose'] ?? '';
      final ki = (med['contraindications'] ?? '').toString();
      final kiChecked = med['kiChecked'] == true;

      // Medikament + Dosis
      String line = '\u2022 $name \u2013 $dose';
      if (ki.isNotEmpty) {
        line += ' | KI: $ki';
        line += kiChecked ? ' \u2713' : ' \u2717';
      }

      // Mehrzeilig zeichnen falls Text zu lang
      final double availableWidth = pageWidth - 2 * margin - 20;
      final textSize = smallFont.measureString(line, layoutArea: Size(availableWidth, 0));
      final double lineHeight = textSize.height > 0 ? textSize.height + 4 : 12;

      page.graphics.drawString(line, smallFont,
        bounds: Rect.fromLTWH(margin + 20, currentY, availableWidth, lineHeight + 4));
      currentY += lineHeight + 2;
    }
    return currentY;
  }
}
