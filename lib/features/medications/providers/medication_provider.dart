import 'package:flutter/foundation.dart';

import '../models/medication.dart';
import '../repositories/medication_repository.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _repo;

  List<Medication> _all = [];
  List<Medication> get all => _all;

  MedicationProvider(this._repo);

  Future<void> loadAll() async {
    _all = await _repo.getAllMedications();
  }

  List<Medication> medicationsForSection(String section) {
    return _all.where((m) => m.appliesToSection(section)).toList();
  }

  Future<void> addOrUpdateMedication(Medication med) async {
    // einfache Variante: immer insert mit REPLACE im Repo
    await _repo.insertMedication(med);
    await loadAll();
    notifyListeners();
  }

  Future<void> deleteMedication(String id) async {
    await _repo.deleteMedication(id);
    await loadAll();
    notifyListeners();
  }
}
