import '../../../core/services/database_service.dart';
import '../models/isbar_handover.dart';

class ISBARRepository {
  final DatabaseService _databaseService;

  ISBARRepository(this._databaseService);

  Future<ISBARHandover?> getForMission(String missionId) async {
    final maps = await _databaseService.dbQuery(
      'isbar_handovers',
      where: 'mission_id = ?',
      whereArgs: [missionId],
    );
    if (maps.isEmpty) return null;
    return ISBARHandover.fromMap(maps.first);
  }

  Future<void> upsert(ISBARHandover handover) async {
    await _databaseService.dbInsert('isbar_handovers', handover.toMap());
  }
}
