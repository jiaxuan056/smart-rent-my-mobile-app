import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartrent_my/models/booking.dart';
import 'package:smartrent_my/models/vehicle.dart';
import 'package:smartrent_my/services/government_data_service.dart';
import 'package:smartrent_my/services/local_account_service.dart';
import 'package:smartrent_my/services/local_app_data_service.dart';
import 'package:smartrent_my/state/app_state.dart';

void main() {
  group('Admin management', () {
    late Directory directory;
    late AppState appState;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'smartrent_admin_member_test_',
      );
      appState = AppState(
        GovernmentDataService(),
        localAccountService: LocalAccountService(storageDirectory: directory),
        localAppDataService: LocalAppDataService(storageDirectory: directory),
      );
      await appState.initialize(loadRemoteData: false);
    });

    tearDown(() async {
      await appState.flushData();
      appState.dispose();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('prevents customers from using administrator operations', () {
      appState.enterDemoMode();

      expect(
        appState.updateBookingStatus('SMR-DEMO-1004', BookingStatus.ongoing),
        'Administrator access is required.',
      );
      expect(
        appState.changeVehicleAvailability(
          appState.allVehicles.first.id,
          VehicleAvailability.maintenance,
        ),
        'Administrator access is required.',
      );
    });

    test('allows an administrator to perform a valid status transition', () {
      appState.enterAdminMode();

      expect(
        appState.updateBookingStatus('SMR-DEMO-1004', BookingStatus.ongoing),
        isNull,
      );
      final updated = appState.allBookings.firstWhere(
        (booking) => booking.id == 'SMR-DEMO-1004',
      );

      expect(updated.status, BookingStatus.ongoing);
      expect(
        appState.updateBookingStatus('SMR-DEMO-1004', BookingStatus.cancelled),
        contains('cannot be changed'),
      );
    });

    test('validates and manages an administrator-created vehicle', () {
      appState.enterAdminMode();
      const validVehicle = Vehicle(
        id: 'admin-test-vehicle',
        imageAsset: '',
        brand: 'Test',
        model: 'Vehicle',
        year: 2026,
        category: 'Sedan',
        powertrain: VehiclePowertrain.petrolRon95,
        transmission: 'Automatic',
        seats: 5,
        dailyRate: 150,
        branch: 'George Town',
        rating: 4.5,
        description: 'Vehicle used by the administrator automated test.',
        colorValue: 0xFF0F766E,
        efficiencyKmPerLitre: 18,
      );
      final invalidVehicle = validVehicle.copyWith(dailyRate: 0);

      expect(appState.saveVehicle(invalidVehicle), isNotNull);
      expect(appState.saveVehicle(validVehicle), isNull);
      expect(
        appState.allVehicles.any((vehicle) => vehicle.id == validVehicle.id),
        isTrue,
      );

      expect(
        appState.changeVehicleAvailability(
          validVehicle.id,
          VehicleAvailability.maintenance,
        ),
        isNull,
      );
      final maintained = appState.allVehicles.firstWhere(
        (vehicle) => vehicle.id == validVehicle.id,
      );
      expect(maintained.canBeBooked, isFalse);

      expect(
        appState.changeVehicleAvailability(
          validVehicle.id,
          VehicleAvailability.deactivated,
        ),
        isNull,
      );
      expect(
        appState.vehicles.any((vehicle) => vehicle.id == validVehicle.id),
        isFalse,
      );
      expect(
        appState.allVehicles.any((vehicle) => vehicle.id == validVehicle.id),
        isTrue,
      );
    });

    test('allows an administrator to hide and restore a review', () {
      appState.enterDemoMode();
      expect(
        appState.submitReview(
          bookingId: 'SMR-DEMO-1002',
          rating: 5,
          comment: 'Comfortable vehicle and helpful rental service.',
        ),
        isNull,
      );
      final review = appState.allReviews.single;

      appState.enterAdminMode();
      expect(appState.setReviewHidden(review.id, true), isNull);
      expect(
        appState.allReviews
            .singleWhere((item) => item.id == review.id)
            .isHidden,
        isTrue,
      );
      expect(appState.reviewsForVehicle(review.vehicleId), isEmpty);

      expect(appState.setReviewHidden(review.id, false), isNull);
      expect(appState.reviewsForVehicle(review.vehicleId), hasLength(1));
    });

    test('combines hybrid registration categories for analytics', () {
      final petrolHybrid = appState.trendFor('hybrid_petrol');
      final dieselHybrid = appState.trendFor('hybrid_diesel');
      final combined = appState.trendFor('hybrid');

      expect(combined, hasLength(12));
      expect(
        combined.last.registrations,
        petrolHybrid.last.registrations + dieselHybrid.last.registrations,
      );
    });
  });
}
