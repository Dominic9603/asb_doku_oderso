/// RescueDoc – Seriennummern-Generator
///
/// Verwendung:
///   dart run tools/generate_keys.dart [anzahl]
///
/// Erzeugt eine keys.json mit der gewünschten Anzahl gültiger Seriennummern.
/// Die Datei kann dann als Secret Gist auf GitHub hochgeladen werden.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main(List<String> args) {
  final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 10 : 10;

  print('🔑 RescueDoc Key-Generator');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Generiere $count Seriennummern...\n');

  final keys = <String>[];
  final usedKeys = <String>{};

  for (var i = 0; i < count; i++) {
    String key;
    do {
      key = _generateKey();
    } while (usedKeys.contains(key));
    usedKeys.add(key);
    keys.add(key);
    print('  ${i + 1}. $key');
  }

  // JSON-Datei schreiben
  final output = {
    'generated_at': DateTime.now().toIso8601String(),
    'count': keys.length,
    'keys': keys,
  };

  final jsonString = const JsonEncoder.withIndent('  ').convert(output);
  final file = File('tools/keys.json');
  file.writeAsStringSync(jsonString);

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ ${keys.length} Keys in tools/keys.json gespeichert');
  print('');
  print('Nächste Schritte:');
  print('  1. Gehe zu https://gist.github.com');
  print('  2. Erstelle ein neues "Secret Gist"');
  print('  3. Dateiname: keys.json');
  print('  4. Inhalt: Kopiere den Inhalt von tools/keys.json');
  print('  5. Klicke auf "Create secret gist"');
  print('  6. Klicke auf "Raw" um die Raw-URL zu kopieren');
  print('  7. Trage die URL in lib/core/constants/app_constants.dart ein:');
  print('     static const String keysUrl = \'https://gist.githubusercontent.com/...\';');
}

/// Generiert einen zufälligen Key im Format XXXX-XXXX-XXXX-XXXX
String _generateKey() {
  final random = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // ohne I/O/0/1 (Verwechslungsgefahr)

  String randomPart(int length) {
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  final part1 = randomPart(4);
  final part2 = randomPart(4);
  final part3 = randomPart(4);
  final part4 = randomPart(4);

  return '$part1-$part2-$part3-$part4';
}
