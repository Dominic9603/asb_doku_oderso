import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../authentication/models/user_info.dart';

/// Service zum Hochladen einer PDF in Supabase Storage
/// und Versenden eines zeitlich begrenzten Download-Links per Email.
class PdfShareService {
  PdfShareService._();

  /// Lädt PDF-Bytes in Supabase Storage hoch und gibt eine
  /// signierte URL zurück, die nach [AppConfig.linkExpirySeconds] abläuft.
  static Future<String> uploadAndGetLink(
    Uint8List pdfBytes,
    String missionNumber,
  ) async {
    final supabase = Supabase.instance.client;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'einsatz_${missionNumber}_$timestamp.pdf';

    // PDF in Bucket hochladen
    await supabase.storage
        .from(AppConfig.storageBucket)
        .uploadBinary(
          fileName,
          pdfBytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    // Signierte URL erstellen (30 Minuten gültig)
    final signedUrl = await supabase.storage
        .from(AppConfig.storageBucket)
        .createSignedUrl(fileName, AppConfig.linkExpirySeconds);

    return signedUrl;
  }

  /// Öffnet den Email-Client mit dem Download-Link.
  /// Die Empfänger-Adresse wird aus [UserInfo.recipientEmail] gelesen.
  static Future<void> sendEmailWithLink({
    required String downloadUrl,
    required String missionNumber,
    required String recipientEmail,
  }) async {
    final subject = Uri.encodeComponent(
      'Einsatzbericht - $missionNumber',
    );

    final expiryMinutes = AppConfig.linkExpirySeconds ~/ 60;

    final body = Uri.encodeComponent(
      'Einsatzbericht $missionNumber\n\n'
      'Der PDF-Bericht kann über folgenden Link heruntergeladen werden:\n\n'
      '$downloadUrl\n\n'
      '⚠️ Dieser Link ist nur $expiryMinutes Minuten gültig.\n\n'
      'Gesendet aus RescueDoc',
    );

    final mailtoUri = Uri.parse(
      'mailto:$recipientEmail?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri);
    } else {
      throw Exception('Email-Client konnte nicht geöffnet werden');
    }
  }

  /// Komplett-Workflow: Upload → Signed URL → Email öffnen
  static Future<String> uploadAndSendEmail({
    required Uint8List pdfBytes,
    required String missionNumber,
    required String recipientEmail,
  }) async {
    final url = await uploadAndGetLink(pdfBytes, missionNumber);
    await sendEmailWithLink(
      downloadUrl: url,
      missionNumber: missionNumber,
      recipientEmail: recipientEmail,
    );
    return url;
  }
}
