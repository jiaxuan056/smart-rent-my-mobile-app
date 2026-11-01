import '../models/fuel_price.dart';
import '../models/vehicle.dart';

class TripCost {
  const TripCost({
    required this.rentalDays,
    required this.rentalCost,
    required this.energyCost,
    required this.insuranceCost,
    required this.serviceFee,
    required this.totalCost,
    required this.energyQuantity,
    required this.energyUnit,
    required this.energyRate,
  });

  final int rentalDays;
  final double rentalCost;
  final double energyCost;
  final double insuranceCost;
  final double serviceFee;
  final double totalCost;
  final double energyQuantity;
  final String energyUnit;
  final double energyRate;

  factory TripCost.fromJson(Map<String, dynamic> json) {
    double value(String key) {
      final raw = json[key];
      if (raw is num) {
        return raw.toDouble();
      }
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return TripCost(
      rentalDays: (json['rental_days'] as num?)?.toInt() ?? 1,
      rentalCost: value('rental_cost'),
      energyCost: value('energy_cost'),
      insuranceCost: value('insurance_cost'),
      serviceFee: value('service_fee'),
      totalCost: value('total_cost'),
      energyQuantity: value('energy_quantity'),
      energyUnit: json['energy_unit']?.toString() ?? 'L',
      energyRate: value('energy_rate'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rental_days': rentalDays,
      'rental_cost': rentalCost,
      'energy_cost': energyCost,
      'insurance_cost': insuranceCost,
      'service_fee': serviceFee,
      'total_cost': totalCost,
      'energy_quantity': energyQuantity,
      'energy_unit': energyUnit,
      'energy_rate': energyRate,
    };
  }
}

class CostCalculationService {
  static const double chargingRatePerKwh = 1.20;
  static const double insurancePerDay = 12;
  static const double serviceFee = 10;
  static const double minimumExpectedDistanceKm = 1;
  static const double maximumExpectedDistanceKm = 5000;

  static TripCost calculate({
    required Vehicle vehicle,
    required FuelPrice fuelPrice,
    required int rentalDays,
    required double expectedDistanceKm,
  }) {
    final safeDays = rentalDays < 1 ? 1 : rentalDays;
    final safeDistance = expectedDistanceKm.isFinite
        ? expectedDistanceKm.clamp(0, maximumExpectedDistanceKm).toDouble()
        : 0.0;
    final rentalCost = vehicle.dailyRate * safeDays;
    final insuranceCost = insurancePerDay * safeDays;

    double quantity;
    double rate;
    String unit;

    if (vehicle.isElectric) {
      final consumption = vehicle.energyKwhPer100Km ?? 0;
      quantity = safeDistance * consumption / 100;
      rate = chargingRatePerKwh;
      unit = 'kWh';
    } else {
      final efficiency = vehicle.efficiencyKmPerLitre ?? 1;
      quantity = efficiency <= 0 ? 0 : safeDistance / efficiency;
      rate = switch (vehicle.powertrain) {
        VehiclePowertrain.petrolRon97 => fuelPrice.ron97,
        VehiclePowertrain.diesel => fuelPrice.dieselPeninsular,
        VehiclePowertrain.petrolRon95 ||
        VehiclePowertrain.hybridPetrol => fuelPrice.ron95,
        VehiclePowertrain.electric => chargingRatePerKwh,
      };
      unit = 'L';
    }

    final energyCost = quantity * rate;
    final total = rentalCost + energyCost + insuranceCost + serviceFee;

    return TripCost(
      rentalDays: safeDays,
      rentalCost: rentalCost,
      energyCost: energyCost,
      insuranceCost: insuranceCost,
      serviceFee: serviceFee,
      totalCost: total,
      energyQuantity: quantity,
      energyUnit: unit,
      energyRate: rate,
    );
  }

  static int rentalDays(DateTime pickup, DateTime returnDate) {
    final minutes = returnDate.difference(pickup).inMinutes;
    if (minutes <= 0) {
      return 1;
    }
    return (minutes / Duration.minutesPerDay).ceil();
  }

  static bool datesOverlap({
    required DateTime pickup,
    required DateTime returnDate,
    required DateTime existingPickup,
    required DateTime existingReturn,
  }) {
    return pickup.isBefore(existingReturn) &&
        returnDate.isAfter(existingPickup);
  }
}
