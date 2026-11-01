enum PaymentStatus { succeeded, declined }

class PaymentResult {
  const PaymentResult({
    required this.id,
    required this.status,
    required this.amount,
    required this.cardLast4,
    required this.createdAt,
  });

  final String id;
  final PaymentStatus status;
  final double amount;
  final String cardLast4;
  final DateTime createdAt;

  bool get succeeded => status == PaymentStatus.succeeded;
}
