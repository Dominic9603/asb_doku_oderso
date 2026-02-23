import 'package:sqflite/sqflite.dart' as sqflite;
import '../../../core/services/database_service.dart';
import '../models/mission.dart';
import '../models/patient.dart';
import '../models/vital_signs.dart';
import '../models/measure.dart';
import '../models/abcde_assessment.dart';

abstract class MissionRepository {
  Future<List<Mission>> getAllMissions();
  Future<Mission?> getMissionById(String id);
  Future<void> saveMission(Mission mission);
  Future<void> deleteMission(String id);
  
  // Patient
  Future<Patient?> getPatientByMissionId(String missionId);
  Future<void> savePatient(Patient patient);
  
  // Vital Signs
  Future<List<VitalSigns>> getVitalSignsByMissionId(String missionId);
  Future<void> saveVitalSigns(VitalSigns vitalSigns);
  Future<void> deleteVitalSigns(String id);
  
  // Measures
  Future<List<Measure>> getMeasuresByMissionId(String missionId);
  Future<void> saveMeasure(Measure measure);
  Future<void> deleteMeasure(String id);
  
  // cABCDE
  Future<List<ABCDEAssessment>> getABCDEByMissionId(String missionId);
  Future<void> saveABCDEAssessment(ABCDEAssessment assessment);
}

class SQLiteMissionRepository implements MissionRepository {
  final DatabaseService _databaseService;
  
  SQLiteMissionRepository(this._databaseService);
  
  sqflite.Database? get _db => _databaseService.database;
  
  bool get _isWeb => _databaseService.isWeb;
  
  @override
  Future<List<Mission>> getAllMissions() async {
    if (_isWeb) return []; // Web: Keine Daten
    final maps = await _db?.query(
      'missions',
      orderBy: 'start_time DESC',
    ) ?? [];
    return maps.map((map) => Mission.fromMap(map)).toList();
  }
  
  @override
  Future<Mission?> getMissionById(String id) async {
    final maps = await _db?.query(
      'missions',
      where: 'id = ?',
      whereArgs: [id],
    ) ?? [];
    if (maps.isEmpty) return null;
    return Mission.fromMap(maps.first);
  }
  
  @override
  Future<void> saveMission(Mission mission) async {
    await _db?.insert(
      'missions',
      mission.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
  
  @override
  Future<void> deleteMission(String id) async {
    await _db?.delete(
      'missions',
      where: 'id = ?',
      whereArgs: [id],
    ) ?? [];
  }
  
  // Patients
  @override
  Future<Patient?> getPatientByMissionId(String missionId) async {
    final maps = await _db?.query(
      'patients',
      where: 'mission_id = ?',
      whereArgs: [missionId],
    ) ?? [];
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }
  
  @override
  Future<void> savePatient(Patient patient) async {
    await _db?.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
  
  // Vital Signs
  @override
  Future<List<VitalSigns>> getVitalSignsByMissionId(String missionId) async {
    final maps = await _db?.query(
      'vital_signs',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'timestamp DESC',
    ) ?? [];
    return maps.map((map) => VitalSigns.fromMap(map)).toList();
  }
  
  @override
  Future<void> saveVitalSigns(VitalSigns vitalSigns) async {
    await _db?.insert(
      'vital_signs',
      vitalSigns.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
  
  @override
  Future<void> deleteVitalSigns(String id) async {
    await _db?.delete(
      'vital_signs',
      where: 'id = ?',
      whereArgs: [id],
    ) ?? [];
  }
  
  // Measures
  @override
  Future<List<Measure>> getMeasuresByMissionId(String missionId) async {
    final maps = await _db?.query(
      'measures',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'performed_at DESC',
    ) ?? [];
    return maps.map((map) => Measure.fromMap(map)).toList();
  }
  
  @override
  Future<void> saveMeasure(Measure measure) async {
    await _db?.insert(
      'measures',
      measure.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
  
  @override
  Future<void> deleteMeasure(String id) async {
    await _db?.delete(
      'measures',
      where: 'id = ?',
      whereArgs: [id],
    ) ?? [];
  }
  
  // cABCDE
  @override
  Future<List<ABCDEAssessment>> getABCDEByMissionId(String missionId) async {
    final maps = await _db?.query(
      'abcde_assessments',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'timestamp DESC',
    ) ?? [];
    return maps.map((m) => ABCDEAssessment.fromMap(m)).toList();
  }
  
  @override
  Future<void> saveABCDEAssessment(ABCDEAssessment assessment) async {
    await _db?.insert(
      'abcde_assessments',
      assessment.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
}

