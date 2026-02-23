import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rescue_doc/features/medications/models/medication.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

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
      return;
    }

    try {
      final databasePath = await sqflite.getDatabasesPath();
      final path = '$databasePath/rescue_doc.db';

      _database = await sqflite.openDatabase(
        path,
        version: 6,
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
        ecg_rhythm TEXT,
        a_documented INTEGER DEFAULT 0,
        event_description TEXT,
        cpr_tubus_types TEXT,
        cpr_tubus_sizes TEXT,
        cpr_shocks INTEGER,
        cpr_rosc INTEGER DEFAULT 0,
        cpr_medications TEXT,
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
    await db.execute('CREATE INDEX idx_missions_start_time ON missions(start_time)');
    await db.execute('CREATE INDEX idx_patients_mission ON patients(mission_id)');
    await db.execute('CREATE INDEX idx_abcde_mission ON abcde_assessments(mission_id)');
    await db.execute('CREATE INDEX idx_abcde_timestamp ON abcde_assessments(timestamp)');
    await db.execute('CREATE INDEX idx_vital_signs_mission ON vital_signs(mission_id)');
    await db.execute('CREATE INDEX idx_vital_signs_timestamp ON vital_signs(timestamp)');
    await db.execute('CREATE INDEX idx_measures_mission ON measures(mission_id)');
    await db.execute('CREATE INDEX idx_measures_performed ON measures(performed_at)');
    await db.execute('CREATE INDEX idx_medications_name ON medications(trade_name)');
  }

  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    print('📦 Database migration: v$oldVersion -> v$newVersion');
    
    // Migration v1 -> v2: event_description Spalte hinzufügen
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN event_description TEXT');
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
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN cpr_tubus_types TEXT');
        
        print('  → Füge cpr_tubus_sizes hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN cpr_tubus_sizes TEXT');
        
        print('  → Füge cpr_shocks hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN cpr_shocks INTEGER');
        
        print('  → Füge cpr_rosc hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN cpr_rosc INTEGER DEFAULT 0');
        
        print('  → Füge cpr_medications hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN cpr_medications TEXT');
        
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
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN airway_medications TEXT');
        print('✅ Migration v4: airway_medications Spalte erfolgreich hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v4: airway_medications - $e');
      }
    }
    
    // Migration v4 -> v5: Medikamentenspalten für B, C, D, E hinzufügen
    if (oldVersion < 5) {
      print('🔄 Starte Migration v5: B/C/D/E Medikamente...');
      try {
        print('  → Füge breathing_medications hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN breathing_medications TEXT');
        
        print('  → Füge circulation_medications hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN circulation_medications TEXT');
        
        print('  → Füge disability_medications hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN disability_medications TEXT');
        
        print('  → Füge exposure_medications hinzu...');
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN exposure_medications TEXT');
        
        print('✅ Migration v5: Alle B/C/D/E Medikamenten-Spalten erfolgreich hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v5: B/C/D/E Medikamente - $e');
      }
    }

    // Migration v5 -> v6: BEFAST-Spalte hinzufügen
    if (oldVersion < 6) {
      print('🔄 Starte Migration v6: BEFAST...');
      try {
        await db.execute('ALTER TABLE abcde_assessments ADD COLUMN befast_result TEXT');
        print('✅ Migration v6: befast_result Spalte erfolgreich hinzugefügt');
      } catch (e) {
        print('⚠️ Migration v6: befast_result - $e');
      }
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
    final parts =
        where.trim().split(RegExp(r'\s+AND\s+', caseSensitive: false));
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
    final parts =
        where.trim().split(RegExp(r'\s+AND\s+', caseSensitive: false));
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
      final field =
          t.replaceAll(RegExp(r'\s+(ASC|DESC).*$', caseSensitive: false), '').trim();
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
      // Web-Modus: Return In-Memory Medications
      return (_webTables['medications'] ?? [])
          .map((m) => Medication.fromMap(m))
          .toList();
    }
    final db = database;
    final maps = await db?.query(
      'medications',
      orderBy: 'trade_name COLLATE NOCASE ASC',
    ) ?? [];
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  Future<List<Medication>> searchMedications(String query) async {
    if (_isWeb) {
      // Web-Modus: Filter In-Memory Medications
      final lowerQuery = query.toLowerCase();
      return (_webTables['medications'] ?? [])
          .where((m) {
            final med = Medication.fromMap(m);
            return med.name.toLowerCase().contains(lowerQuery) ||
                med.activeIngredient.toLowerCase().contains(lowerQuery) ||
                (med.category?.toLowerCase().contains(lowerQuery) ?? false);
          })
          .map((m) => Medication.fromMap(m))
          .toList();
    }
    final db = database;
    final maps = await db?.query(
      'medications',
      where: 'trade_name LIKE ? OR active_ingredient LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'trade_name COLLATE NOCASE ASC',
    ) ?? [];
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  Future<void> updateMedication(Medication med) async {
    if (_isWeb) {
      // Web-Modus: Update In-Memory Medication
      final index = _webTables['medications']!.indexWhere((m) => m['id'] == med.id);
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
    await db?.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}

