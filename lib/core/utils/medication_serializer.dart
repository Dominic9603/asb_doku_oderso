import 'dart:convert';

/// Hilfsfunktionen zur Serialisierung / Deserialisierung von Medikamenten
/// in den ABCDE-Assessment-Feldern (airwayMedications, breathingMedications, usw.)
///
/// Neues Format: JSON-Array [{name, dose, contraindications, kiChecked}]
/// Rückwärtskompatibel zum alten Format: name:dose|name:dose
class MedicationSerializer {
  /// Serialisiert Liste von Medikamenten-Maps zu JSON-String
  static String serialize(List<Map<String, dynamic>> medications) {
    if (medications.isEmpty) return '';
    final data = medications.map((m) => {
      'name': m['name'] ?? '',
      'dose': m['dose'] ?? '',
      'contraindications': m['contraindications'] ?? '',
      'kiChecked': m['kiChecked'] ?? false,
    }).toList();
    return jsonEncode(data);
  }

  /// Deserialisiert String zu Liste von Medikamenten-Maps.
  /// Unterstützt altes Format (name:dose|name:dose) und neues JSON-Format.
  static List<Map<String, dynamic>> deserialize(String? text) {
    if (text == null || text.isEmpty) return [];

    // Neues JSON-Format erkennen
    if (text.trimLeft().startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(text);
        return decoded.map<Map<String, dynamic>>((item) => {
          'name': item['name'] ?? '',
          'dose': item['dose'] ?? '',
          'contraindications': item['contraindications'] ?? '',
          'kiChecked': item['kiChecked'] ?? false,
        }).toList();
      } catch (_) {
        // Fallback auf altes Format
      }
    }

    // Altes Format: name:dose|name:dose
    final result = <Map<String, dynamic>>[];
    final meds = text.split('|');
    for (final med in meds) {
      final parts = med.split(':');
      if (parts.length >= 2) {
        result.add({
          'name': parts[0],
          'dose': parts[1],
          'contraindications': '',
          'kiChecked': false,
        });
      }
    }
    return result;
  }

  /// Parst Medikamenten-String für PDF-Anzeige.
  /// Gibt Liste von Maps mit name, dose, contraindications, kiChecked zurück.
  static List<Map<String, dynamic>> parseForPdf(String? text) {
    return deserialize(text);
  }
}
