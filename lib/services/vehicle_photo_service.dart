import 'dart:io';

import 'package:flutter/services.dart';

class VehiclePhotoException implements Exception {
  const VehiclePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VehiclePhotoService {
  const VehiclePhotoService();

  static const _channel = MethodChannel('smartrent_my/vehicle_photo');

  Future<String?> pickPhoto() async {
    if (!Platform.isAndroid) {
      throw const VehiclePhotoException(
        'Vehicle photo selection is currently available on Android.',
      );
    }
    try {
      return await _channel.invokeMethod<String>('pickVehiclePhoto');
    } on PlatformException catch (error) {
      throw VehiclePhotoException(
        error.message ?? 'The selected vehicle photo could not be opened.',
      );
    } on MissingPluginException {
      throw const VehiclePhotoException(
        'Restart the Android app before selecting a vehicle photo.',
      );
    }
  }
}
