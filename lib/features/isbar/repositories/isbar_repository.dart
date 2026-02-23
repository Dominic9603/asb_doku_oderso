import 'package:sqflite/sqflite.dart' as sqflite;

import '../../../core/services/database_service.dart';
import '../models/isbar_handover.dart';

class ISBARRepository {
  final DatabaseService _databaseService;

  ISBARRepository(this._databaseService);

  sqflite.Database? get _db => _databaseService.database;
  bool get _isWeb => _databaseService.isWeb;

  Future<ISBARHandover?> getForMission(String missionId) async {
    if (_isWeb) return null;
    final maps = await _db?.query(
      'isbar_handovers',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      limit: 1,
    ) ?? [];
    if (maps.isEmpty) return null;
    return ISBARHandover.fromMap(maps.first);
  }

  Future<void> upsert(ISBARHandover handover) async {
    if (_isWeb) return;
    await _db?.insert(
      'isbar_handovers',
      handover.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
}

