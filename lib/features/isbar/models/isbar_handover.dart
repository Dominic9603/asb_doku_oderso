class ISBARHandover {
  final String id;
  final String missionId;
  final String? identification;
  final String? situation;
  final String? background;
  final String? assessment;
  final String? recommendation;
  final int createdAt;

  ISBARHandover({
    required this.id,
    required this.missionId,
    this.identification,
    this.situation,
    this.background,
    this.assessment,
    this.recommendation,
    required this.createdAt,
  });

  ISBARHandover copyWith({
    String? id,
    String? missionId,
    String? identification,
    String? situation,
    String? background,
    String? assessment,
    String? recommendation,
    int? createdAt,
  }) {
    return ISBARHandover(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      identification: identification ?? this.identification,
      situation: situation ?? this.situation,
      background: background ?? this.background,
      assessment: assessment ?? this.assessment,
      recommendation: recommendation ?? this.recommendation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'identification': identification,
      'situation': situation,
      'background': background,
      'assessment': assessment,
      'recommendation': recommendation,
      'created_at': createdAt,
    };
  }

  factory ISBARHandover.fromMap(Map<String, dynamic> map) {
    return ISBARHandover(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      identification: map['identification'] as String?,
      situation: map['situation'] as String?,
      background: map['background'] as String?,
      assessment: map['assessment'] as String?,
      recommendation: map['recommendation'] as String?,
      createdAt: map['created_at'] as int,
    );
  }
}
