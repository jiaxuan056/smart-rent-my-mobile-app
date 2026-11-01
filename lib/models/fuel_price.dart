class FuelPrice {
  const FuelPrice({
    required this.effectiveDate,
    required this.ron95,
    required this.ron97,
    required this.dieselPeninsular,
    required this.dieselEastMalaysia,
    required this.isFallback,
    this.ron95Budi,
    this.ron95Skps,
  });

  final DateTime effectiveDate;
  final double ron95;
  final double ron97;
  final double dieselPeninsular;
  final double dieselEastMalaysia;
  final double? ron95Budi;
  final double? ron95Skps;
  final bool isFallback;

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      effectiveDate:
          DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      ron95: _asDouble(json['ron95']),
      ron97: _asDouble(json['ron97']),
      dieselPeninsular: _asDouble(json['diesel']),
      dieselEastMalaysia: _asDouble(json['diesel_eastmsia']),
      ron95Budi: _nullableDouble(json['ron95_budi95']),
      ron95Skps: _nullableDouble(json['ron95_skps']),
      isFallback: false,
    );
  }

  factory FuelPrice.fallback() {
    return FuelPrice(
      effectiveDate: DateTime(2025, 9, 30),
      ron95: 2.60,
      ron97: 3.18,
      dieselPeninsular: 3.35,
      dieselEastMalaysia: 2.15,
      ron95Budi: 1.99,
      ron95Skps: 2.05,
      isFallback: true,
    );
  }

  static double _asDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }
}
