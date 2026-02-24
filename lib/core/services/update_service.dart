import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Enthält Informationen über ein verfügbares Update.
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
  });
}

/// Service für automatische Update-Prüfung und -Installation.
/// Funktioniert nur auf Android (nicht auf Web).
class UpdateService {
  static const _owner = 'Dominic9603';
  static const _repo = 'asb_doku_oderso';
  static const _apkName = 'RescueDoc.apk';

  /// Prüft ob ein neueres Release auf GitHub vorhanden ist.
  /// Gibt [UpdateInfo] zurück wenn Update verfügbar, sonst null.
  Future<UpdateInfo?> checkForUpdate() async {
    // Nur auf Android verfügbar
    if (kIsWeb) return null;
    if (!Platform.isAndroid) return null;

    try {
      // Aktuelle installierte Version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Neueste Version von GitHub Releases API holen
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_owner/$_repo/releases/latest',
            ),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'RescueDoc-App/$currentVersion',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName =
          (data['tag_name'] as String? ?? '').replaceFirst('v', '');

      if (tagName.isEmpty || !_isNewer(tagName, currentVersion)) return null;

      // APK-Download-URL aus den Release-Assets extrahieren
      final assets = (data['assets'] as List<dynamic>? ?? []);
      String? downloadUrl;
      for (final raw in assets) {
        final asset = raw as Map<String, dynamic>;
        if (asset['name'] == _apkName) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (downloadUrl == null) return null;

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: tagName,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint('Update-Check fehlgeschlagen: $e');
      return null;
    }
  }

  /// Vergleicht zwei Versionstrings (SemVer, z.B. "1.0.1" vs "1.0.0").
  /// Gibt true zurück wenn [latest] > [current].
  bool _isNewer(String latest, String current) {
    try {
      List<int> parse(String v) =>
          v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final l = parse(latest);
      final c = parse(current);
      final len = l.length > c.length ? l.length : c.length;
      for (int i = 0; i < len; i++) {
        final lv = i < l.length ? l[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Lädt die APK herunter und gibt den lokalen Dateipfad zurück.
  /// [onProgress] wird mit Werten von 0.0 bis 1.0 aufgerufen.
  Future<String> downloadApk(
    String url,
    void Function(double progress) onProgress,
  ) async {
    // Externe App-Verzeichnis bevorzugen (für FileProvider zugänglich)
    Directory dir;
    try {
      dir = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }

    final apkPath = '${dir.path}/RescueDoc_update.apk';
    final file = File(apkPath);

    // Ggf. alte Datei löschen
    if (await file.exists()) await file.delete();

    // HTTP-Client mit Redirect-Unterstützung
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await client
          .send(request)
          .timeout(const Duration(minutes: 10));

      if (response.statusCode != 200) {
        throw Exception('Server-Fehler: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? -1;
      int received = 0;

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }

    // Prüfen ob die Datei wirklich vorhanden und nicht leer ist
    final fileSize = await file.length();
    if (fileSize < 1024) {
      throw Exception(
          'Heruntergeladene Datei zu klein ($fileSize Bytes) – möglicherweise Redirect-Problem.');
    }

    return apkPath;
  }

  /// Öffnet den Android-Paketinstaller für die heruntergeladene APK.
  Future<void> installApk(String apkPath) async {
    final result = await OpenFile.open(
      apkPath,
      type: 'application/vnd.android.package-archive',
    );
    // Fehler aus dem open_file-Result auswerten
    if (result.type != ResultType.done) {
      throw Exception('Installer-Fehler: ${result.message}');
    }
  }
}
