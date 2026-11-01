import 'package:flutter_test/flutter_test.dart';
import 'package:smartrent_my/core/validators.dart';
import 'package:smartrent_my/data/demo_vehicles.dart';
import 'package:smartrent_my/models/booking.dart';
import 'package:smartrent_my/models/fuel_price.dart';
import 'package:smartrent_my/services/cost_calculation_service.dart';
import 'package:smartrent_my/services/simulated_stripe_service.dart';

void main() {
  group('Booking date and status rules', () {
    test('detects overlapping dates but allows adjacent bookings', () {
      final overlaps = CostCalculationService.datesOverlap(
        pickup: DateTime(2026, 10, 12),
        returnDate: DateTime(2026, 10, 15),
        existingPickup: DateTime(2026, 10, 10),
        existingReturn: DateTime(2026, 10, 13),
      );
      final adjacent = CostCalculationService.datesOverlap(
        pickup: DateTime(2026, 10, 13),
        returnDate: DateTime(2026, 10, 15),
        existingPickup: DateTime(2026, 10, 10),
        existingReturn: DateTime(2026, 10, 13),
      );

      expect(overlaps, isTrue);
      expect(adjacent, isFalse);
    });

    test('allows only valid booking-status transitions', () {
      expect(
        BookingStatus.confirmed.canTransitionTo(BookingStatus.ongoing),
        isTrue,
      );
      expect(
        BookingStatus.confirmed.canTransitionTo(BookingStatus.cancelled),
        isTrue,
      );
      expect(
        BookingStatus.ongoing.canTransitionTo(BookingStatus.completed),
        isTrue,
      );
      expect(
        BookingStatus.ongoing.canTransitionTo(BookingStatus.cancelled),
        isFalse,
      );
      expect(
        BookingStatus.completed.canTransitionTo(BookingStatus.confirmed),
        isFalse,
      );
      expect(
        BookingStatus.cancelled.canTransitionTo(BookingStatus.confirmed),
        isFalse,
      );
    });

    test('classifies active and closed booking statuses', () {
      expect(BookingStatus.confirmed.isActive, isTrue);
      expect(BookingStatus.ongoing.isActive, isTrue);
      expect(BookingStatus.completed.isClosed, isTrue);
      expect(BookingStatus.cancelled.isClosed, isTrue);
      expect(BookingStatus.confirmed.isClosed, isFalse);
    });

    test('preserves booking details through JSON conversion', () {
      final vehicle = demoVehicles.first;
      final cost = CostCalculationService.calculate(
        vehicle: vehicle,
        fuelPrice: FuelPrice.fallback(),
        rentalDays: 2,
        expectedDistanceKm: 200,
      );
      final booking = Booking(
        id: 'SMR-TEST-1001',
        customerName: 'Demo Student',
        customerEmail: 'student@example.com',
        vehicle: vehicle,
        pickupDate: DateTime(2026, 11, 1),
        returnDate: DateTime(2026, 11, 3),
        expectedDistanceKm: 200,
        cost: cost,
        status: BookingStatus.confirmed,
        createdAt: DateTime(2026, 10, 20),
        updatedAt: DateTime(2026, 10, 20),
        paymentReference: 'pi_test_example',
      );

      final restored = Booking.fromJson(booking.toJson());

      expect(restored.id, booking.id);
      expect(restored.vehicle.id, vehicle.id);
      expect(restored.status, BookingStatus.confirmed);
      expect(restored.cost.totalCost, closeTo(cost.totalCost, 0.001));
      expect(restored.paymentReference, 'pi_test_example');
    });
  });

  group('Payment validation and simulation', () {
    const service = SimulatedStripeService(processingDelay: Duration.zero);

    test('accepts the supported successful test card', () async {
      final result = await service.confirmTestPayment(
        amount: 250,
        cardNumber: '4242 4242 4242 4242',
      );

      expect(result.succeeded, isTrue);
      expect(result.amount, 250);
      expect(result.cardLast4, '4242');
      expect(result.id, startsWith('pi_test_sim_'));
    });

    test('declines the supported declined test card', () async {
      await expectLater(
        service.confirmTestPayment(
          amount: 250,
          cardNumber: '4000 0000 0000 0002',
        ),
        throwsA(
          isA<SimulatedPaymentException>().having(
            (error) => error.message,
            'message',
            contains('declined'),
          ),
        ),
      );
    });

    test('rejects unsupported card numbers and invalid amounts', () async {
      await expectLater(
        service.confirmTestPayment(
          amount: 250,
          cardNumber: '5555 5555 5555 4444',
        ),
        throwsA(isA<SimulatedPaymentException>()),
      );
      await expectLater(
        service.confirmTestPayment(
          amount: 0,
          cardNumber: '4242 4242 4242 4242',
        ),
        throwsA(
          isA<SimulatedPaymentException>().having(
            (error) => error.message,
            'message',
            contains('amount is invalid'),
          ),
        ),
      );
    });

    test('validates cardholder names and positive numeric inputs', () {
      expect(AppValidators.cardholderName('Demo Student'), isNull);
      expect(AppValidators.cardholderName('Demo Student 123'), isNotNull);
      expect(
        AppValidators.positiveNumber('300', label: 'travel distance'),
        isNull,
      );
      expect(
        AppValidators.positiveNumber('0', label: 'travel distance'),
        isNotNull,
      );
      expect(
        AppValidators.positiveNumber('abc', label: 'travel distance'),
        isNotNull,
      );
    });
  });
}
