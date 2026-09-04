enum Gender { male, female, diverse, unknown }

class Patient {
  final String id;
  final String missionId;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? address;
  final String? insurance;

  Patient({
    required this.id,
    required this.missionId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.insurance,
  });

  factory Patient.create(String missionId) {
    return Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      missionId: missionId,
    );
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_of_birth'] as int)
          : null,
      gender: map['gender'] != null
          ? Gender.values.firstWhere((e) => e.name == map['gender'])
          : null,
      address: map['address'] as String?,
      insurance: map['insurance'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mission_id': missionId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.millisecondsSinceEpoch,
      'gender': gender?.name,
      'address': address,
      'insurance': insurance,
    };
  }

  Patient copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    Gender? gender,
    String? address,
    String? insurance,
  }) {
    return Patient(
      id: id,
      missionId: missionId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      insurance: insurance ?? this.insurance,
    );
  }

  String get fullName {
    if (firstName == null && lastName == null) return 'Unbekannter Patient';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}
