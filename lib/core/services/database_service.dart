import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rescue_doc/features/medications/models/medication.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  sqflite.Database? _database;
  bool _isWeb = false;

  bool get isWeb => _isWeb;

  sqflite.Database? get database {
    if (_database == null) {
      if (!_isWeb) {
        throw Exception('Database not initialized. Call initialize() first.');
      }
      // Web: _database bleibt null, Operationen werden abgefangen
    }
    return _database;
  }

  Future<void> initialize() async {
    // Prüfe ob Web (kIsWeb ist compile-time constant, kein dart:io nötig)
    _isWeb = kIsWeb;

    if (_isWeb) {
      print('⚠️ Web-Plattform erkannt - Verwende In-Memory Storage');
      // Keine echte DB auf Web
      await _seedDefaultMedicationsWeb();
      return;
    }

    try {
      final databasePath = await sqflite.getDatabasesPath();
      final path = '$databasePath/rescue_doc.db';

      _database = await sqflite.openDatabase(
        path,
        version: 9,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('❌ Datenbankinitialisierung fehlgeschlagen: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Missions
    await db.execute('''
      CREATE TABLE missions (
        id TEXT PRIMARY KEY,
        mission_number TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        status TEXT NOT NULL,
        created_by TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Patients
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        date_of_birth INTEGER,
        gender TEXT,
        address TEXT,
        insurance TEXT,
        symptoms TEXT,
        allergies TEXT,
        medications TEXT,
        past_medical_history TEXT,
        last_oral_intake TEXT,
        events_leading_to_illness TEXT,
        risk_factors TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions (id) ON DELETE CASCADE
      )
    ''');

    // cABCDE
    await db.execute('''
      CREATE TABLE abcde_assessments (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        external_bleeding INTEGER DEFAULT 0,
        bleeding_location TEXT,
        bleeding_control TEXT,
        airway_patent INTEGER DEFAULT 1,
        airway_threatened INTEGER DEFAULT 0,
        airway_issue TEXT,
        airway_intervention TEXT,
        airway_medications TEXT,
        respiratory_rate INTEGER,
        spo2 REAL,
        breathing_sounds TEXT,
        symmetric_breathing INTEGER DEFAULT 1,
        breathing_issue TEXT,
        breathing_intervention TEXT,
        breathing_medications TEXT,
        heart_rate INTEGER,
        systolic_bp INTEGER,
        diastolic_bp INTEGER,
        pulse_quality TEXT,
        skin_color TEXT,
        capillary_refill TEXT,
        circulation_issue TEXT,
        circulation_intervention TEXT,
        circulation_medications TEXT,
        gcs_eye INTEGER,
        gcs_verbal INTEGER,
        gcs_motor INTEGER,
        pupil_left TEXT,
        pupil_right TEXT,
        blood_sugar REAL,
        befast_result TEXT,
        disability_issue TEXT,
        disability_intervention TEXT,
        disability_medications TEXT,
        temperature REAL,
        injuries TEXT,
        environmental_factors TEXT,
        exposure_issue TEXT,
        exposure_intervention TEXT,
        exposure_medications TEXT,
        situation_notes TEXT,
        suspected_diagnosis TEXT,
        ecg_rhythm TEXT,
        a_documented INTEGER DEFAULT 0,
        event_description TEXT,
        cpr_tubus_types TEXT,
        cpr_tubus_sizes TEXT,
        cpr_shocks INTEGER,
        cpr_rosc INTEGER DEFAULT 0,
        cpr_medications TEXT,
        sampler_symptoms TEXT,
        sampler_allergies TEXT,
        sampler_medications TEXT,
        sampler_past_medical_history TEXT,
        sampler_last_oral_intake TEXT,
        sampler_events TEXT,
        sampler_risk_factors TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions (id) ON DELETE CASCADE
      )
    ''');

    // Vital Signs (Legacy)
    await db.execute('''
      CREATE TABLE vital_signs (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        heart_rate INTEGER,
        systolic_bp INTEGER,
        diastolic_bp INTEGER,
        respiratory_rate INTEGER,
        spo2 REAL,
        temperature REAL,
        gcs INTEGER,
        blood_sugar REAL,
        ecg_rhythm TEXT,
        left_pupil TEXT,
        right_pupil TEXT,
        notes TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions (id) ON DELETE CASCADE
      )
    ''');

    // Measures
    await db.execute('''
      CREATE TABLE measures (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        measure_type TEXT NOT NULL,
        performed_at INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions (id) ON DELETE CASCADE
      )
    ''');

    // Medication Administrations
    await db.execute('''
      CREATE TABLE medication_administrations (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        medication_id TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        route TEXT NOT NULL,
        administered_at INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions (id) ON DELETE CASCADE
      )
    ''');

    // ISBAR
    await db.execute('''
      CREATE TABLE isbar_handovers (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL UNIQUE,
        identification TEXT,
        situation TEXT,
        background TEXT,
        assessment TEXT,
        recommendation TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions (id) ON DELETE CASCADE
      )
    ''');

    // Medications master table
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        trade_name TEXT NOT NULL,
        active_ingredient TEXT NOT NULL,
        adult_dose TEXT,
        child_dose TEXT,
        indications TEXT,
        contraindications TEXT,
        application_route TEXT,
        dosage TEXT,
        category TEXT,
        notes TEXT,
        sections_csv TEXT
      )
    ''');

    // Indexe
    await db.execute(
      'CREATE INDEX idx_missions_start_time ON missions(start_time)',
    );
    await db.execute(
      'CREATE INDEX idx_patients_mission ON patients(mission_id)',
    );
    await db.execute(
      'CREATE INDEX idx_abcde_mission ON abcde_assessments(mission_id)',
    );
    await db.execute(
      'CREATE INDEX idx_abcde_timestamp ON abcde_assessments(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_vital_signs_mission ON vital_signs(mission_id)',
    );
    await db.execute(
      'CREATE INDEX idx_vital_signs_timestamp ON vital_signs(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_measures_mission ON measures(mission_id)',
    );
    await db.execute(
      'CREATE INDEX idx_measures_performed ON measures(performed_at)',
    );
    await db.execute(
      'CREATE INDEX idx_medications_name ON medications(trade_name)',
    );

    await _seedDefaultMedications(db);
  }

  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('📦 Database migration: v$oldVersion -> v$newVersion');

    // Migration v1 -> v2: event_description Spalte hinzufügen
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN event_description TEXT',
        );
        print('✅ Migration v2: event_description Spalte hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v2: event_description - $e');
      }
    }

    // Migration v2 -> v3: CPR-Spalten hinzufügen
    if (oldVersion < 3) {
      print('🔄 Starte Migration v3: CPR-Spalten...');
      try {
        print('  → Füge cpr_tubus_types hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN cpr_tubus_types TEXT',
        );

        print('  → Füge cpr_tubus_sizes hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN cpr_tubus_sizes TEXT',
        );

        print('  → Füge cpr_shocks hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN cpr_shocks INTEGER',
        );

        print('  → Füge cpr_rosc hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN cpr_rosc INTEGER DEFAULT 0',
        );

        print('  → Füge cpr_medications hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN cpr_medications TEXT',
        );

        print('✅ Migration v3: Alle CPR-Spalten erfolgreich hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v3: CPR-Spalten - $e');
      }
    }

    // Migration v3 -> v4: airway_medications Spalte hinzufügen
    if (oldVersion < 4) {
      print('🔄 Starte Migration v4: Airway Medikamente...');
      try {
        print('  → Füge airway_medications hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN airway_medications TEXT',
        );
        print(
          '✅ Migration v4: airway_medications Spalte erfolgreich hinzugefügt',
        );
      } catch (e) {
        print('⚠️ Migration v4: airway_medications - $e');
      }
    }

    // Migration v4 -> v5: Medikamentenspalten für B, C, D, E hinzufügen
    if (oldVersion < 5) {
      print('🔄 Starte Migration v5: B/C/D/E Medikamente...');
      try {
        print('  → Füge breathing_medications hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN breathing_medications TEXT',
        );

        print('  → Füge circulation_medications hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN circulation_medications TEXT',
        );

        print('  → Füge disability_medications hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN disability_medications TEXT',
        );

        print('  → Füge exposure_medications hinzu...');
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN exposure_medications TEXT',
        );

        print(
          '✅ Migration v5: Alle B/C/D/E Medikamenten-Spalten erfolgreich hinzugefügt',
        );
      } catch (e) {
        print('⚠️ Migration v5: B/C/D/E Medikamente - $e');
      }
    }

    // Migration v5 -> v6: BEFAST-Spalte hinzufügen
    if (oldVersion < 6) {
      print('🔄 Starte Migration v6: BEFAST...');
      try {
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN befast_result TEXT',
        );
        print('✅ Migration v6: befast_result Spalte erfolgreich hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v6: befast_result - $e');
      }
    }

    // Migration v6 -> v7: situation_notes Spalte hinzufügen
    if (oldVersion < 7) {
      print('🔄 Starte Migration v7: Situation Notes...');
      try {
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN situation_notes TEXT',
        );
        print('✅ Migration v7: situation_notes Spalte erfolgreich hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v7: situation_notes - $e');
      }
    }

    // Migration v7 -> v8: suspected_diagnosis Spalte hinzufügen
    if (oldVersion < 8) {
      print('🔄 Starte Migration v8: Verdachtsdiagnose...');
      try {
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN suspected_diagnosis TEXT',
        );
        print(
          '✅ Migration v8: suspected_diagnosis Spalte erfolgreich hinzugefügt',
        );
      } catch (e) {
        print('⚠️ Migration v8: suspected_diagnosis - $e');
      }
    }

    // Migration v8 -> v9: SAMPLER-Schema von Patient zu E (ABCDE) verschieben
    if (oldVersion < 9) {
      print('🔄 Starte Migration v9: SAMPLER zu E verschieben...');
      try {
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_symptoms TEXT',
        );
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_allergies TEXT',
        );
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_medications TEXT',
        );
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_past_medical_history TEXT',
        );
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_last_oral_intake TEXT',
        );
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_events TEXT',
        );
        await db.execute(
          'ALTER TABLE abcde_assessments ADD COLUMN sampler_risk_factors TEXT',
        );
        await _migrateSamplerFromPatients(db);
        print(
          '✅ Migration v9: SAMPLER-Spalten hinzugefügt und Altdaten übernommen',
        );
      } catch (e) {
        print('⚠️ Migration v9: SAMPLER - $e');
      }

      try {
        await _seedDefaultMedications(db);
      } catch (e) {
        print('⚠️ Migration v9: Grundmedikamente seeden - $e');
      }
    }
  }

  /// Übernimmt vorhandene SAMPLER-Daten aus der patients-Tabelle in den
  /// jeweils neuesten (oder neu erzeugten) abcde_assessments-Datensatz der Mission.
  Future<void> _migrateSamplerFromPatients(sqflite.Database db) async {
    final patients = await db.query('patients');
    for (final patient in patients) {
      final samplerValues = {
        'sampler_symptoms': patient['symptoms'],
        'sampler_allergies': patient['allergies'],
        'sampler_medications': patient['medications'],
        'sampler_past_medical_history': patient['past_medical_history'],
        'sampler_last_oral_intake': patient['last_oral_intake'],
        'sampler_events': patient['events_leading_to_illness'],
        'sampler_risk_factors': patient['risk_factors'],
      };
      final hasData = samplerValues.values.any(
        (v) => v != null && (v as String).isNotEmpty,
      );
      if (!hasData) continue;

      final missionId = patient['mission_id'] as String;
      final existing = await db.query(
        'abcde_assessments',
        where: 'mission_id = ?',
        whereArgs: [missionId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await db.update(
          'abcde_assessments',
          samplerValues,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('abcde_assessments', {
          'id': const Uuid().v4(),
          'mission_id': missionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...samplerValues,
        });
      }
    }
  }

  /// Basis-Medikamentendatenbank, die bei jeder Neuinstallation für alle
  /// App-Nutzer angelegt wird. Optionale Schlüssel je Eintrag:
  /// 'dosage' (allgemeiner Dosierungstext), 'adultDose', 'childDose',
  /// 'indications', 'contraindications', 'applicationRoute', 'sectionsCsv'
  /// (z.B. 'A,B,C'). Hier eingetragene Standardwerte gelten für alle
  /// Nutzer, deren App-Datenbank noch nicht existiert bzw. den Eintrag
  /// (per Name) noch nicht enthält – bereits vorhandene Einträge werden
  /// nicht überschrieben.
  static const List<Map<String, String>> _defaultMedicationSeed = [
    {
      'name': 'Acetylsalicylsäure',
      'activeIngredient': 'Acetylsalicylsäure',
      'category': 'Thrombozytenaggregationshemmer',
      'applicationRoute': 'i.v.',
      'dosage': '250 - 500 mg i.v. (alternativ 500 mg Granulat oral)',
      'indications': 'akutes Koronarsyndrom',
    },
    {
      'name': 'Amiodaron',
      'activeIngredient': 'Amiodaron',
      'category': 'Antiarrhythmikum',
      'applicationRoute': 'i.v.',
      'dosage':
          'Reanimation 300 mg i.v. nach 3. Defibrillation, ggf. 150 mg nach 5. Defibrillation; Tachykardie 300 mg i.v. als Kurzinfusion',
      'indications':
          'Reanimation (Kammerflimmern/pulslose VT) / tachykarde Herzrhythmusstörung',
    },
    {
      'name': 'Atropin',
      'activeIngredient': 'Atropinsulfat',
      'category': 'Parasympatholytikum',
      'applicationRoute': 'i.v.',
      'dosage':
          'initial 0,5 mg i.v. (max. 3 mg); bei Alkylphosphat-Intoxikation deutlich höher dosiert',
      'indications': 'symptomatische Bradykardie / Alkylphosphat-Intoxikation',
    },
    {
      'name': 'Butylscopolamin',
      'activeIngredient': 'Butylscopolamin',
      'category': 'Spasmolytikum',
      'applicationRoute': 'i.v.',
      'dosage': '20 - 40 mg i.v. (max. 100 mg)',
      'indications': 'kolikartige Bauchschmerzen',
    },
    {
      'name': 'Epinephrin',
      'activeIngredient': 'Epinephrin',
      'category': 'Notfallmedikament / Vasopressor',
      'applicationRoute': 'i.v. / i.m. / inhalativ',
      'dosage':
          'Reanimation 1 mg i.v.; Anaphylaxie 0,5 mg i.m.; Bradykardie titriert i.v.',
      'indications': 'Reanimation / Anaphylaxie / bedrohliche Bradykardie',
    },
    {
      'name': 'Fentanyl',
      'activeIngredient': 'Fentanyl',
      'category': 'Opioid-Analgetikum',
      'applicationRoute': 'i.v. / i.n.',
      'dosage': 'initial ca. 50 µg i.v., titriert nach Wirkung',
      'indications': 'Analgesie / Narkose',
    },
    {
      'name': 'Furosemid',
      'activeIngredient': 'Furosemid',
      'category': 'Diuretikum',
      'applicationRoute': 'i.v.',
      'dosage': 'initial 20 mg i.v., ggf. Steigerung',
      'indications': 'kardiales Lungenödem / akute Herzinsuffizienz',
    },
    {
      'name': 'Glukose',
      'activeIngredient': 'Glucose',
      'category': 'Notfallmedikament',
      'applicationRoute': 'i.v.',
      'dosage': '8 - 16 g i.v. (über laufenden Zugang)',
      'indications': 'Hypoglykämie',
    },
    {
      'name': 'Glyceroltrinitrat',
      'activeIngredient': 'Glyceroltrinitrat',
      'category': 'Vasodilatator',
      'applicationRoute': 's.l.',
      'dosage': '0,4 - 0,8 mg sublingual, bei Lungenödem auch höher dosiert',
      'indications': 'akutes Koronarsyndrom / kardiales Lungenödem',
    },
    {
      'name': 'Heparin',
      'activeIngredient': 'Heparin',
      'category': 'Antikoagulans',
      'applicationRoute': 'i.v.',
      'dosage': '5.000 IE i.v. (ACS), höher dosiert bei Lungenarterienembolie',
      'indications': 'akutes Koronarsyndrom / Lungenarterienembolie',
    },
    {
      'name': 'Ibuprofen',
      'activeIngredient': 'Ibuprofen',
      'category': 'Analgetikum',
      'applicationRoute': 'rektal',
      'dosage': 'gewichtsadaptiert, v.a. bei Kindern (ca. 10 mg/kgKG rektal)',
      'indications': 'Analgesie / Fieber',
    },
    {
      'name': 'Metamizol',
      'activeIngredient': 'Metamizol',
      'category': 'Analgetikum',
      'applicationRoute': 'i.v.',
      'dosage': '1 g i.v. langsam bzw. als Kurzinfusion',
      'indications': 'kolikartige Schmerzen / Fieber',
    },
    {
      'name': 'Metoclopramid',
      'activeIngredient': 'Metoclopramid',
      'category': 'Antiemetikum',
      'applicationRoute': 'i.v.',
      'dosage': '10 mg i.v.',
      'indications': 'Übelkeit & Erbrechen',
    },
    {
      'name': 'Midazolam',
      'activeIngredient': 'Midazolam',
      'category': 'Benzodiazepin (Sedativum)',
      'applicationRoute': 'i.v. / i.n. / i.m.',
      'dosage':
          'Status epilepticus ca. 10 mg i.n./i.m./i.v.; Analgosedierung niedriger dosiert',
      'indications': 'Status epilepticus / Analgosedierung / Erregungszustand',
    },
    {
      'name': 'Morphin',
      'activeIngredient': 'Morphin',
      'category': 'Opioid-Analgetikum',
      'applicationRoute': 'i.v.',
      'dosage': 'fraktioniert 2 mg i.v. bis zur Wirkung (max. 10 mg)',
      'indications': 'Analgesie',
    },
    {
      'name': 'Naloxon',
      'activeIngredient': 'Naloxon',
      'category': 'Antidot',
      'applicationRoute': 'i.v. / i.m. / i.n.',
      'dosage': 'fraktioniert 0,4 mg i.v., alternativ i.m./i.n.',
      'indications': 'Opioid-Intoxikation',
    },
    {
      'name': 'Norepinephrin',
      'activeIngredient': 'Noradrenalin',
      'category': 'Vasopressor',
      'applicationRoute': 'i.v.',
      'dosage': 'titriert i.v. (Push-Dose bzw. Perfusor)',
      'indications': 'Schock / therapieresistente Hypotonie',
    },
    {
      'name': 'Ondansetron',
      'activeIngredient': 'Ondansetron',
      'category': 'Antiemetikum',
      'applicationRoute': 'i.v.',
      'dosage': '4 mg i.v.',
      'indications': 'Übelkeit & Erbrechen',
    },
    {
      'name': 'Paracetamol',
      'activeIngredient': 'Paracetamol',
      'category': 'Analgetikum',
      'applicationRoute': 'i.v. / rektal',
      'dosage': '1 g i.v. (bei Kindern gewichtsadaptiert)',
      'indications': 'Analgesie / Fieber',
    },
    {
      'name': 'Prednisolon',
      'activeIngredient': 'Prednisolon',
      'category': 'Kortikosteroid',
      'applicationRoute': 'i.v.',
      'dosage': '50 - 100 mg i.v., bei Anaphylaxie bis 250 mg i.v.',
      'indications': 'obstruktive Atemwegserkrankung / Anaphylaxie',
    },
    {
      'name': 'Salbutamol',
      'activeIngredient': 'Salbutamol',
      'category': 'Beta-2-Sympathomimetikum',
      'applicationRoute': 'inhalativ',
      'dosage': '2,5 - 5 mg inhalativ',
      'indications': 'Asthma bronchiale / COPD / Anaphylaxie',
    },
    {
      'name': 'Urapidil',
      'activeIngredient': 'Urapidil',
      'category': 'Antihypertensivum',
      'applicationRoute': 'i.v.',
      'dosage': 'schrittweise titriert 10 mg i.v. (max. 50 mg)',
      'indications': 'hypertensiver Notfall',
    },
    {
      'name': 'Adenosin',
      'activeIngredient': 'Adenosin',
      'category': 'Antiarrhythmikum',
      'applicationRoute': 'i.v.',
      'dosage': 'initial 6 mg i.v. schnell, ggf. 12 mg, ggf. 18 mg',
      'indications': 'paroxysmale supraventrikuläre Tachykardie',
    },
    {
      'name': 'Clemastin',
      'activeIngredient': 'Clemastin',
      'category': 'Antihistaminikum',
      'applicationRoute': 'i.v.',
      'dosage': '2 mg i.v.',
      'indications': 'Anaphylaxie / allergische Reaktion',
    },
    {
      'name': 'Diazepam',
      'activeIngredient': 'Diazepam',
      'category': 'Benzodiazepin',
      'applicationRoute': 'i.v.',
      'dosage': '5 - 10 mg i.v. langsam',
      'indications': 'Status epilepticus / Fieberkrampf',
    },
    {
      'name': 'Dimenhydrinat',
      'activeIngredient': 'Dimenhydrinat',
      'category': 'Antiemetikum',
      'applicationRoute': 'i.v.',
      'dosage': '62 mg i.v.',
      'indications': 'Übelkeit & Erbrechen',
    },
    {
      'name': 'Dimetinden',
      'activeIngredient': 'Dimetinden',
      'category': 'Antihistaminikum',
      'applicationRoute': 'i.v.',
      'dosage': '4 mg i.v.',
      'indications': 'Anaphylaxie / allergische Reaktion',
    },
    {
      'name': 'Droperidol',
      'activeIngredient': 'Droperidol',
      'category': 'Antiemetikum',
      'applicationRoute': 'i.v.',
      'dosage': '0,625 - 1,25 mg i.v.',
      'indications': 'Übelkeit & Erbrechen',
    },
    {
      'name': 'Esketamin',
      'activeIngredient': 'Esketamin',
      'category': 'Anästhetikum',
      'applicationRoute': 'i.v.',
      'dosage': '0,125 - 0,25 mg/kgKG i.v. (Analgesie)',
      'indications': 'Analgesie / Narkoseeinleitung',
    },
    {
      'name': 'Fenoterol',
      'activeIngredient': 'Fenoterol',
      'category': 'Beta-2-Sympathomimetikum',
      'applicationRoute': 'inhalativ',
      'dosage': '1 Sprühstoß (0,1 mg) inhalativ',
      'indications': 'Asthma bronchiale / COPD',
    },
    {
      'name': 'Flumazenil',
      'activeIngredient': 'Flumazenil',
      'category': 'Antidot',
      'applicationRoute': 'i.v.',
      'dosage': 'initial 0,2 mg i.v., titrieren bis max. 1 mg',
      'indications': 'Benzodiazepin-Intoxikation',
    },
    {
      'name': 'Granisetron',
      'activeIngredient': 'Granisetron',
      'category': 'Antiemetikum',
      'applicationRoute': 'i.v.',
      'dosage': '1 mg i.v.',
      'indications': 'Übelkeit & Erbrechen',
    },
    {
      'name': 'Ipratropiumbromid',
      'activeIngredient': 'Ipratropiumbromid',
      'category': 'Anticholinergikum',
      'applicationRoute': 'inhalativ',
      'dosage': '0,25 - 0,5 mg inhalativ',
      'indications': 'Asthma bronchiale / COPD / Anaphylaxie',
    },
    {
      'name': 'Lidocain',
      'activeIngredient': 'Lidocain',
      'category': 'Antiarrhythmikum',
      'applicationRoute': 'i.v.',
      'dosage': '100 mg i.v. (nach 3. Defibrillation)',
      'indications': 'Reanimation / Tachykardie',
    },
    {
      'name': 'Lorazepam',
      'activeIngredient': 'Lorazepam',
      'category': 'Benzodiazepin',
      'applicationRoute': 'i.v.',
      'dosage': '4 mg i.v. (max. 8 mg)',
      'indications': 'Status epilepticus / Erregungszustand',
    },
    {
      'name': 'Magnesiumsulfat',
      'activeIngredient': 'Magnesiumsulfat',
      'category': 'Antiarrhythmikum / Elektrolyt',
      'applicationRoute': 'i.v.',
      'dosage': '2 g i.v. als Kurzinfusion',
      'indications': 'Torsade de Pointes / schwerer Asthmaanfall',
    },
    {
      'name': 'Metoprolol',
      'activeIngredient': 'Metoprolol',
      'category': 'Betablocker',
      'applicationRoute': 'i.v.',
      'dosage': '5 mg i.v., Wiederholung bis max. 15 mg',
      'indications': 'tachykarde Herzrhythmusstörungen',
    },
    {
      'name': 'Nalbuphin',
      'activeIngredient': 'Nalbuphin',
      'category': 'Opioid-Analgetikum',
      'applicationRoute': 'i.v.',
      'dosage': '10 - 20 mg i.v. / i.m.',
      'indications': 'Analgesie',
    },
    {
      'name': 'Nifedipin',
      'activeIngredient': 'Nifedipin',
      'category': 'Kalzium-Antagonist',
      'applicationRoute': 'oral',
      'dosage': '10 mg oral (Kapsel zerbeißen)',
      'indications': 'hypertensiver Notfall',
    },
    {
      'name': 'Oxytocin',
      'activeIngredient': 'Oxytocin',
      'category': 'Hormon',
      'applicationRoute': 'i.v.',
      'dosage': '3 - 5 IE i.v. als Kurzinfusion',
      'indications': 'atonische Nachgeburtsblutung',
    },
    {
      'name': 'Piritramid',
      'activeIngredient': 'Piritramid',
      'category': 'Opioid-Analgetikum',
      'applicationRoute': 'i.v.',
      'dosage': '7,5 - 15 mg i.v.',
      'indications': 'Analgesie',
    },
    {
      'name': 'Propofol',
      'activeIngredient': 'Propofol',
      'category': 'Hypnotikum / Anästhetikum',
      'applicationRoute': 'i.v.',
      'dosage': '1,5 - 2,5 mg/kgKG i.v. titriert',
      'indications': 'Narkoseeinleitung (RSI)',
    },
    {
      'name': 'Reproterol',
      'activeIngredient': 'Reproterol',
      'category': 'Beta-2-Sympathomimetikum',
      'applicationRoute': 'i.v.',
      'dosage': '0,09 mg i.v.',
      'indications': 'Asthma bronchiale / COPD / Anaphylaxie',
    },
    {
      'name': 'Rocuronium',
      'activeIngredient': 'Rocuronium',
      'category': 'Muskelrelaxans',
      'applicationRoute': 'i.v.',
      'dosage': '1 mg/kgKG i.v.',
      'indications': 'Narkose (RSI)',
    },
    {
      'name': 'Sufentanil',
      'activeIngredient': 'Sufentanil',
      'category': 'Opioid-Analgetikum',
      'applicationRoute': 'i.v.',
      'dosage': 'initial 5 µg i.v. (max. 20 µg)',
      'indications': 'Analgesie / Narkose',
    },
    {
      'name': 'Suxamethonium',
      'activeIngredient': 'Succinylcholin',
      'category': 'Muskelrelaxans',
      'applicationRoute': 'i.v.',
      'dosage': '1 - 1,5 mg/kgKG i.v.',
      'indications': 'Narkose (RSI)',
    },
    {
      'name': 'Theodrenalin-Cafedrin',
      'activeIngredient': 'Cafedrin/Theodrenalin',
      'category': 'Sympathomimetikum',
      'applicationRoute': 'i.v.',
      'dosage': '1 Ampulle verdünnt, initial 1 ml i.v.',
      'indications': 'Hypotonie / orthostatische Dysregulation',
    },
    {
      'name': 'Thiamin',
      'activeIngredient': 'Thiamin (Vitamin B1)',
      'category': 'Vitamin',
      'applicationRoute': 'i.v.',
      'dosage': '100 mg i.v.',
      'indications': 'Verdacht auf Thiaminmangel vor Glukosegabe',
    },
    {
      'name': 'Tranexamsäure',
      'activeIngredient': 'Tranexamsäure',
      'category': 'Antifibrinolytikum',
      'applicationRoute': 'i.v.',
      'dosage': '1 g i.v. als Kurzinfusion',
      'indications': 'lebensbedrohliche Blutung (Polytrauma)',
    },
  ];

  /// Fügt die Grundmedikamenten-Datenbank ein, ohne bereits vorhandene
  /// (namensgleiche) Einträge zu überschreiben.
  Future<void> _seedDefaultMedications(sqflite.Database db) async {
    for (final entry in _defaultMedicationSeed) {
      final existing = await db.query(
        'medications',
        where: 'trade_name = ?',
        whereArgs: [entry['name']],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      final medication = Medication(
        id: const Uuid().v4(),
        name: entry['name']!,
        activeIngredient: entry['activeIngredient']!,
        category: entry['category'],
        dosage: entry['dosage'],
        adultDose: entry['adultDose'],
        childDose: entry['childDose'],
        indications: entry['indications'],
        contraindications: entry['contraindications'],
        applicationRoute: entry['applicationRoute'],
        sectionsCsv: entry['sectionsCsv'],
      );
      await db.insert('medications', medication.toMap());
    }
  }

  /// Web-Variante der Grundmedikamenten-Datenbank (In-Memory).
  Future<void> _seedDefaultMedicationsWeb() async {
    final existingNames = _webTables['medications']!
        .map((m) => (m['trade_name'] as String?)?.toLowerCase())
        .toSet();
    for (final entry in _defaultMedicationSeed) {
      if (existingNames.contains(entry['name']!.toLowerCase())) continue;
      final medication = Medication(
        id: const Uuid().v4(),
        name: entry['name']!,
        activeIngredient: entry['activeIngredient']!,
        category: entry['category'],
        dosage: entry['dosage'],
        adultDose: entry['adultDose'],
        childDose: entry['childDose'],
        indications: entry['indications'],
        contraindications: entry['contraindications'],
        applicationRoute: entry['applicationRoute'],
        sectionsCsv: entry['sectionsCsv'],
      );
      _webTables['medications']!.add(medication.toMap());
    }
  }

  Future<void> close() async {
    if (!_isWeb) {
      await _database?.close();
      _database = null;
    }
  }

  // Web-Fallback In-Memory Storage
  final Map<String, List<Map<String, dynamic>>> _webTables = {
    'medications': [],
    'missions': [],
    'patients': [],
    'abcde_assessments': [],
    'isbar_handovers': [],
    'vital_signs': [],
    'measures': [],
  };

  // ── Generische CRUD-Methoden (Web In-Memory + Native SQLite) ──

  Future<void> dbInsert(String table, Map<String, dynamic> values) async {
    if (_isWeb) {
      final list = _webTables[table];
      if (list != null) {
        final id = values['id'];
        if (id != null) {
          final idx = list.indexWhere((r) => r['id'] == id);
          if (idx >= 0) {
            list[idx] = Map<String, dynamic>.from(values);
          } else {
            list.add(Map<String, dynamic>.from(values));
          }
        } else {
          list.add(Map<String, dynamic>.from(values));
        }
      }
      return;
    }
    await _database?.insert(
      table,
      values,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> dbQuery(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    if (_isWeb) {
      var rows = List<Map<String, dynamic>>.from(_webTables[table] ?? []);
      if (where != null && whereArgs != null) {
        rows = _filterWebRows(rows, where, whereArgs);
      }
      if (orderBy != null) {
        rows = _sortWebRows(rows, orderBy);
      }
      return rows;
    }
    return await _database?.query(
          table,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
        ) ??
        [];
  }

  Future<void> dbDelete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (_isWeb) {
      final list = _webTables[table];
      if (list != null && where != null && whereArgs != null) {
        _webTables[table] =
            list.where((r) => !_matchesWhere(r, where, whereArgs)).toList();
      }
      return;
    }
    await _database?.delete(table, where: where, whereArgs: whereArgs);
  }

  List<Map<String, dynamic>> _filterWebRows(
    List<Map<String, dynamic>> rows,
    String where,
    List<Object?> whereArgs,
  ) {
    final parts = where.trim().split(
          RegExp(r'\s+AND\s+', caseSensitive: false),
        );
    var filtered = rows;
    int argIndex = 0;
    for (final part in parts) {
      final match = RegExp(r'(\w+)\s*=\s*\?').firstMatch(part.trim());
      if (match != null && argIndex < whereArgs.length) {
        final field = match.group(1)!;
        final value = whereArgs[argIndex++];
        filtered = filtered
            .where((r) => r[field]?.toString() == value?.toString())
            .toList();
      }
    }
    return filtered;
  }

  bool _matchesWhere(
    Map<String, dynamic> row,
    String where,
    List<Object?> whereArgs,
  ) {
    final parts = where.trim().split(
          RegExp(r'\s+AND\s+', caseSensitive: false),
        );
    int argIndex = 0;
    for (final part in parts) {
      final match = RegExp(r'(\w+)\s*=\s*\?').firstMatch(part.trim());
      if (match != null && argIndex < whereArgs.length) {
        final field = match.group(1)!;
        final value = whereArgs[argIndex++];
        if (row[field]?.toString() != value?.toString()) return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _sortWebRows(
    List<Map<String, dynamic>> rows,
    String orderBy,
  ) {
    final parts = orderBy.split(',');
    final criteria = <({String field, bool desc})>[];
    for (final part in parts) {
      final t = part.trim();
      final isDesc = t.toUpperCase().contains(' DESC');
      final field = t
          .replaceAll(RegExp(r'\s+(ASC|DESC).*$', caseSensitive: false), '')
          .trim();
      criteria.add((field: field, desc: isDesc));
    }
    final sorted = List<Map<String, dynamic>>.from(rows);
    sorted.sort((a, b) {
      for (final c in criteria) {
        final av = a[c.field];
        final bv = b[c.field];
        int cmp;
        if (av == null && bv == null) {
          cmp = 0;
        } else if (av == null) {
          cmp = -1;
        } else if (bv == null) {
          cmp = 1;
        } else if (av is num && bv is num) {
          cmp = av.compareTo(bv);
        } else {
          cmp = av.toString().compareTo(bv.toString());
        }
        if (cmp != 0) return c.desc ? -cmp : cmp;
      }
      return 0;
    });
    return sorted;
  }

  Future<void> insertMedication(Medication med) async {
    if (_isWeb) {
      // Web-Modus: In-Memory Storage
      _webTables['medications']!.add(med.toMap());
      return;
    }
    final db = database;
    await db?.insert(
      'medications',
      med.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<Medication>> getAllMedications() async {
    if (_isWeb) {
      // Web-Modus: Return In-Memory Medications (alphabetisch sortiert)
      final meds = (_webTables['medications'] ?? [])
          .map((m) => Medication.fromMap(m))
          .toList();
      meds.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return meds;
    }
    final db = database;
    final maps = await db?.query(
          'medications',
          orderBy: 'trade_name COLLATE NOCASE ASC',
        ) ??
        [];
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  Future<List<Medication>> searchMedications(String query) async {
    if (_isWeb) {
      // Web-Modus: Filter In-Memory Medications (alphabetisch sortiert)
      final lowerQuery = query.toLowerCase();
      final meds = (_webTables['medications'] ?? [])
          .where((m) {
            final med = Medication.fromMap(m);
            return med.name.toLowerCase().contains(lowerQuery) ||
                med.activeIngredient.toLowerCase().contains(lowerQuery) ||
                (med.category?.toLowerCase().contains(lowerQuery) ?? false);
          })
          .map((m) => Medication.fromMap(m))
          .toList();
      meds.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return meds;
    }
    final db = database;
    final maps = await db?.query(
          'medications',
          where:
              'trade_name LIKE ? OR active_ingredient LIKE ? OR category LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'trade_name COLLATE NOCASE ASC',
        ) ??
        [];
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  Future<void> updateMedication(Medication med) async {
    if (_isWeb) {
      // Web-Modus: Update In-Memory Medication
      final index = _webTables['medications']!.indexWhere(
        (m) => m['id'] == med.id,
      );
      if (index >= 0) {
        _webTables['medications']![index] = med.toMap();
      }
      return;
    }
    final db = database;
    await db?.update(
      'medications',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );
  }

  Future<void> deleteMedication(String id) async {
    if (_isWeb) {
      // Web-Modus: Delete In-Memory Medication
      _webTables['medications']!.removeWhere((m) => m['id'] == id);
      return;
    }
    final db = database;
    await db?.delete('medications', where: 'id = ?', whereArgs: [id]);
  }
}
