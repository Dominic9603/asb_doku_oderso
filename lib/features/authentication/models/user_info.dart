/// Speichert personalisierte Benutzerinformationen
class UserInfo {
  final String firstName;
  final String lastName;
  final String shortSign; // z.B. "JD" für John Doe
  final String recipientEmail; // Empfänger-Email für PDF-Versand

  UserInfo({
    required this.firstName,
    required this.lastName,
    required this.shortSign,
    this.recipientEmail = '',
  });

  /// Vollständiger Name
  String get fullName => '$firstName $lastName';

  /// Zu JSON für Speicherung
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'shortSign': shortSign,
      'recipientEmail': recipientEmail,
    };
  }

  /// Aus JSON laden
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      shortSign: json['shortSign'] as String? ?? '',
      recipientEmail: json['recipientEmail'] as String? ?? '',
    );
  }

  @override
  String toString() => '$fullName ($shortSign)';
}
