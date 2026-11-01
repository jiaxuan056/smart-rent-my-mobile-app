class VehicleReview {
  const VehicleReview({
    required this.id,
    required this.bookingId,
    required this.vehicleId,
    required this.vehicleName,
    required this.customerEmail,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isHidden = false,
  });

  final String id;
  final String bookingId;
  final String vehicleId;
  final String vehicleName;
  final String customerEmail;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool isHidden;

  VehicleReview copyWith({bool? isHidden}) {
    return VehicleReview(
      id: id,
      bookingId: bookingId,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      customerEmail: customerEmail,
      customerName: customerName,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  factory VehicleReview.fromJson(Map<String, dynamic> json) {
    return VehicleReview(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      vehicleName: json['vehicle_name']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isHidden: json['is_hidden'] is bool ? json['is_hidden'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'customer_email': customerEmail,
      'customer_name': customerName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'is_hidden': isHidden,
    };
  }
}
