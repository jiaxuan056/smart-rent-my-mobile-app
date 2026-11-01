import '../models/payment_result.dart';

class SimulatedStripeService {
  const SimulatedStripeService({
    this.processingDelay = const Duration(milliseconds: 1400),
  });

  static const successfulTestCard = '4242424242424242';
  static const declinedTestCard = '4000000000000002';

  final Duration processingDelay;

  Future<PaymentResult> confirmTestPayment({
    required double amount,
    required String cardNumber,
  }) async {
    await Future<void>.delayed(processingDelay);
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (digits == declinedTestCard) {
      throw const SimulatedPaymentException(
        'This test card was declined. Use 4242 4242 4242 4242 for success.',
      );
    }
    if (digits != successfulTestCard) {
      throw const SimulatedPaymentException(
        'Use a supported test card. No real card details are accepted.',
      );
    }
    if (!amount.isFinite || amount <= 0) {
      throw const SimulatedPaymentException('The payment amount is invalid.');
    }

    final timestamp = DateTime.now();
    return PaymentResult(
      id: 'pi_test_sim_${timestamp.microsecondsSinceEpoch}',
      status: PaymentStatus.succeeded,
      amount: amount,
      cardLast4: digits.substring(digits.length - 4),
      createdAt: timestamp,
    );
  }
}

class SimulatedPaymentException implements Exception {
  const SimulatedPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
