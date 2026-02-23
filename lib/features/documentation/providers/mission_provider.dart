import 'package:flutter/foundation.dart';

import '../models/mission.dart';
import '../models/patient.dart';
import '../models/vital_signs.dart';
import '../models/measure.dart';
import '../models/abcde_assessment.dart';
import '../repositories/mission_repository.dart';

class MissionProvider extends ChangeNotifier {
  final MissionRepository _repository;

  MissionProvider(this._repository) {
    _loadMissions();
  }

  List<Mission> _missions = [];
  List<Mission> get missions => _missions;

  Mission? _currentMission;
  Mission? get currentMission => _currentMission;

  Patient? _currentPatient;
  Patient? get currentPatient => _currentPatient;

  List<VitalSigns> _currentVitalSigns = [];
  List<VitalSigns> get currentVitalSigns => _currentVitalSigns;
  List<VitalSigns> get vitalSigns => _currentVitalSigns;

  List<Measure> _currentMeasures = [];
  List<Measure> get currentMeasures => _currentMeasures;
  List<Measure> get measures => _currentMeasures;

  List<ABCDEAssessment> _abcdeAssessments = [];
  List<ABCDEAssessment> get abcdeAssessments => _abcdeAssessments;

  ABCDEAssessment? get latestABCDE =>
      _abcdeAssessments.isNotEmpty ? _abcdeAssessments.first : null;

  // NEU: letzter Vitalzeichen-Datensatz
  VitalSigns? latestVitalSigns;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> _loadMissions() async {
    _isLoading = true;
    try {
      _missions = await _repository.getAllMissions();
      
      // Auto-Löschung: Einsätze älter als 24h entfernen
      final now = DateTime.now();
      final expiredMissions = _missions.where((m) =>
        now.difference(m.startTime).inHours >= 24
      ).toList();
      for (final expired in expiredMissions) {
        await _repository.deleteMission(expired.id);
      }
      if (expiredMissions.isNotEmpty) {
        _missions.removeWhere((m) =>
          now.difference(m.startTime).inHours >= 24
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNewMission({String? missionNumber}) async {
    _currentMission = Mission.create(missionNumber: missionNumber);
    await _repository.saveMission(_currentMission!);

    _currentPatient = Patient.create(_currentMission!.id);
    await _repository.savePatient(_currentPatient!);

    _currentVitalSigns = [];
    _currentMeasures = [];
    _abcdeAssessments = [];
    latestVitalSigns = null;

    await _loadMissions();
  }

  Future<void> loadMission(String missionId) async {
    _isLoading = true;
    try {
      _currentMission = await _repository.getMissionById(missionId);
      if (_currentMission != null) {
        _currentPatient =
            await _repository.getPatientByMissionId(missionId);
        _currentVitalSigns =
            await _repository.getVitalSignsByMissionId(missionId);
        _currentMeasures =
            await _repository.getMeasuresByMissionId(missionId);
        _abcdeAssessments =
            await _repository.getABCDEByMissionId(missionId);

        // Sortiere ABCDE assessments nach Timestamp (neuste zuerst)
        if (_abcdeAssessments.isNotEmpty) {
          _abcdeAssessments.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          );
        }

        // falls kein Patient vorhanden, einen anlegen
        if (_currentPatient == null) {
          _currentPatient = Patient.create(missionId);
          await _repository.savePatient(_currentPatient!);
        }

        // NEU: latestVitalSigns aus Liste bestimmen
        if (_currentVitalSigns.isNotEmpty) {
          _currentVitalSigns.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          );
          latestVitalSigns = _currentVitalSigns.first;
        } else {
          latestVitalSigns = null;
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> completeMission() async {
    if (_currentMission == null) return;
    final completed = _currentMission!.copyWith(
      endTime: DateTime.now(),
      status: MissionStatus.completed,
    );
    await _repository.saveMission(completed);
    _currentMission = null;
    _currentPatient = null;
    _currentVitalSigns = [];
    _currentMeasures = [];
    _abcdeAssessments = [];
    latestVitalSigns = null;
    await _loadMissions();
  }

  Future<void> deleteMission(String id) async {
    await _repository.deleteMission(id);
    await _loadMissions();
  }

  // Patient
  Future<void> updatePatient(Patient patient) async {
    await _repository.savePatient(patient);
    _currentPatient = patient;
  }

  // Vital Signs
  Future<void> addVitalSigns(VitalSigns vitalSigns) async {
    await _repository.saveVitalSigns(vitalSigns);
    _currentVitalSigns.insert(0, vitalSigns);
    latestVitalSigns = vitalSigns;
    notifyListeners();
  }

  Future<void> deleteVitalSigns(String id) async {
    await _repository.deleteVitalSigns(id);
    _currentVitalSigns.removeWhere((v) => v.id == id);
    if (latestVitalSigns?.id == id) {
      if (_currentVitalSigns.isNotEmpty) {
        _currentVitalSigns.sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        );
        latestVitalSigns = _currentVitalSigns.first;
      } else {
        latestVitalSigns = null;
      }
    }
    notifyListeners();
  }

  // Maßnahmen
  Future<void> addMeasure(Measure measure) async {
    await _repository.saveMeasure(measure);
    _currentMeasures.insert(0, measure);
    notifyListeners();
  }

  Future<void> deleteMeasure(String id) async {
    await _repository.deleteMeasure(id);
    _currentMeasures.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// Prüft ob eine Maßnahme dieses Typs existiert
  bool hasMeasure(MeasureType type) {
    return _currentMeasures.any((m) => m.measureType == type);
  }

  /// Erstellt eine Maßnahme falls noch keine dieses Typs existiert (für cABCDE-Sync)
  Future<void> ensureMeasureExists(MeasureType type, {String? notes}) async {
    if (_currentMission == null) return;
    if (!hasMeasure(type)) {
      final measure = Measure(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        missionId: _currentMission!.id,
        measureType: type,
        performedAt: DateTime.now(),
        notes: notes,
      );
      await addMeasure(measure);
    }
  }

  // cABCDE
  Future<void> addOrUpdateABCDE(ABCDEAssessment assessment) async {
    await _repository.saveABCDEAssessment(assessment);
    _abcdeAssessments.removeWhere((a) => a.id == assessment.id);
    _abcdeAssessments.insert(0, assessment);
    notifyListeners();  // ← KRITISCH: UI muss benachrichtigt werden
  }

  Future<void> refresh() async {
    await _loadMissions();
    if (_currentMission != null) {
      await loadMission(_currentMission!.id);
    }
  }
}
