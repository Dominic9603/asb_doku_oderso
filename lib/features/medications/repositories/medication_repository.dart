import '../../../core/services/database_service.dart';
import '../models/medication.dart';

class MedicationRepository {
  final DatabaseService _databaseService;

  MedicationRepository(this._databaseService);

  Future<List<Medication>> getAllMedications() async {
    return await _databaseService.getAllMedications();
  }

  Future<List<Medication>> getMedicationsForSection(String section) async {
    final all = await _databaseService.getAllMedications();
    return all.where((m) => (m.sectionsCsv ?? '').contains(section)).toList();
  }

  Future<void> insertMedication(Medication med) async {
    await _databaseService.insertMedication(med);
  }

  Future<void> deleteMedication(String id) async {
    await _databaseService.deleteMedication(id);
  }
}

