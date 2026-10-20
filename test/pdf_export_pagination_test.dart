import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:rescue_doc/core/services/pdf_export_service.dart';
import 'package:rescue_doc/features/documentation/models/measure.dart';
import 'package:rescue_doc/features/documentation/models/mission.dart';

void main() {
  test('starts a new page before content reaches the signature area', () async {
    final now = DateTime.now();
    final bytes = await PDFExportService.generatePdfBytes(
      mission: Mission(
        id: '12345678-aaaa',
        startTime: now,
        status: MissionStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
      patient: null,
      abcdeAssessments: const [],
      vitalSigns: const [],
      measures: List.generate(
        10,
        (index) => Measure(
          id: '$index',
          missionId: 'mission',
          measureType: MeasureType.oxygenTherapy,
          performedAt: now.add(Duration(minutes: index)),
          notes: List.filled(35, 'Dokumentation der Maßnahme').join(' '),
        ),
      ),
      userInfo: null,
    );
    final document = PdfDocument(inputBytes: bytes);

    expect(document.pages.count, greaterThan(1));
    expect(PdfTextExtractor(document).extractText(), contains('Dokumentation'));

    document.dispose();
  });
}
