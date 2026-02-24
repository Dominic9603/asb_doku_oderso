import 'dart:convert';
import 'dart:io';

void main() async {
  final token = Platform.environment['GITHUB_TOKEN'] ?? '';
  const releaseId = 289595964;
  const apkPath = r'C:\Users\Administrator\rescue_doc\build\app\outputs\flutter-apk\app-release.apk';
  const repo = 'Dominic9603/asb_doku_oderso';

  final client = HttpClient();

  // 1. Bestehende Assets laden und löschen
  print('Lade Asset-Liste...');
  final assetsReq = await client.getUrl(
    Uri.parse('https://api.github.com/repos/$repo/releases/$releaseId/assets'),
  );
  assetsReq.headers.set('Authorization', 'Bearer $token');
  assetsReq.headers.set('Accept', 'application/vnd.github+json');
  assetsReq.headers.set('User-Agent', 'RescueDoc-Deploy');
  final assetsResp = await assetsReq.close();
  final assetsBody = await assetsResp.transform(utf8.decoder).join();
  final assets = jsonDecode(assetsBody) as List;

  for (final asset in assets) {
    print('Lösche: ${asset['name']} (id=${asset['id']})');
    final delReq = await client.deleteUrl(
      Uri.parse('https://api.github.com/repos/$repo/releases/assets/${asset['id']}'),
    );
    delReq.headers.set('Authorization', 'Bearer $token');
    delReq.headers.set('Accept', 'application/vnd.github+json');
    delReq.headers.set('User-Agent', 'RescueDoc-Deploy');
    final delResp = await delReq.close();
    await delResp.drain();
    print('  Status: ${delResp.statusCode}');
  }

  // 2. APK hochladen
  final apkFile = File(apkPath);
  final apkBytes = await apkFile.readAsBytes();
  print('Lade APK hoch (${(apkBytes.length / 1024 / 1024).toStringAsFixed(1)} MB)...');

  final uploadUri = Uri.parse(
    'https://uploads.github.com/repos/$repo/releases/$releaseId/assets?name=rescue_doc.apk',
  );
  final uploadReq = await client.postUrl(uploadUri);
  uploadReq.headers.set('Authorization', 'Bearer $token');
  uploadReq.headers.set('Accept', 'application/vnd.github+json');
  uploadReq.headers.set('Content-Type', 'application/octet-stream');
  uploadReq.headers.set('Content-Length', apkBytes.length.toString());
  uploadReq.headers.set('User-Agent', 'RescueDoc-Deploy');
  uploadReq.headers.set('X-GitHub-Api-Version', '2022-11-28');
  uploadReq.add(apkBytes);

  final uploadResp = await uploadReq.close();
  final uploadBody = await uploadResp.transform(utf8.decoder).join();
  final uploadResult = jsonDecode(uploadBody) as Map;

  if (uploadResp.statusCode == 201) {
    print('✅ Upload erfolgreich: ${uploadResult['browser_download_url']}');
  } else {
    print('❌ Fehler ${uploadResp.statusCode}: $uploadBody');
  }

  client.close();
}
