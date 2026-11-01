enum VehiclePowertrain {
  petrolRon95,
  petrolRon97,
  diesel,
  hybridPetrol,
  electric,
}

extension VehiclePowertrainDetails on VehiclePowertrain {
  String get label {
    return switch (this) {
      VehiclePowertrain.petrolRon95 => 'Petrol · RON95',
      VehiclePowertrain.petrolRon97 => 'Petrol · RON97',
      VehiclePowertrain.diesel => 'Diesel',
      VehiclePowertrain.hybridPetrol => 'Hybrid petrol',
      VehiclePowertrain.electric => 'Electric',
    };
  }

  String get filterLabel {
    return switch (this) {
      VehiclePowertrain.petrolRon95 ||
      VehiclePowertrain.petrolRon97 => 'Petrol',
      VehiclePowertrain.diesel => 'Diesel',
      VehiclePowertrain.hybridPetrol => 'Hybrid',
      VehiclePowertrain.electric => 'Electric',
    };
  }
}

enum VehicleAvailability { available, unavailable, maintenance, deactivated }

extension VehicleAvailabilityDetails on VehicleAvailability {
  String get label {
    return switch (this) {
      VehicleAvailability.available => 'Available',
      VehicleAvailability.unavailable => 'Unavailable',
      VehicleAvailability.maintenance => 'Under maintenance',
      VehicleAvailability.deactivated => 'Deactivated',
    };
  }

  bool get canBeBooked => this == VehicleAvailability.available;
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.imageAsset,
    required this.brand,
    required this.model,
    required this.year,
    required this.category,
    required this.powertrain,
    required this.transmission,
    required this.seats,
    required this.dailyRate,
    required this.branch,
    required this.rating,
    required this.description,
    required this.colorValue,
    this.efficiencyKmPerLitre,
    this.energyKwhPer100Km,
    this.imageUrl,
    this.imageLocalPath,
    this.sourceName,
    this.sourceUrl,
    this.availability = VehicleAvailability.available,
    this.createdAt,
  });

  final String id;
  final String imageAsset;
  final String? imageUrl;
  final String? imageLocalPath;
  final String brand;
  final String model;
  final int year;
  final String category;
  final VehiclePowertrain powertrain;
  final String transmission;
  final int seats;
  final double dailyRate;
  final String branch;
  final double rating;
  final String description;
  final int colorValue;
  final double? efficiencyKmPerLitre;
  final double? energyKwhPer100Km;
  final String? sourceName;
  final String? sourceUrl;
  final VehicleAvailability availability;
  final DateTime? createdAt;

  String get name => '$brand $model';
  bool get isElectric => powertrain == VehiclePowertrain.electric;
  bool get canBeBooked => availability.canBeBooked;

  String get efficiencyLabel {
    if (isElectric) {
      return '${energyKwhPer100Km?.toStringAsFixed(1) ?? '—'} kWh/100 km';
    }
    return '${efficiencyKmPerLitre?.toStringAsFixed(1) ?? '—'} km/L';
  }

  Vehicle copyWith({
    String? imageAsset,
    String? imageUrl,
    String? imageLocalPath,
    String? brand,
    String? model,
    int? year,
    String? category,
    VehiclePowertrain? powertrain,
    String? transmission,
    int? seats,
    double? dailyRate,
    String? branch,
    double? rating,
    String? description,
    int? colorValue,
    double? efficiencyKmPerLitre,
    double? energyKwhPer100Km,
    String? sourceName,
    String? sourceUrl,
    VehicleAvailability? availability,
  }) {
    return Vehicle(
      id: id,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      category: category ?? this.category,
      powertrain: powertrain ?? this.powertrain,
      transmission: transmission ?? this.transmission,
      seats: seats ?? this.seats,
      dailyRate: dailyRate ?? this.dailyRate,
      branch: branch ?? this.branch,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      efficiencyKmPerLitre: efficiencyKmPerLitre ?? this.efficiencyKmPerLitre,
      energyKwhPer100Km: energyKwhPer100Km ?? this.energyKwhPer100Km,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      availability: availability ?? this.availability,
      createdAt: createdAt,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      imageAsset: json['image_asset']?.toString() ?? '',
      imageUrl: _nullableString(json['image_url']),
      imageLocalPath: _nullableString(json['image_local_path']),
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: _asInt(json['year'], 2025),
      category: json['category']?.toString() ?? 'Car',
      powertrain: _enumByName(
        VehiclePowertrain.values,
        json['powertrain']?.toString(),
        VehiclePowertrain.petrolRon95,
      ),
      transmission: json['transmission']?.toString() ?? 'Automatic',
      seats: _asInt(json['seats'], 5),
      dailyRate: _asDouble(json['daily_rate'], 0),
      branch: json['branch']?.toString() ?? '',
      rating: _asDouble(json['rating'], 0),
      description: json['description']?.toString() ?? '',
      colorValue: _asInt(json['color_value'], 0xFF0F766E),
      efficiencyKmPerLitre: _nullableDouble(json['efficiency_km_per_litre']),
      energyKwhPer100Km: _nullableDouble(json['energy_kwh_per_100_km']),
      sourceName: _nullableString(json['source_name']),
      sourceUrl: _nullableString(json['source_url']),
      availability: _enumByName(
        VehicleAvailability.values,
        json['availability']?.toString(),
        VehicleAvailability.available,
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_asset': imageAsset,
      'image_url': imageUrl,
      'image_local_path': imageLocalPath,
      'brand': brand,
      'model': model,
      'year': year,
      'category': category,
      'powertrain': powertrain.name,
      'transmission': transmission,
      'seats': seats,
      'daily_rate': dailyRate,
      'branch': branch,
      'rating': rating,
      'description': description,
      'color_value': colorValue,
      'efficiency_km_per_litre': efficiencyKmPerLitre,
      'energy_kwh_per_100_km': energyKwhPer100Km,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'availability': availability.name,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

int _asInt(Object? value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  return _asDouble(value, 0);
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
