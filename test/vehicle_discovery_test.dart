import 'package:flutter_test/flutter_test.dart';
import 'package:smartrent_my/data/demo_vehicles.dart';
import 'package:smartrent_my/models/fuel_price.dart';
import 'package:smartrent_my/models/recommendation.dart';
import 'package:smartrent_my/models/vehicle.dart';
import 'package:smartrent_my/services/cost_calculation_service.dart';
import 'package:smartrent_my/services/recommendation_service.dart';

void main() {
  final fuelPrice = FuelPrice.fallback();

  group('Vehicle discovery data', () {
    test('catalogue provides searchable names and filter categories', () {
      final searchResults = demoVehicles.where(
        (vehicle) => vehicle.name.toLowerCase().contains('perodua'),
      );
      final fuelLabels = demoVehicles
          .map((vehicle) => vehicle.powertrain.filterLabel)
          .toSet();

      expect(searchResults, isNotEmpty);
      expect(
        searchResults.every(
          (vehicle) => vehicle.brand.toLowerCase() == 'perodua',
        ),
        isTrue,
      );
      expect(fuelLabels, containsAll(<String>['Petrol', 'Hybrid', 'Electric']));
      expect(demoVehicles.every((vehicle) => vehicle.dailyRate > 0), isTrue);
    });

    test('unavailable vehicles cannot be booked', () {
      final unavailable = demoVehicles.first.copyWith(
        availability: VehicleAvailability.maintenance,
      );
      final deactivated = demoVehicles.first.copyWith(
        availability: VehicleAvailability.deactivated,
      );

      expect(demoVehicles.first.canBeBooked, isTrue);
      expect(unavailable.canBeBooked, isFalse);
      expect(deactivated.canBeBooked, isFalse);
    });
  });

  group('Trip-cost calculations', () {
    test('calculates a petrol vehicle trip using official fuel values', () {
      final myvi = demoVehicles.firstWhere(
        (vehicle) => vehicle.id == 'myvi-2025',
      );
      final cost = CostCalculationService.calculate(
        vehicle: myvi,
        fuelPrice: fuelPrice,
        rentalDays: 3,
        expectedDistanceKm: 350,
      );

      expect(cost.rentalCost, 360);
      expect(cost.energyUnit, 'L');
      expect(cost.energyQuantity, closeTo(20, 0.001));
      expect(cost.energyCost, closeTo(52, 0.001));
      expect(cost.totalCost, closeTo(458, 0.001));
    });

    test('calculates an electric vehicle trip in kWh', () {
      final dolphin = demoVehicles.firstWhere(
        (vehicle) => vehicle.id == 'dolphin-2025',
      );
      final cost = CostCalculationService.calculate(
        vehicle: dolphin,
        fuelPrice: fuelPrice,
        rentalDays: 2,
        expectedDistanceKm: 250,
      );

      expect(cost.energyUnit, 'kWh');
      expect(cost.energyQuantity, closeTo(40, 0.001));
      expect(cost.energyRate, CostCalculationService.chargingRatePerKwh);
      expect(cost.energyCost, closeTo(48, 0.001));
      expect(cost.totalCost, closeTo(502, 0.001));
    });

    test('rounds a partial rental day up to a complete day', () {
      final pickup = DateTime(2026, 9, 1, 10);

      expect(
        CostCalculationService.rentalDays(pickup, DateTime(2026, 9, 2, 9)),
        1,
      );
      expect(
        CostCalculationService.rentalDays(pickup, DateTime(2026, 9, 2, 11)),
        2,
      );
    });
  });

  group('Smart recommendations', () {
    test('respects fuel preference, seats, budget and availability', () {
      final results = RecommendationService.rank(
        vehicles: demoVehicles,
        fuelPrice: fuelPrice,
        criteria: RecommendationCriteria(
          pickupDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 3),
          expectedDistanceKm: 200,
          passengers: 5,
          maximumBudget: 2000,
          preferredFuel: 'Electric',
        ),
        isAvailable: (vehicle) => vehicle.id != 'atto3-2025',
      );

      expect(results, isNotEmpty);
      expect(
        results.every(
          (item) => item.vehicle.powertrain == VehiclePowertrain.electric,
        ),
        isTrue,
      );
      expect(results.every((item) => item.vehicle.id != 'atto3-2025'), isTrue);
      expect(results.every((item) => item.cost.totalCost <= 2000), isTrue);
    });

    test('returns no recommendation when the budget is too low', () {
      final results = RecommendationService.rank(
        vehicles: demoVehicles,
        fuelPrice: fuelPrice,
        criteria: RecommendationCriteria(
          pickupDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 4),
          expectedDistanceKm: 300,
          passengers: 5,
          maximumBudget: 50,
        ),
        isAvailable: (_) => true,
      );

      expect(results, isEmpty);
    });

    test('sorts recommendations from highest to lowest score', () {
      final results = RecommendationService.rank(
        vehicles: demoVehicles,
        fuelPrice: fuelPrice,
        criteria: RecommendationCriteria(
          pickupDate: DateTime(2026, 10, 1),
          returnDate: DateTime(2026, 10, 2),
          expectedDistanceKm: 100,
          passengers: 4,
          maximumBudget: 1000,
        ),
        isAvailable: (_) => true,
      );

      expect(results.length, greaterThan(1));
      for (var index = 1; index < results.length; index++) {
        expect(
          results[index - 1].score,
          greaterThanOrEqualTo(results[index].score),
        );
      }
    });
  });
}
