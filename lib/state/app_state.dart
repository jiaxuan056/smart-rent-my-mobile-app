import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/demo_vehicles.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/fuel_price.dart';
import '../models/local_account.dart';
import '../models/recommendation.dart';
import '../models/registration_record.dart';
import '../models/vehicle.dart';
import '../models/vehicle_review.dart';
import '../services/cost_calculation_service.dart';
import '../services/government_data_service.dart';
import '../services/local_account_service.dart';
import '../services/local_app_data_service.dart';
import '../services/recommendation_service.dart';

class AppState extends ChangeNotifier {
  AppState(
    this._governmentDataService, {
    LocalAccountService? localAccountService,
    LocalAppDataService? localAppDataService,
  }) : _localAccountService = localAccountService ?? LocalAccountService(),
       _localAppDataService = localAppDataService ?? LocalAppDataService();

  final GovernmentDataService _governmentDataService;
  final LocalAccountService _localAccountService;
  final LocalAppDataService _localAppDataService;
  final List<Vehicle> _vehicles = [];
  final List<Booking> _bookings = [];
  final List<VehicleReview> _reviews = [];
  final List<AppNotificationRecord> _notifications = [];
  final List<LocalAccount> _registeredAccounts = [];
  final Map<String, Set<String>> _favouritesByUser = {};
  final Set<String> _comparisonIds = {};
  LocalAccount? _activeAccount;
  Future<void> _saveQueue = Future<void>.value();

  bool isInitializing = true;
  bool isSignedIn = false;
  bool isDemoAccount = false;
  AccountRole currentRole = AccountRole.customer;
  String userName = 'Demo Student';
  String userEmail = 'student@smartrent.my';
  String userPhone = '';
  String? userAvatarPath;
  int navigationIndex = 0;
  FuelPrice fuelPrice = FuelPrice.fallback();
  List<RegistrationRecord> registrationRecords = [];
  bool isFuelLoading = false;
  bool isTrendLoading = false;
  bool trendsAreFallback = true;
  Set<String> trendFallbackFuels = {};
  String? accountError;
  String? dataError;
  String? fuelError;
  String? trendError;

  bool get isAdmin => currentRole == AccountRole.admin;

  List<Vehicle> get vehicles => List.unmodifiable(
    _vehicles.where(
      (vehicle) => vehicle.availability != VehicleAvailability.deactivated,
    ),
  );

  List<Vehicle> get allVehicles => List.unmodifiable(_vehicles);
  List<Booking> get allBookings => List.unmodifiable(_bookings);
  List<VehicleReview> get allReviews => List.unmodifiable(_reviews);
  List<LocalAccount> get registeredAccounts =>
      List.unmodifiable(_registeredAccounts);

  List<Booking> get bookings {
    if (isAdmin) {
      return allBookings;
    }
    final email = _normalizedUserEmail;
    return List.unmodifiable(
      _bookings.where(
        (booking) => booking.customerEmail.toLowerCase() == email,
      ),
    );
  }

  List<Booking> get activeBookings =>
      bookings.where((booking) => booking.status.isActive).toList();

  List<Booking> get bookingHistory =>
      bookings.where((booking) => booking.status.isClosed).toList();

  Set<String> get favouriteIds => Set.unmodifiable(
    _favouritesByUser[_normalizedUserEmail] ?? const <String>{},
  );

  Set<String> get comparisonIds => Set.unmodifiable(_comparisonIds);

  List<Vehicle> get favouriteVehicles =>
      vehicles.where((vehicle) => favouriteIds.contains(vehicle.id)).toList();

  List<Vehicle> get comparisonVehicles =>
      vehicles.where((vehicle) => _comparisonIds.contains(vehicle.id)).toList();

  List<AppNotificationRecord> get notifications {
    final email = _normalizedUserEmail;
    final values =
        _notifications
            .where((item) => item.recipientEmail.toLowerCase() == email)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(values);
  }

  int get unreadNotificationCount =>
      notifications.where((item) => !item.isRead).length;

