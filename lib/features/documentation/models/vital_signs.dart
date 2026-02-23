enum PupilStatus {
  normal,
  dilated,
  constricted,
  unresponsive,
}

class VitalSigns {
  final String id;
  final String missionId;
  final DateTime timestamp;
  
  // Vital Parameter
  final int? heartRate;
  final int? systolicBP;
  final int? diastolicBP;
  final int? respiratoryRate;
  final double? spo2;
  final double? temperature;
  final int? gcs;
  final double? bloodSugar;
  
  // EKG
  final String? ecgRhythm;
  
  // Pupillen
  final PupilStatus? leftPupil;
  final PupilStatus? rightPupil;
  
  // Notizen
  final String? notes;
  
  VitalSigns({
    required this.id,
    required this.missionId,
    required this.timestamp,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.respiratoryRate,
    this.spo2,
    this.temperature,
    this.gcs,
    this.bloodSugar,
    this.ecgRhythm,
    this.leftPupil,
    this.rightPupil,
    this.notes,
  });
  
  factory VitalSigns.create(String missionId) {
    return VitalSigns(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      missionId: missionId,
      timestamp: DateTime.now(),
    );
  }
  
  factory VitalSigns.fromMap(Map<String, dynamic> map) {
    return VitalSigns(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      heartRate: map['heart_rate'] as int?,
      systolicBP: map['systolic_bp'] as int?,
      diastolicBP: map['diastolic_bp'] as int?,
      respiratoryRate: map['respiratory_rate'] as int?,
      spo2: map['spo2'] as double?,
      temperature: map['temperature'] as double?,
      gcs: map['gcs'] as int?,
      bloodSugar: map['blood_sugar'] as double?,
      ecgRhythm: map['ecg_rhythm'] as String?,
      leftPupil: map['left_pupil'] != null
          ? PupilStatus.values.firstWhere((e) => e.name == map['left_pupil'])
          : null,
      rightPupil: map['right_pupil'] != null
          ? PupilStatus.values.firstWhere((e) => e.name == map['right_pupil'])
          : null,
      notes: map['notes'] as String?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'heart_rate': heartRate,
      'systolic_bp': systolicBP,
      'diastolic_bp': diastolicBP,
      'respiratory_rate': respiratoryRate,
      'spo2': spo2,
      'temperature': temperature,
      'gcs': gcs,
      'blood_sugar': bloodSugar,
      'ecg_rhythm': ecgRhythm,
      'left_pupil': leftPupil?.name,
      'right_pupil': rightPupil?.name,
      'notes': notes,
    };
  }
  
  String get bloodPressure {
    if (systolicBP == null || diastolicBP == null) return '-';
    return '$systolicBP/$diastolicBP';
  }
  
  bool get hasAnyData {
    return heartRate != null ||
        systolicBP != null ||
        diastolicBP != null ||
        respiratoryRate != null ||
        spo2 != null ||
        temperature != null ||
        gcs != null ||
        bloodSugar != null;
  }
    VitalSigns copyWith({
    String? id,
    String? missionId,
    DateTime? timestamp,
    int? heartRate,
    int? systolicBP,
    int? diastolicBP,
    int? respiratoryRate,
    double? spo2,
    double? temperature,
    int? gcs,
    double? bloodSugar,
    String? ecgRhythm,
    PupilStatus? leftPupil,
    PupilStatus? rightPupil,
    String? notes,
  }) {
    return VitalSigns(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      gcs: gcs ?? this.gcs,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      ecgRhythm: ecgRhythm ?? this.ecgRhythm,
      leftPupil: leftPupil ?? this.leftPupil,
      rightPupil: rightPupil ?? this.rightPupil,
      notes: notes ?? this.notes,
    );
  }
}
