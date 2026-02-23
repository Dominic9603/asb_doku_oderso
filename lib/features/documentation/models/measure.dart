enum MeasureType {
  // Airway
  guedeltubus,
  wendltubus,
  endotrachealIntubation,
  supraglotticAirway,
  absaugen,
  
  // Breathing
  oxygenTherapy,
  bagValveMask,
  mechanicalVentilation,
  auskultation,
  
  // Circulation
  ivAccess,
  ioAccess,
  fluidResuscitation,
  tourniquetApplication,
  woundPacking,
  druckverband,
  
  // Monitoring
  ecgAbleitung,
  pulseOximetry,
  capnography,
  bloodPressureMonitoring,
  
  // Immobilization
  cervicalCollar,
  spinalBoard,
  splinting,
  pelvicBinder,
  vakuummatratze,
  schaufeltrage,
  rettungstuch,
  
  // Wundversorgung & Thermomanagement
  wundverband,
  waermeerhalt,
  kuehlen,
  
  // Lagerung
  lagerung,
  
  // Other
  cpr,
  defibrillation,
  pacing,
  nasogastricTube,
  other,
}

class Measure {
  final String id;
  final String missionId;
  final MeasureType measureType;
  final DateTime performedAt;
  final String? notes;
  
  Measure({
    required this.id,
    required this.missionId,
    required this.measureType,
    required this.performedAt,
    this.notes,
  });
  
  factory Measure.create(String missionId, MeasureType measureType) {
    return Measure(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      missionId: missionId,
      measureType: measureType,
      performedAt: DateTime.now(),
    );
  }
  
  factory Measure.fromMap(Map<String, dynamic> map) {
    final typeStr = map['measure_type'] as String;
    final type = MeasureType.values.cast<MeasureType?>().firstWhere(
      (e) => e?.name == typeStr,
      orElse: () => null,
    );
    
    // Unbekannte/gelöschte Typen → als 'other' laden mit Notiz
    return Measure(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      measureType: type ?? MeasureType.other,
      performedAt: DateTime.fromMillisecondsSinceEpoch(map['performed_at'] as int),
      notes: type == null
          ? '(Ehem. $typeStr) ${map['notes'] ?? ''}'
          : map['notes'] as String?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'measure_type': measureType.name,
      'performed_at': performedAt.millisecondsSinceEpoch,
      'notes': notes,
    };
  }
  
  String get displayName {
    switch (measureType) {
      // Airway
      case MeasureType.guedeltubus:
        return 'Guedeltubus';
      case MeasureType.wendltubus:
        return 'Wendltubus';
      case MeasureType.endotrachealIntubation:
        return 'Endotracheale Intubation';
      case MeasureType.supraglotticAirway:
        return 'Supraglottischer Atemweg';
      case MeasureType.absaugen:
        return 'Absaugen';
      
      // Breathing
      case MeasureType.oxygenTherapy:
        return 'Sauerstoffgabe';
      case MeasureType.bagValveMask:
        return 'Beatmungsbeutel';
      case MeasureType.mechanicalVentilation:
        return 'Maschinelle Beatmung';
      case MeasureType.auskultation:
        return 'Auskultation';
      
      // Circulation
      case MeasureType.ivAccess:
        return 'Intravenöser Zugang';
      case MeasureType.ioAccess:
        return 'Intraossärer Zugang';
      case MeasureType.fluidResuscitation:
        return 'Volumentherapie';
      case MeasureType.tourniquetApplication:
        return 'Tourniquet';
      case MeasureType.woundPacking:
        return 'Wundtamponade';
      case MeasureType.druckverband:
        return 'Druckverband';
      
      // Monitoring
      case MeasureType.ecgAbleitung:
        return 'EKG';
      case MeasureType.pulseOximetry:
        return 'Pulsoxymetrie';
      case MeasureType.capnography:
        return 'Kapnographie';
      case MeasureType.bloodPressureMonitoring:
        return 'Blutdruckmessung';
      
      // Immobilization
      case MeasureType.cervicalCollar:
        return 'HWS-Schiene';
      case MeasureType.spinalBoard:
        return 'Spineboard';
      case MeasureType.splinting:
        return 'Schienung';
      case MeasureType.pelvicBinder:
        return 'Beckengurt';
      case MeasureType.vakuummatratze:
        return 'Vakuummatratze';
      case MeasureType.schaufeltrage:
        return 'Schaufeltrage';
      case MeasureType.rettungstuch:
        return 'Rettungstuch';
      
      // Wundversorgung & Thermo
      case MeasureType.wundverband:
        return 'Wundverband';
      case MeasureType.waermeerhalt:
        return 'Wärmeerhalt';
      case MeasureType.kuehlen:
        return 'Kühlen';
      
      // Lagerung
      case MeasureType.lagerung:
        return 'Lagerung';
      
      // Other
      case MeasureType.cpr:
        return 'Reanimation';
      case MeasureType.defibrillation:
        return 'Defibrillation';
      case MeasureType.pacing:
        return 'Pacing';
      case MeasureType.nasogastricTube:
        return 'Magensonde';
      case MeasureType.other:
        return 'Sonstige Maßnahme';
    }
  }
  
  String get category {
    if ([
      MeasureType.guedeltubus,
      MeasureType.wendltubus,
      MeasureType.endotrachealIntubation,
      MeasureType.supraglotticAirway,
      MeasureType.absaugen,
    ].contains(measureType)) {
      return 'Airway';
    }
    
    if ([
      MeasureType.oxygenTherapy,
      MeasureType.bagValveMask,
      MeasureType.mechanicalVentilation,
      MeasureType.auskultation,
    ].contains(measureType)) {
      return 'Breathing';
    }
    
    if ([
      MeasureType.ivAccess,
      MeasureType.ioAccess,
      MeasureType.fluidResuscitation,
      MeasureType.tourniquetApplication,
      MeasureType.woundPacking,
      MeasureType.druckverband,
    ].contains(measureType)) {
      return 'Circulation';
    }
    
    if ([
      MeasureType.ecgAbleitung,
      MeasureType.pulseOximetry,
      MeasureType.capnography,
      MeasureType.bloodPressureMonitoring,
    ].contains(measureType)) {
      return 'Monitoring';
    }
    
    if ([
      MeasureType.cervicalCollar,
      MeasureType.spinalBoard,
      MeasureType.splinting,
      MeasureType.pelvicBinder,
      MeasureType.vakuummatratze,
      MeasureType.schaufeltrage,
      MeasureType.rettungstuch,
    ].contains(measureType)) {
      return 'Immobilisation';
    }
    
    if ([
      MeasureType.wundverband,
      MeasureType.waermeerhalt,
      MeasureType.kuehlen,
      MeasureType.lagerung,
    ].contains(measureType)) {
      return 'Versorgung';
    }
    
    return 'Sonstige';
  }
}
