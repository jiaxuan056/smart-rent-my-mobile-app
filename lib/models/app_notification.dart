class AppNotificationRecord {
  const AppNotificationRecord({
    required this.id,
    required this.recipientEmail,
    required this.title,
    required this.message,
    required this.createdAt,
    this.bookingId,
    this.isRead = false,
  });

  final String id;
  final String recipientEmail;
  final String title;
  final String message;
  final String? bookingId;
  final DateTime createdAt;
  final bool isRead;

  AppNotificationRecord copyWith({bool? isRead}) {
    return AppNotificationRecord(
      id: id,
      recipientEmail: recipientEmail,
      title: title,
      message: message,
      bookingId: bookingId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotificationRecord.fromJson(Map<String, dynamic> json) {
    return AppNotificationRecord(
      id: json['id']?.toString() ?? '',
      recipientEmail: json['recipient_email']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      bookingId: json['booking_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] is bool ? json['is_read'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_email': recipientEmail,
      'title': title,
      'message': message,
      'booking_id': bookingId,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
