class ABCDEAssessment {
  final String id;
  final String missionId;
  final DateTime timestamp;
  
  // c - Critical Bleeding
  final bool externalBleeding;
  final String? bleedingLocation;
  final String? bleedingControl;
  
  // A - Airway
  final bool airwayPatent;
  final bool airwayThreatened;
  final String? airwayIssue;
  final String? airwayIntervention;
  final String? airwayMedications; // "Med1, Med2" (komma-getrennt)
  final bool aDocumented;
  
  // B - Breathing
  final int? respiratoryRate;
  final double? spo2;
  final String? breathingSounds;
  final bool symmetricBreathing;
  final String? breathingIssue;
  final String? breathingIntervention;
  final String? breathingMedications; // "Med1:Dose1|Med2:Dose2"
  
  // C - Circulation
  final int? heartRate;
  final int? systolicBP;
  final int? diastolicBP;
  final String? pulseQuality;
  final String? skinColor;
  final String? capillaryRefill;
  final String? circulationIssue;
  final String? circulationIntervention;
  final String? circulationMedications; // "Med1:Dose1|Med2:Dose2"
  final String? eventDescription; // Notfallereignis
  
  // D - Disability
  final int? gcsEye;
  final int? gcsVerbal;
  final int? gcsMotor;
  final String? pupilLeft;
  final String? pupilRight;
  final double? bloodSugar;
  final String? befastResult; // 'auffällig' oder 'unauffällig'
  final String? disabilityIssue;
  final String? disabilityIntervention;
  final String? disabilityMedications; // "Med1:Dose1|Med2:Dose2"
  
  // E - Exposure/Environment
  final double? temperature;
  final String? injuries;
  final String? environmentalFactors;
  final String? exposureIssue;
  final String? exposureIntervention;
  final String? exposureMedications; // "Med1:Dose1|Med2:Dose2"
  final String? situationNotes; // Situation vor Ort / Einsatzablauf / Ergänzungen
  
  // CPR - Cardiopulmonary Resuscitation
  final String? cprTubusTypes; // "Guedeltubus, Wendltubus" (komma-getrennt)
  final String? cprTubusSizes; // "Größe 3, 32mm" (komma-getrennt)
  final int? cprShocks;
  final bool? cprROSC; // Rückkehr von Eigenkreislauf
  final String? cprMedications; // "Med1, Med2" (komma-getrennt)
  
  // EKG
  final String? ecgRhythm;
  
  ABCDEAssessment({
    required this.id,
    required this.missionId,
    required this.timestamp,
    this.externalBleeding = false,
    this.bleedingLocation,
    this.bleedingControl,
    this.airwayPatent = true,
    this.airwayThreatened = false,
    this.airwayIssue,
    this.airwayIntervention,
    this.airwayMedications,
    this.respiratoryRate,
    this.spo2,
    this.breathingSounds,
    this.symmetricBreathing = true,
    this.breathingIssue,
    this.breathingIntervention,
    this.breathingMedications,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.pulseQuality,
    this.skinColor,
    this.capillaryRefill,
    this.circulationIssue,
    this.circulationIntervention,
    this.circulationMedications,
    this.gcsEye,
    this.gcsVerbal,
    this.gcsMotor,
    this.pupilLeft,
    this.pupilRight,
    this.bloodSugar,
    this.befastResult,
    this.disabilityIssue,
    this.disabilityIntervention,
    this.disabilityMedications,
    this.temperature,
    this.injuries,
    this.environmentalFactors,
    this.exposureIssue,
    this.exposureIntervention,
    this.exposureMedications,
    this.situationNotes,
    this.cprTubusTypes,
    this.cprTubusSizes,
    this.cprShocks,
    this.cprROSC,
    this.cprMedications,
    this.ecgRhythm,
    this.aDocumented = false,
    this.eventDescription,
  });
  
  int? get gcsTotal {
    if (gcsEye == null || gcsVerbal == null || gcsMotor == null) return null;
    return gcsEye! + gcsVerbal! + gcsMotor!;
  }
  
