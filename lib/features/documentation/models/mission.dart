import 'package:uuid/uuid.dart';

enum MissionStatus {
  active,
  completed,
  archived,
}

class Mission {
  final String id;
  final String? missionNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final MissionStatus status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Mission({
    required this.id,
    this.missionNumber,
    required this.startTime,
    this.endTime,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Factory constructor für neuen Einsatz
  factory Mission.create({String? missionNumber, String? createdBy}) {
    final now = DateTime.now();
    return Mission(
      id: const Uuid().v4(),
      missionNumber: missionNumber,
      startTime: now,
      status: MissionStatus.active,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Von Database Map
  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as String,
      missionNumber: map['mission_number'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      status: MissionStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
  
  // Zu Database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_number': missionNumber,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'status': status.name,
      'created_by': createdBy,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
  
  // CopyWith für Updates
  Mission copyWith({
    String? missionNumber,
    DateTime? endTime,
    MissionStatus? status,
  }) {
    return Mission(
      id: id,
      missionNumber: missionNumber ?? this.missionNumber,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
