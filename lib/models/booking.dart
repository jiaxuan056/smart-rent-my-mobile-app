import '../services/cost_calculation_service.dart';
import 'vehicle.dart';

enum BookingStatus { confirmed, ongoing, completed, cancelled }

extension BookingStatusDetails on BookingStatus {
  String get label {
    return switch (this) {
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.ongoing => 'Ongoing',
      BookingStatus.completed => 'Completed',
      BookingStatus.cancelled => 'Cancelled',
    };
  }

  bool get isActive =>
      this == BookingStatus.confirmed || this == BookingStatus.ongoing;
  bool get isClosed =>
      this == BookingStatus.completed || this == BookingStatus.cancelled;

  bool canTransitionTo(BookingStatus next) {
    return switch (this) {
      BookingStatus.confirmed =>
        next == BookingStatus.ongoing || next == BookingStatus.cancelled,
      BookingStatus.ongoing => next == BookingStatus.completed,
      BookingStatus.completed || BookingStatus.cancelled => false,
    };
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.vehicle,
    required this.pickupDate,
    required this.returnDate,
    required this.expectedDistanceKm,
    required this.cost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paymentReference,
  });

  final String id;
  final String customerName;
  final String customerEmail;
  final Vehicle vehicle;
  final DateTime pickupDate;
  final DateTime returnDate;
  final double expectedDistanceKm;
  final TripCost cost;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentReference;

  Booking copyWith({BookingStatus? status, DateTime? updatedAt}) {
    return Booking(
      id: id,
      customerName: customerName,
      customerEmail: customerEmail,
      vehicle: vehicle,
      pickupDate: pickupDate,
      returnDate: returnDate,
      expectedDistanceKm: expectedDistanceKm,
      cost: cost,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentReference: paymentReference,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'SmartRent customer',
      customerEmail: json['customer_email']?.toString() ?? '',
      vehicle: Vehicle.fromJson(
        Map<String, dynamic>.from(json['vehicle'] as Map? ?? const {}),
      ),
      pickupDate:
          DateTime.tryParse(json['pickup_date']?.toString() ?? '') ??
          DateTime.now(),
      returnDate:
          DateTime.tryParse(json['return_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      expectedDistanceKm: _asDouble(json['expected_distance_km']),
      cost: TripCost.fromJson(
        Map<String, dynamic>.from(json['cost'] as Map? ?? const {}),
      ),
      status: _statusFromName(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      paymentReference: json['payment_reference']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'vehicle': vehicle.toJson(),
      'pickup_date': pickupDate.toIso8601String(),
      'return_date': returnDate.toIso8601String(),
      'expected_distance_km': expectedDistanceKm,
      'cost': cost.toJson(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'payment_reference': paymentReference,
    };
  }
}

BookingStatus _statusFromName(String? name) {
  for (final status in BookingStatus.values) {
    if (status.name == name) {
      return status;
    }
  }
  return BookingStatus.confirmed;
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