  Future<void> initialize({bool loadRemoteData = true}) async {
    registrationRecords = _governmentDataService.fallbackRegistrations();
    trendFallbackFuels = Set.of(GovernmentDataService.supportedFuelTypes);
    try {
      _registeredAccounts
        ..clear()
        ..addAll(await _localAccountService.loadAccounts());
    } on AccountException catch (error) {
      accountError = error.message;
    }

    try {
      final snapshot = await _localAppDataService.load();
      _mergeVehicles(snapshot.vehicles);
      _bookings.addAll(snapshot.bookings);
      _reviews.addAll(snapshot.reviews);
      _notifications.addAll(snapshot.notifications);
      _favouritesByUser.addAll(snapshot.favouritesByUser);
    } on LocalDataException catch (error) {
      dataError = error.message;
      _mergeVehicles(const []);
    }
    if (_vehicles.isEmpty) {
      _vehicles.addAll(demoVehicles);
    }
    if (_bookings.isEmpty) {
      _bookings.addAll(_buildDemoBookings());
    }

    if (loadRemoteData) {
      await Future.wait([refreshFuelPrice(), refreshTrends()]);
    }
    isInitializing = false;
    notifyListeners();
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final account = await _localAccountService.authenticate(
        email: email,
        password: password,
      );
      if (!account.isActive) {
        return 'This account is inactive. Contact SmartRent MY staff.';
      }
      _applyAccount(account);
      isDemoAccount = false;
      isSignedIn = true;
      accountError = null;
      notifyListeners();
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String securityPhrase,
  }) async {
    try {
      final account = await _localAccountService.register(
        displayName: name,
        email: email,
        password: password,
        securityPhrase: securityPhrase,
      );
      _registeredAccounts.add(account);
      _applyAccount(account);
      isDemoAccount = false;
      isSignedIn = true;
      accountError = null;
      notifyListeners();
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  void enterDemoMode() {
    _activeAccount = null;
    userName = 'Demo Student';
    userEmail = 'student@smartrent.my';
    userPhone = '';
    userAvatarPath = null;
    currentRole = AccountRole.customer;
    isDemoAccount = true;
    isSignedIn = true;
    navigationIndex = 0;
    notifyListeners();
  }

  void enterAdminMode() {
    _activeAccount = null;
    userName = 'SmartRent Administrator';
    userEmail = 'admin@smartrent.my';
    userPhone = '04-555 0188';
    userAvatarPath = null;
    currentRole = AccountRole.admin;
    isDemoAccount = true;
    isSignedIn = true;
    navigationIndex = 0;
    notifyListeners();
  }

  Future<String?> recoverPassword({
    required String email,
    required String securityPhrase,
    required String newPassword,
  }) async {
    try {
      await _localAccountService.recoverPassword(
        email: email,
        securityPhrase: securityPhrase,
        newPassword: newPassword,
      );
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateProfile({
    required String displayName,
    required String phone,
  }) async {
    final activeAccount = _activeAccount;
    if (activeAccount == null) {
      userName = displayName.trim();
      userPhone = phone.trim();
      notifyListeners();
      return null;
    }
    try {
      final updated = await _localAccountService.updateProfile(
        account: activeAccount,
        displayName: displayName,
        phone: phone,
      );
      _replaceRegisteredAccount(updated);
      _applyAccount(updated);
      notifyListeners();
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final activeAccount = _activeAccount;
    if (activeAccount == null) {
      return 'Register a local account before changing its password.';
    }
    try {
      final updated = await _localAccountService.changePassword(
        account: activeAccount,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _replaceRegisteredAccount(updated);
      _applyAccount(updated);
      notifyListeners();
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateAvatar(String avatarPath) async {
    final activeAccount = _activeAccount;
    if (activeAccount == null) {
      userAvatarPath = avatarPath;
      notifyListeners();
      return null;
    }
    try {
      final updated = await _localAccountService.updateAvatar(
        account: activeAccount,
        avatarPath: avatarPath,
      );
      _replaceRegisteredAccount(updated);
      _applyAccount(updated);
      notifyListeners();
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  Future<String?> removeAvatar() async {
    final activeAccount = _activeAccount;
    if (activeAccount == null) {
      userAvatarPath = null;
      notifyListeners();
      return null;
    }
    try {
      final updated = await _localAccountService.updateAvatar(
        account: activeAccount,
        remove: true,
      );
      _replaceRegisteredAccount(updated);
      _applyAccount(updated);
      notifyListeners();
      return null;
    } on AccountException catch (error) {
      return error.message;
    }
  }

  Future<void> refreshFuelPrice() async {
    isFuelLoading = true;
    fuelError = null;
    notifyListeners();
    try {
      fuelPrice = await _governmentDataService.fetchLatestFuelPrice();
    } on GovernmentDataException catch (error) {
      fuelPrice = FuelPrice.fallback();
      fuelError = error.message;
    } finally {
      isFuelLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTrends() async {
    isTrendLoading = true;
    trendError = null;
    notifyListeners();
    try {
      final liveRecords = await _governmentDataService
          .fetchVehicleRegistrations();
      final liveFuels = liveRecords.map((record) => record.fuel).toSet();
      final missingFuels = GovernmentDataService.supportedFuelTypes.difference(
        liveFuels,
      );
      final fallbackRecords = _governmentDataService
          .fallbackRegistrations()
          .where((record) => missingFuels.contains(record.fuel));
      registrationRecords = [...liveRecords, ...fallbackRecords];
      trendFallbackFuels = missingFuels;
      trendsAreFallback =
          missingFuels.length ==
          GovernmentDataService.supportedFuelTypes.length;
      if (missingFuels.isNotEmpty) {
        trendError =
            'The live API omitted ${missingFuels.map(_fuelLabel).join(', ')}. '
            'Fallback values are shown only for those categories.';
      }
    } on GovernmentDataException catch (error) {
      registrationRecords = _governmentDataService.fallbackRegistrations();
      trendFallbackFuels = Set.of(GovernmentDataService.supportedFuelTypes);
      trendsAreFallback = true;
      trendError = error.message;
    } finally {
      isTrendLoading = false;
      notifyListeners();
    }
  }

  void setNavigationIndex(int value) {
    navigationIndex = value;
    notifyListeners();
  }

  void signOut() {
    _activeAccount = null;
    isSignedIn = false;
    isDemoAccount = false;
    currentRole = AccountRole.customer;
    userName = 'Demo Student';
    userEmail = 'student@smartrent.my';
    userPhone = '';
    userAvatarPath = null;
    navigationIndex = 0;
    _comparisonIds.clear();
    notifyListeners();
  }

  void toggleFavourite(String vehicleId) {
    final favourites = _favouritesByUser.putIfAbsent(
      _normalizedUserEmail,
      () => <String>{},
    );
    if (!favourites.add(vehicleId)) {
      favourites.remove(vehicleId);
    }
    _schedulePersist();
    notifyListeners();
  }

  bool toggleComparison(String vehicleId) {
    if (_comparisonIds.contains(vehicleId)) {
      _comparisonIds.remove(vehicleId);
      notifyListeners();
      return true;
    }
    if (_comparisonIds.length >= 3) {
      return false;
    }
    _comparisonIds.add(vehicleId);
    notifyListeners();
    return true;
  }

  void clearComparison() {
    _comparisonIds.clear();
    notifyListeners();
  }

  bool isVehicleAvailable(
    String vehicleId,
    DateTime pickup,
    DateTime returnDate,
  ) {
    final vehicle = _vehicles.where((item) => item.id == vehicleId).firstOrNull;
    if (vehicle == null || !vehicle.canBeBooked) {
      return false;
    }
    return !_bookings.any(
      (booking) =>
          booking.vehicle.id == vehicleId &&
          booking.status.isActive &&
          CostCalculationService.datesOverlap(
            pickup: pickup,
            returnDate: returnDate,
            existingPickup: booking.pickupDate,
            existingReturn: booking.returnDate,
          ),
    );
  }

  Booking addBooking({
    required Vehicle vehicle,
    required DateTime pickup,
    required DateTime returnDate,
    required double expectedDistanceKm,
    String? paymentReference,
  }) {
    if (isAdmin) {
      throw StateError('Administrators cannot create customer bookings.');
    }
    if (!returnDate.isAfter(pickup)) {
      throw StateError('Return date must be after the pickup date.');
    }
    if (!expectedDistanceKm.isFinite ||
        expectedDistanceKm < CostCalculationService.minimumExpectedDistanceKm ||
        expectedDistanceKm > CostCalculationService.maximumExpectedDistanceKm) {
      throw StateError('Expected distance must be from 1 to 5,000 km.');
    }
    if (!isVehicleAvailable(vehicle.id, pickup, returnDate)) {
      throw StateError('This vehicle is unavailable for those dates.');
    }
    final days = CostCalculationService.rentalDays(pickup, returnDate);
    final cost = CostCalculationService.calculate(
      vehicle: vehicle,
      fuelPrice: fuelPrice,
      rentalDays: days,
      expectedDistanceKm: expectedDistanceKm,
    );
    final now = DateTime.now();
    final booking = Booking(
      id: 'SMR-${now.millisecondsSinceEpoch}',
      customerName: userName,
      customerEmail: userEmail,
      vehicle: vehicle,
      pickupDate: pickup,
      returnDate: returnDate,
      expectedDistanceKm: expectedDistanceKm,
      cost: cost,
      status: BookingStatus.confirmed,
      createdAt: now,
      updatedAt: now,
      paymentReference: paymentReference,
    );
    _bookings.insert(0, booking);
    _addNotification(
      recipientEmail: userEmail,
      title: 'Booking confirmed',
      message: '${vehicle.name} is confirmed for ${_shortDate(pickup)}.',
      bookingId: booking.id,
    );
    _schedulePersist();
    notifyListeners();
    return booking;
  }

  String? cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return 'Booking record not found.';
    }
    final booking = _bookings[index];
    if (!isAdmin &&
        booking.customerEmail.toLowerCase() != _normalizedUserEmail) {
      return 'You cannot modify another customer’s booking.';
    }
    if (booking.status != BookingStatus.confirmed) {
      return 'Only confirmed bookings can be cancelled.';
    }
    _bookings[index] = booking.copyWith(
      status: BookingStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    _addNotification(
      recipientEmail: booking.customerEmail,
      title: 'Booking cancelled',
      message: '${booking.vehicle.name} booking ${booking.id} was cancelled.',
      bookingId: booking.id,
    );
    _schedulePersist();
    notifyListeners();
    return null;
  }

  String? updateBookingStatus(String bookingId, BookingStatus next) {
    if (!isAdmin) {
      return 'Administrator access is required.';
    }
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return 'Booking record not found.';
    }
    final booking = _bookings[index];
    if (!booking.status.canTransitionTo(next)) {
      return '${booking.status.label} cannot be changed to ${next.label}.';
    }
    _bookings[index] = booking.copyWith(
      status: next,
      updatedAt: DateTime.now(),
    );
    _addNotification(
      recipientEmail: booking.customerEmail,
      title: 'Booking status updated',
      message: '${booking.id} is now ${next.label.toLowerCase()}.',
      bookingId: booking.id,
    );
    _schedulePersist();
    notifyListeners();
    return null;
  }

  String? saveVehicle(Vehicle vehicle) {
    if (!isAdmin) {
      return 'Administrator access is required.';
    }
    if (vehicle.brand.trim().isEmpty || vehicle.model.trim().isEmpty) {
      return 'Brand and model are required.';
    }
    if (vehicle.dailyRate <= 0 || vehicle.seats < 1 || vehicle.seats > 12) {
      return 'Enter a valid rental rate and seating capacity.';
    }
    if (vehicle.isElectric) {
      if ((vehicle.energyKwhPer100Km ?? 0) <= 0) {
        return 'Electric vehicles require energy consumption information.';
      }
    } else if ((vehicle.efficiencyKmPerLitre ?? 0) <= 0) {
      return 'Fuel vehicles require efficiency information.';
    }
    final index = _vehicles.indexWhere((item) => item.id == vehicle.id);
    if (index == -1) {
      final duplicate = _vehicles.any(
        (item) =>
            item.brand.toLowerCase() == vehicle.brand.toLowerCase() &&
            item.model.toLowerCase() == vehicle.model.toLowerCase() &&
            item.year == vehicle.year &&
            item.availability != VehicleAvailability.deactivated,
      );
      if (duplicate) {
        return 'This vehicle model and year already exists.';
      }
      _vehicles.add(vehicle);
    } else {
      _vehicles[index] = vehicle;
    }
    _schedulePersist();
    notifyListeners();
    return null;
  }

  String? changeVehicleAvailability(
    String vehicleId,
    VehicleAvailability availability,
  ) {
    if (!isAdmin) {
      return 'Administrator access is required.';
    }
    final index = _vehicles.indexWhere((item) => item.id == vehicleId);
    if (index == -1) {
      return 'Vehicle record not found.';
    }
    _vehicles[index] = _vehicles[index].copyWith(availability: availability);
    _schedulePersist();
    notifyListeners();
    return null;
  }

  List<VehicleRecommendation> recommendVehicles(
    RecommendationCriteria criteria,
  ) {
    return RecommendationService.rank(
      vehicles: vehicles,
      fuelPrice: fuelPrice,
      criteria: criteria,
      isAvailable: (vehicle) => isVehicleAvailable(
        vehicle.id,
        criteria.pickupDate,
        criteria.returnDate,
      ),
    );
  }

  String? submitReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return 'Booking record not found.';
    }
    final booking = _bookings[index];
    if (booking.customerEmail.toLowerCase() != _normalizedUserEmail ||
        booking.status != BookingStatus.completed) {
      return 'Reviews are available only after your rental is completed.';
    }
    if (rating < 1 || rating > 5) {
      return 'Select a rating from one to five stars.';
    }
    final cleanComment = comment.trim();
    if (cleanComment.length < 5 || cleanComment.length > 500) {
      return 'Write a review between 5 and 500 characters.';
    }
    if (_reviews.any((review) => review.bookingId == bookingId)) {
      return 'A review has already been submitted for this booking.';
    }
    _reviews.insert(
      0,
      VehicleReview(
        id: 'REV-${DateTime.now().millisecondsSinceEpoch}',
        bookingId: booking.id,
        vehicleId: booking.vehicle.id,
        vehicleName: booking.vehicle.name,
        customerEmail: booking.customerEmail,
        customerName: booking.customerName,
        rating: rating,
        comment: cleanComment,
        createdAt: DateTime.now(),
      ),
    );
    _schedulePersist();
    notifyListeners();
    return null;
  }

  bool hasReviewedBooking(String bookingId) =>
      _reviews.any((review) => review.bookingId == bookingId);

  List<VehicleReview> reviewsForVehicle(String vehicleId) {
    return _reviews
        .where((review) => review.vehicleId == vehicleId && !review.isHidden)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double ratingForVehicle(Vehicle vehicle) {
    final reviews = reviewsForVehicle(vehicle.id);
    if (reviews.isEmpty) {
      return vehicle.rating;
    }
    return reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        reviews.length;
  }

  String? setReviewHidden(String reviewId, bool hidden) {
    if (!isAdmin) {
      return 'Administrator access is required.';
    }
    final index = _reviews.indexWhere((review) => review.id == reviewId);
    if (index == -1) {
      return 'Review record not found.';
    }
    _reviews[index] = _reviews[index].copyWith(isHidden: hidden);
    _schedulePersist();
    notifyListeners();
    return null;
  }

  void markNotificationRead(String notificationId) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) {
      return;
    }
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _schedulePersist();
    notifyListeners();
  }

  void markAllNotificationsRead() {
    final email = _normalizedUserEmail;
    for (var index = 0; index < _notifications.length; index++) {
      if (_notifications[index].recipientEmail.toLowerCase() == email) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    }
    _schedulePersist();
    notifyListeners();
  }

  List<RegistrationRecord> trendFor(String fuel) {
    final records = fuel == 'hybrid'
        ? _combinedHybridRecords()
        : registrationRecords.where((record) => record.fuel == fuel).toList();
    records.sort((a, b) => a.date.compareTo(b.date));
    return records.length <= 12
        ? records
        : records.sublist(records.length - 12);
  }

  Future<void> flushData() => _saveQueue;

  List<RegistrationRecord> _combinedHybridRecords() {
    final monthlyTotals = <DateTime, int>{};
    for (final record in registrationRecords.where(
      (record) =>
          record.fuel == 'hybrid_petrol' || record.fuel == 'hybrid_diesel',
    )) {
      final month = DateTime(record.date.year, record.date.month);
      monthlyTotals.update(
        month,
        (value) => value + record.registrations,
        ifAbsent: () => record.registrations,
      );
    }
    return monthlyTotals.entries
        .map(
          (entry) => RegistrationRecord(
            date: entry.key,
            fuel: 'hybrid',
            registrations: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  void _mergeVehicles(List<Vehicle> savedVehicles) {
    final values = <String, Vehicle>{
      for (final vehicle in demoVehicles) vehicle.id: vehicle,
    };
    for (final vehicle in savedVehicles) {
      if (vehicle.id.isNotEmpty) {
        values[vehicle.id] = vehicle;
      }
    }
    _vehicles
      ..clear()
      ..addAll(values.values);
  }

  List<Booking> _buildDemoBookings() {
    if (_vehicles.length < 4) {
      return [];
    }
    final today = DateTime.now();
    Booking create({
      required int index,
      required BookingStatus status,
      required DateTime pickup,
      required DateTime returnDate,
      required String suffix,
    }) {
      final vehicle = _vehicles[index];
      final cost = CostCalculationService.calculate(
        vehicle: vehicle,
        fuelPrice: FuelPrice.fallback(),
        rentalDays: CostCalculationService.rentalDays(pickup, returnDate),
        expectedDistanceKm: 260 + index * 40,
      );
      return Booking(
        id: 'SMR-DEMO-$suffix',
        customerName: 'Demo Student',
        customerEmail: 'student@smartrent.my',
        vehicle: vehicle,
        pickupDate: pickup,
        returnDate: returnDate,
        expectedDistanceKm: 260 + index * 40,
        cost: cost,
        status: status,
        createdAt: pickup.subtract(const Duration(days: 3)),
        updatedAt: today,
        paymentReference: 'pi_test_demo_$suffix',
      );
    }

    return [
      create(
        index: 0,
        status: BookingStatus.confirmed,
        pickup: today.add(const Duration(days: 4)),
        returnDate: today.add(const Duration(days: 7)),
        suffix: '1004',
      ),
      create(
        index: 1,
        status: BookingStatus.ongoing,
        pickup: today.subtract(const Duration(days: 1)),
        returnDate: today.add(const Duration(days: 2)),
        suffix: '1003',
      ),
      create(
        index: 2,
        status: BookingStatus.completed,
        pickup: today.subtract(const Duration(days: 12)),
        returnDate: today.subtract(const Duration(days: 9)),
        suffix: '1002',
      ),
      create(
        index: 3,
        status: BookingStatus.cancelled,
        pickup: today.subtract(const Duration(days: 20)),
        returnDate: today.subtract(const Duration(days: 17)),
        suffix: '1001',
      ),
    ];
  }

  void _applyAccount(LocalAccount account) {
    _activeAccount = account;
    userName = account.displayName;
    userEmail = account.email;
    userPhone = account.phone;
    userAvatarPath = account.avatarPath;
    currentRole = account.role;
    navigationIndex = 0;
  }

  void _replaceRegisteredAccount(LocalAccount account) {
    final index = _registeredAccounts.indexWhere(
      (item) => item.email == account.email,
    );
    if (index == -1) {
      _registeredAccounts.add(account);
    } else {
      _registeredAccounts[index] = account;
    }
  }

  void _addNotification({
    required String recipientEmail,
    required String title,
    required String message,
    String? bookingId,
  }) {
    _notifications.insert(
      0,
      AppNotificationRecord(
        id: 'NOT-${DateTime.now().microsecondsSinceEpoch}',
        recipientEmail: recipientEmail,
        title: title,
        message: message,
        bookingId: bookingId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _schedulePersist() {
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _localAppDataService.save(
          AppDataSnapshot(
            vehicles: _vehicles,
            bookings: _bookings,
            favouritesByUser: _favouritesByUser,
            notifications: _notifications,
            reviews: _reviews,
          ),
        );
        dataError = null;
      } on LocalDataException catch (error) {
        dataError = error.message;
        notifyListeners();
      }
    });
    unawaited(_saveQueue);
  }

  String get _normalizedUserEmail => userEmail.trim().toLowerCase();

  String _fuelLabel(String fuel) => fuel.replaceAll('_', ' ');

  String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
