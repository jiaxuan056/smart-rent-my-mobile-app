import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/vehicle.dart';
import '../models/vehicle_review.dart';

class LocalDataException implements Exception {
  const LocalDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppDataSnapshot {
  const AppDataSnapshot({
    this.vehicles = const [],
    this.bookings = const [],
    this.favouritesByUser = const {},
    this.notifications = const [],
    this.reviews = const [],
  });

  final List<Vehicle> vehicles;
  final List<Booking> bookings;
  final Map<String, Set<String>> favouritesByUser;
  final List<AppNotificationRecord> notifications;
  final List<VehicleReview> reviews;

  factory AppDataSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) parse) {
      final value = json[key];
      if (value is! List) {
        return [];
      }
      return value
          .whereType<Map>()
          .map((row) => parse(Map<String, dynamic>.from(row)))
          .toList();
    }

    final favourites = <String, Set<String>>{};
    final rawFavourites = json['favourites_by_user'];
    if (rawFavourites is Map) {
      for (final entry in rawFavourites.entries) {
        final value = entry.value;
        if (value is List) {
          favourites[entry.key.toString()] = value
              .map((item) => item.toString())
              .toSet();
        }
      }
    }

    return AppDataSnapshot(
      vehicles: rows('vehicles', Vehicle.fromJson),
      bookings: rows('bookings', Booking.fromJson),
      favouritesByUser: favourites,
      notifications: rows('notifications', AppNotificationRecord.fromJson),
      reviews: rows('reviews', VehicleReview.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 2,
      'vehicles': vehicles.map((item) => item.toJson()).toList(),
      'bookings': bookings.map((item) => item.toJson()).toList(),
      'favourites_by_user': {
        for (final entry in favouritesByUser.entries)
          entry.key: entry.value.toList(),
      },
      'notifications': notifications.map((item) => item.toJson()).toList(),
      'reviews': reviews.map((item) => item.toJson()).toList(),
    };
  }
}

class LocalAppDataService {
  LocalAppDataService({this.storageDirectory});

  static const _storageChannel = MethodChannel('smartrent_my/local_storage');
  final Directory? storageDirectory;

  Future<AppDataSnapshot> load() async {
    final file = await _dataFile();
    try {
      if (!await file.exists()) {
        return const AppDataSnapshot();
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException();
      }
      return AppDataSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      throw const LocalDataException(
        'The saved application data is damaged. Clear the app data to reset it.',
      );
    } on FileSystemException {
      throw const LocalDataException(
        'SmartRent MY could not read its private application data.',
      );
    }
  }

  Future<void> save(AppDataSnapshot snapshot) async {
    try {
      final file = await _dataFile();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
        flush: true,
      );
      if (await file.exists()) {
        await file.delete();
      }
      await temporary.rename(file.path);
    } on FileSystemException {
      throw const LocalDataException(
        'SmartRent MY could not save the latest application data.',
      );
    }
  }

  Future<File> _dataFile() async {
    final directory = storageDirectory ?? await _applicationDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}smartrent_app_data.json',
    );
  }

  Future<Directory> _applicationDirectory() async {
    try {
      final path = await _storageChannel.invokeMethod<String>(
        'getAppFilesPath',
      );
      if (path == null || path.isEmpty) {
        throw const LocalDataException(
          'Private application storage is unavailable.',
        );
      }
      return Directory(path);
    } on PlatformException catch (error) {
      throw LocalDataException(
        error.message ?? 'Private application storage is unavailable.',
      );
    } on MissingPluginException {
      throw const LocalDataException(
        'Restart the Android app to enable private application storage.',
      );
    }
  }
}
