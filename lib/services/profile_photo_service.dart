import 'dart:io';

import 'package:flutter/services.dart';

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfilePhotoService {
  const ProfilePhotoService();

  static const _channel = MethodChannel('smartrent_my/profile_photo');

  Future<String?> pickPhoto() async {
    if (!Platform.isAndroid) {
      throw const ProfilePhotoException(
        'Profile photo selection is currently available on Android.',
      );
    }
    try {
      return await _channel.invokeMethod<String>('pickProfilePhoto');
    } on PlatformException catch (error) {
      throw ProfilePhotoException(
        error.message ?? 'The selected photo could not be opened.',
      );
    } on MissingPluginException {
      throw const ProfilePhotoException(
        'Restart the app before selecting a profile photo.',
      );
    }
  }

  Future<void> deletePhoto(String? path) async {
    if (!Platform.isAndroid || path == null || path.isEmpty) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('deleteProfilePhoto', {'path': path});
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
