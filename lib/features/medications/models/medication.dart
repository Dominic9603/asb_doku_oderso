class Medication {
  final String id;

  // ALT-kompatible Felder
  final String name;           // = Handelsname
  final String? adultDose;     // optionale Standard-Erwachsenendosis
  final String? childDose;     // optionale Standard-Kinderdosis

  // NEUE Felder
  final String activeIngredient;
  final String? indications;
  final String? contraindications;
  final String? applicationRoute;
  final String? dosage;        // detaillierter Dosierungstext
  final String? category;
  final String? notes;
  final String? sectionsCsv; // z.B. "B", "C", "B,C"

  Medication({
    required this.id,
    required this.name,
    required this.activeIngredient,
    this.adultDose,
    this.childDose,
    this.indications,
    this.contraindications,
    this.applicationRoute,
    this.dosage,
    this.category,
    this.notes,
    this.sectionsCsv,
  });

  // für alte Aufrufer, die nur name + Dosen setzen
  factory Medication.simple({
    required String id,
    required String name,
    String? adultDose,
    String? childDose,
    String? category,
  }) {
    return Medication(
      id: id,
      name: name,
      activeIngredient: name, // Notlösung, bis du echte Wirkstoffe pflegst
      adultDose: adultDose,
      childDose: childDose,
      category: category,
    );
  }

  bool appliesToSection(String section) {
  if (sectionsCsv == null || sectionsCsv!.isEmpty) return true;
  final parts = sectionsCsv!
      .split(',')
      .map((e) => e.trim().toUpperCase())
      .where((e) => e.isNotEmpty);
  return parts.contains(section.toUpperCase());
}

  Medication copyWith({
    String? id,
    String? name,
    String? activeIngredient,
    String? adultDose,
    String? childDose,
    String? indications,
    String? contraindications,
    String? applicationRoute,
    String? dosage,
    String? category,
    String? notes,
    String? sectionsCsv,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      adultDose: adultDose ?? this.adultDose,
      childDose: childDose ?? this.childDose,
      indications: indications ?? this.indications,
      contraindications: contraindications ?? this.contraindications,
      applicationRoute: applicationRoute ?? this.applicationRoute,
      dosage: dosage ?? this.dosage,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      sectionsCsv: sectionsCsv ?? this.sectionsCsv,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trade_name': name,
      'active_ingredient': activeIngredient,
      'adult_dose': adultDose,
      'child_dose': childDose,
      'indications': indications,
      'contraindications': contraindications,
      'application_route': applicationRoute,
      'dosage': dosage,
      'category': category,
      'notes': notes,
      'sections_csv': sectionsCsv,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['trade_name'] as String,
      activeIngredient: map['active_ingredient'] as String,
      adultDose: map['adult_dose'] as String?,
      childDose: map['child_dose'] as String?,
      indications: map['indications'] as String?,
      contraindications: map['contraindications'] as String?,
      applicationRoute: map['application_route'] as String?,
      dosage: map['dosage'] as String?,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      sectionsCsv: map['sections_csv'] as String?,
    );
  }
  
}

