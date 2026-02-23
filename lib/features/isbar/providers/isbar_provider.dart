import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/isbar_handover.dart';
import '../repositories/isbar_repository.dart';

class ISBARProvider extends ChangeNotifier {
  final ISBARRepository _repo;

  ISBARHandover? _current;
  ISBARHandover? get current => _current;

  ISBARProvider(this._repo);

  Future<void> loadForMission(String missionId) async {
    _current = await _repo.getForMission(missionId);
    notifyListeners();
  }

  Future<void> saveForMission({
    required String missionId,
    String? identification,
    String? situation,
    String? background,
    String? assessment,
    String? recommendation,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = _current;
    final handover = existing == null
        ? ISBARHandover(
            id: const Uuid().v4(),
            missionId: missionId,
            identification: identification,
            situation: situation,
            background: background,
            assessment: assessment,
            recommendation: recommendation,
            createdAt: now,
          )
        : existing.copyWith(
            identification: identification,
            situation: situation,
            background: background,
            assessment: assessment,
            recommendation: recommendation,
            createdAt: now,
          );

    await _repo.upsert(handover);
    _current = handover;
    notifyListeners();
  }
}
