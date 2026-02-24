import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

/// Service zum direkten Teilen einer PDF per share_plus.
/// Auf Web: XFile.fromData() (kein Dateisystem-Zugriff).
/// Auf Nativ: temporäre Datei schreiben, dann teilen.
class PdfShareService {
  PdfShareService._();

  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String missionNumber,
  }) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'Einsatzbericht_${missionNumber}_$timestamp.pdf';

    if (kIsWeb) {
      // Web: direkter Browser-Download (funktioniert auf allen Desktop- und Mobile-Browsern)
      await triggerWebDownload(pdfBytes, fileName);
    } else {
      // Nativ: temporäre Datei schreiben, dann teilen
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Einsatzbericht - $missionNumber',
        text: 'Einsatzbericht $missionNumber\n\nGesendet aus RescueDoc',
      );
    }
  }
}
