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
  final DatabaseService _db;

  SQLiteMissionRepository(this._db);

  @override
  Future<List<Mission>> getAllMissions() async {
    final maps = await _db.dbQuery('missions', orderBy: 'start_time DESC');
    return maps.map((m) => Mission.fromMap(m)).toList();
  }

  @override
  Future<Mission?> getMissionById(String id) async {
    final maps = await _db.dbQuery(
      'missions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Mission.fromMap(maps.first);
  }

  @override
  Future<void> saveMission(Mission mission) async {
    await _db.dbInsert('missions', mission.toMap());
  }

  @override
  Future<void> deleteMission(String id) async {
    await _db.dbDelete('missions', where: 'id = ?', whereArgs: [id]);
  }

  // Patients
  @override
  Future<Patient?> getPatientByMissionId(String missionId) async {
    final maps = await _db.dbQuery(
      'patients',
      where: 'mission_id = ?',
      whereArgs: [missionId],
    );
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  @override
  Future<void> savePatient(Patient patient) async {
    await _db.dbInsert('patients', patient.toMap());
  }

  // Vital Signs
  @override
  Future<List<VitalSigns>> getVitalSignsByMissionId(String missionId) async {
    final maps = await _db.dbQuery(
      'vital_signs',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => VitalSigns.fromMap(m)).toList();
  }

  @override
  Future<void> saveVitalSigns(VitalSigns vitalSigns) async {
    await _db.dbInsert('vital_signs', vitalSigns.toMap());
  }

  @override
  Future<void> deleteVitalSigns(String id) async {
    await _db.dbDelete('vital_signs', where: 'id = ?', whereArgs: [id]);
  }

  // Measures
  @override
  Future<List<Measure>> getMeasuresByMissionId(String missionId) async {
    final maps = await _db.dbQuery(
      'measures',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'performed_at DESC',
    );
    return maps.map((m) => Measure.fromMap(m)).toList();
  }

  @override
  Future<void> saveMeasure(Measure measure) async {
    await _db.dbInsert('measures', measure.toMap());
  }

  @override
  Future<void> deleteMeasure(String id) async {
    await _db.dbDelete('measures', where: 'id = ?', whereArgs: [id]);
  }

  // cABCDE
  @override
  Future<List<ABCDEAssessment>> getABCDEByMissionId(String missionId) async {
    final maps = await _db.dbQuery(
      'abcde_assessments',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ABCDEAssessment.fromMap(m)).toList();
  }

  @override
  Future<void> saveABCDEAssessment(ABCDEAssessment assessment) async {
    await _db.dbInsert('abcde_assessments', assessment.toMap());
  }
}

