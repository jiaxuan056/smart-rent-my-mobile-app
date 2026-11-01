import '../services/cost_calculation_service.dart';
import 'vehicle.dart';

class RecommendationCriteria {
  const RecommendationCriteria({
    required this.pickupDate,
    required this.returnDate,
    required this.expectedDistanceKm,
    required this.passengers,
    required this.maximumBudget,
    this.preferredFuel = 'Any',
  });

  final DateTime pickupDate;
  final DateTime returnDate;
  final double expectedDistanceKm;
  final int passengers;
  final double maximumBudget;
  final String preferredFuel;
}

class VehicleRecommendation {
  const VehicleRecommendation({
    required this.vehicle,
    required this.cost,
    required this.score,
    required this.reasons,
  });

  final Vehicle vehicle;
  final TripCost cost;
  final double score;
  final List<String> reasons;
}
