import '../models/fuel_price.dart';
import '../models/recommendation.dart';
import '../models/vehicle.dart';
import 'cost_calculation_service.dart';

class RecommendationService {
  const RecommendationService._();

  static List<VehicleRecommendation> rank({
    required Iterable<Vehicle> vehicles,
    required FuelPrice fuelPrice,
    required RecommendationCriteria criteria,
    required bool Function(Vehicle vehicle) isAvailable,
  }) {
    final days = CostCalculationService.rentalDays(
      criteria.pickupDate,
      criteria.returnDate,
    );
    final results = <VehicleRecommendation>[];

    for (final vehicle in vehicles) {
      if (!vehicle.canBeBooked ||
          vehicle.seats < criteria.passengers ||
          !isAvailable(vehicle)) {
        continue;
      }
      if (criteria.preferredFuel != 'Any' &&
          vehicle.powertrain.filterLabel != criteria.preferredFuel) {
        continue;
      }
      final cost = CostCalculationService.calculate(
        vehicle: vehicle,
        fuelPrice: fuelPrice,
        rentalDays: days,
        expectedDistanceKm: criteria.expectedDistanceKm,
      );
      if (cost.totalCost > criteria.maximumBudget) {
        continue;
      }

      final budgetRatio = criteria.maximumBudget <= 0
          ? 1.0
          : cost.totalCost / criteria.maximumBudget;
      final seatFit = vehicle.seats == criteria.passengers ? 1.0 : 0.75;
      final efficiencyScore = vehicle.isElectric
          ? 0.82
          : ((vehicle.efficiencyKmPerLitre ?? 10) / 25).clamp(0.0, 1.0);
      final score =
          (1 - budgetRatio).clamp(0.0, 1.0) * 55 +
          seatFit * 15 +
          efficiencyScore * 15 +
          (vehicle.rating / 5).clamp(0.0, 1.0) * 15;
      final savings = criteria.maximumBudget - cost.totalCost;
      final reasons = <String>[
        '${savings.toStringAsFixed(0)} RM remains within your budget',
        '${vehicle.seats} seats suit ${criteria.passengers} ${criteria.passengers == 1 ? 'passenger' : 'passengers'}',
        '${vehicle.efficiencyLabel} efficiency',
      ];
      results.add(
        VehicleRecommendation(
          vehicle: vehicle,
          cost: cost,
          score: score,
          reasons: reasons,
        ),
      );
    }

    results.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0
          ? scoreOrder
          : a.cost.totalCost.compareTo(b.cost.totalCost);
    });
    return results;
  }
}