  factory ABCDEAssessment.create(String missionId) {
    return ABCDEAssessment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      missionId: missionId,
      timestamp: DateTime.now(),
    );
  }
  
  factory ABCDEAssessment.fromMap(Map<String, dynamic> map) {
    return ABCDEAssessment(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      externalBleeding: (map['external_bleeding'] ?? 0) == 1,
      bleedingLocation: map['bleeding_location'] as String?,
      bleedingControl: map['bleeding_control'] as String?,
      airwayPatent: (map['airway_patent'] ?? 1) == 1,
      airwayThreatened: (map['airway_threatened'] ?? 0) == 1,
      airwayIssue: map['airway_issue'] as String?,
      airwayIntervention: map['airway_intervention'] as String?,
      airwayMedications: map['airway_medications'] as String?,
      respiratoryRate: map['respiratory_rate'] as int?,
      spo2: map['spo2'] as double?,
      breathingSounds: map['breathing_sounds'] as String?,
      symmetricBreathing: (map['symmetric_breathing'] ?? 1) == 1,
      breathingIssue: map['breathing_issue'] as String?,
      breathingIntervention: map['breathing_intervention'] as String?,
      breathingMedications: map['breathing_medications'] as String?,
      heartRate: map['heart_rate'] as int?,
      systolicBP: map['systolic_bp'] as int?,
      diastolicBP: map['diastolic_bp'] as int?,
      pulseQuality: map['pulse_quality'] as String?,
      skinColor: map['skin_color'] as String?,
      capillaryRefill: map['capillary_refill'] as String?,
      circulationIssue: map['circulation_issue'] as String?,
      circulationIntervention: map['circulation_intervention'] as String?,
      circulationMedications: map['circulation_medications'] as String?,
      gcsEye: map['gcs_eye'] as int?,
      gcsVerbal: map['gcs_verbal'] as int?,
      gcsMotor: map['gcs_motor'] as int?,
      pupilLeft: map['pupil_left'] as String?,
      pupilRight: map['pupil_right'] as String?,
      bloodSugar: map['blood_sugar'] as double?,
      befastResult: map['befast_result'] as String?,
      disabilityIssue: map['disability_issue'] as String?,
      disabilityIntervention: map['disability_intervention'] as String?,
      disabilityMedications: map['disability_medications'] as String?,
      temperature: map['temperature'] as double?,
      injuries: map['injuries'] as String?,
      environmentalFactors: map['environmental_factors'] as String?,
      exposureIssue: map['exposure_issue'] as String?,
      exposureIntervention: map['exposure_intervention'] as String?,
      exposureMedications: map['exposure_medications'] as String?,
      situationNotes: map['situation_notes'] as String?,
      cprTubusTypes: map['cpr_tubus_types'] as String?,
      cprTubusSizes: map['cpr_tubus_sizes'] as String?,
      cprShocks: map['cpr_shocks'] as int?,
      cprROSC: (map['cpr_rosc'] ?? 0) == 1,
      cprMedications: map['cpr_medications'] as String?,
      ecgRhythm: map['ecg_rhythm'] as String?,
      aDocumented: (map['a_documented'] ?? 0) == 1,
      eventDescription: map['event_description'] as String?
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'external_bleeding': externalBleeding ? 1 : 0,
      'bleeding_location': bleedingLocation,
      'bleeding_control': bleedingControl,
      'airway_patent': airwayPatent ? 1 : 0,
      'airway_threatened': airwayThreatened ? 1 : 0,
      'airway_issue': airwayIssue,
      'airway_intervention': airwayIntervention,
      'airway_medications': airwayMedications,
      'respiratory_rate': respiratoryRate,
      'spo2': spo2,
      'breathing_sounds': breathingSounds,
      'symmetric_breathing': symmetricBreathing ? 1 : 0,
      'breathing_issue': breathingIssue,
      'breathing_intervention': breathingIntervention,
      'breathing_medications': breathingMedications,
      'heart_rate': heartRate,
      'systolic_bp': systolicBP,
      'diastolic_bp': diastolicBP,
      'pulse_quality': pulseQuality,
      'skin_color': skinColor,
      'capillary_refill': capillaryRefill,
      'circulation_issue': circulationIssue,
      'circulation_intervention': circulationIntervention,
      'circulation_medications': circulationMedications,
      'gcs_eye': gcsEye,
      'gcs_verbal': gcsVerbal,
      'gcs_motor': gcsMotor,
      'pupil_left': pupilLeft,
      'pupil_right': pupilRight,
      'blood_sugar': bloodSugar,
      'befast_result': befastResult,
      'disability_issue': disabilityIssue,
      'disability_intervention': disabilityIntervention,
      'disability_medications': disabilityMedications,
      'temperature': temperature,
      'injuries': injuries,
      'environmental_factors': environmentalFactors,
      'exposure_issue': exposureIssue,
      'exposure_intervention': exposureIntervention,
      'exposure_medications': exposureMedications,
      'situation_notes': situationNotes,
      'cpr_tubus_types': cprTubusTypes,
      'cpr_tubus_sizes': cprTubusSizes,
      'cpr_shocks': cprShocks,
      'cpr_rosc': cprROSC == true ? 1 : 0,
      'cpr_medications': cprMedications,
      'ecg_rhythm': ecgRhythm,
      'a_documented': aDocumented ? 1 : 0,
      'event_description': eventDescription,
    };
  }
  
  ABCDEAssessment copyWith({
    bool? externalBleeding,
    String? bleedingLocation,
    String? bleedingControl,
    bool? airwayPatent,
    bool? airwayThreatened,
    String? airwayIssue,
    String? airwayIntervention,
    String? airwayMedications,
    int? respiratoryRate,
    double? spo2,
    String? breathingSounds,
    bool? symmetricBreathing,
    String? breathingIssue,
    String? breathingIntervention,
    String? breathingMedications,
    int? heartRate,
    int? systolicBP,
    int? diastolicBP,
    String? pulseQuality,
    String? skinColor,
    String? capillaryRefill,
    String? circulationIssue,
    String? circulationIntervention,
    String? circulationMedications,
    int? gcsEye,
    int? gcsVerbal,
    int? gcsMotor,
    String? pupilLeft,
    String? pupilRight,
    double? bloodSugar,
    String? befastResult,
    String? disabilityIssue,
    String? disabilityIntervention,
    String? disabilityMedications,
    double? temperature,
    String? injuries,
    String? environmentalFactors,
    String? exposureIssue,
    String? exposureIntervention,
    String? exposureMedications,
    String? situationNotes,
    String? cprTubusTypes,
    String? cprTubusSizes,
    int? cprShocks,
    bool? cprROSC,
    String? cprMedications,
    String? ecgRhythm,
    String? eventDescription,
    bool? aDocumented,
  }) {
    return ABCDEAssessment(
      id: id,
      missionId: missionId,
      timestamp: timestamp,
      externalBleeding: externalBleeding ?? this.externalBleeding,
      bleedingLocation: bleedingLocation ?? this.bleedingLocation,
      bleedingControl: bleedingControl ?? this.bleedingControl,
      airwayPatent: airwayPatent ?? this.airwayPatent,
      airwayThreatened: airwayThreatened ?? this.airwayThreatened,
      airwayIssue: airwayIssue ?? this.airwayIssue,
      airwayIntervention: airwayIntervention ?? this.airwayIntervention,
      airwayMedications: airwayMedications ?? this.airwayMedications,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      spo2: spo2 ?? this.spo2,
      breathingSounds: breathingSounds ?? this.breathingSounds,
      symmetricBreathing: symmetricBreathing ?? this.symmetricBreathing,
      breathingIssue: breathingIssue ?? this.breathingIssue,
      breathingIntervention: breathingIntervention ?? this.breathingIntervention,
      breathingMedications: breathingMedications ?? this.breathingMedications,
      heartRate: heartRate ?? this.heartRate,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      pulseQuality: pulseQuality ?? this.pulseQuality,
      skinColor: skinColor ?? this.skinColor,
      capillaryRefill: capillaryRefill ?? this.capillaryRefill,
      circulationIssue: circulationIssue ?? this.circulationIssue,
      circulationIntervention: circulationIntervention ?? this.circulationIntervention,
      circulationMedications: circulationMedications ?? this.circulationMedications,
      gcsEye: gcsEye ?? this.gcsEye,
      gcsVerbal: gcsVerbal ?? this.gcsVerbal,
      gcsMotor: gcsMotor ?? this.gcsMotor,
      pupilLeft: pupilLeft ?? this.pupilLeft,
      pupilRight: pupilRight ?? this.pupilRight,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      befastResult: befastResult ?? this.befastResult,
      disabilityIssue: disabilityIssue ?? this.disabilityIssue,
      disabilityIntervention: disabilityIntervention ?? this.disabilityIntervention,
      disabilityMedications: disabilityMedications ?? this.disabilityMedications,
      temperature: temperature ?? this.temperature,
      injuries: injuries ?? this.injuries,
      environmentalFactors: environmentalFactors ?? this.environmentalFactors,
      exposureIssue: exposureIssue ?? this.exposureIssue,
      exposureIntervention: exposureIntervention ?? this.exposureIntervention,
      exposureMedications: exposureMedications ?? this.exposureMedications,
      situationNotes: situationNotes ?? this.situationNotes,
      cprTubusTypes: cprTubusTypes ?? this.cprTubusTypes,
      cprTubusSizes: cprTubusSizes ?? this.cprTubusSizes,
      cprShocks: cprShocks ?? this.cprShocks,
      cprROSC: cprROSC ?? this.cprROSC,
      cprMedications: cprMedications ?? this.cprMedications,
      ecgRhythm: ecgRhythm ?? this.ecgRhythm,
      aDocumented: aDocumented ?? this.aDocumented,
      eventDescription: eventDescription ?? this.eventDescription,
    );
  }
}
