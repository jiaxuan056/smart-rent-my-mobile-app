class RegistrationRecord {
  const RegistrationRecord({
    required this.date,
    required this.fuel,
    required this.registrations,
  });

  final DateTime date;
  final String fuel;
  final int registrations;

  factory RegistrationRecord.fromJson(Map<String, dynamic> json) {
    final normalizedFuel = (json['fuel']?.toString() ?? 'unknown')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    return RegistrationRecord(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      fuel: normalizedFuel,
      registrations: int.tryParse(json['registrations']?.toString() ?? '') ?? 0,
    );
  }
}
