import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service zum direkten Teilen einer PDF per share_plus.
/// Kein Cloud-Backend nötig – öffnet den nativen Teilen-Dialog.
class PdfShareService {
  PdfShareService._();

  /// Speichert PDF-Bytes temporär und öffnet den Teilen-Dialog.
  /// Der Nutzer kann direkt Email, WhatsApp, etc. wählen.
  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String missionNumber,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'Einsatzbericht_${missionNumber}_$timestamp.pdf';

    // Temporäre Datei schreiben
    final tempDir = await getTemporaryDirectory();
    final file = File('\${tempDir.path}/\$fileName');
    await file.writeAsBytes(pdfBytes);

    // Nativen Teilen-Dialog öffnen
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Einsatzbericht - \$missionNumber',
      text: 'Einsatzbericht \$missionNumber\n\nGesendet aus RescueDoc',
    );
  }
}
