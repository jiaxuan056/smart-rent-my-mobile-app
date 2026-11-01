import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/local_account.dart';

class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalAccountService {
  LocalAccountService({this.storageDirectory});

  static const _storageChannel = MethodChannel('smartrent_my/local_storage');
  final Directory? storageDirectory;
  List<LocalAccount>? _accounts;

  Future<List<LocalAccount>> loadAccounts() async {
    if (_accounts != null) {
      return List.unmodifiable(_accounts!);
    }
    final file = await _accountFile();
    try {
      if (!await file.exists()) {
        _accounts = [];
        return const [];
      }
      final decoded = jsonDecode(await file.readAsString());
      final rows = decoded is Map<String, dynamic> ? decoded['accounts'] : null;
      if (rows is! List) {
        throw const FormatException();
      }
      _accounts = rows
          .whereType<Map>()
          .map((row) => LocalAccount.fromJson(Map<String, dynamic>.from(row)))
          .where(
            (account) =>
                account.email.isNotEmpty &&
                account.passwordHash.isNotEmpty &&
                account.securityPhraseHash.isNotEmpty,
          )
          .toList();
      return List.unmodifiable(_accounts!);
    } on FormatException {
      throw const AccountException(
        'The local account file is damaged. Clear the app data and register again.',
      );
    } on FileSystemException {
      throw const AccountException(
        'The app could not read its private account storage.',
      );
    }
  }

  Future<LocalAccount> register({
    required String displayName,
    required String email,
    required String password,
    required String securityPhrase,
  }) async {
    final accounts = await _mutableAccounts();
    final normalizedEmail = _normalizeEmail(email);
    if (accounts.any((account) => account.email == normalizedEmail)) {
      throw const AccountException(
        'An account with this email already exists.',
      );
    }
    final passwordSalt = _createSalt();
    final phraseSalt = _createSalt();
    final account = LocalAccount(
      displayName: displayName.trim(),
      email: normalizedEmail,
      phone: '',
      passwordHash: _hash(password, passwordSalt),
      passwordSalt: passwordSalt,
      securityPhraseHash: _hash(_normalizePhrase(securityPhrase), phraseSalt),
      securityPhraseSalt: phraseSalt,
      createdAt: DateTime.now(),
    );
    accounts.add(account);
    await _save(accounts);
    return account;
  }

  Future<LocalAccount> authenticate({
    required String email,
    required String password,
  }) async {
    final account = await _findByEmail(email);
    if (account == null ||
        !_constantTimeEquals(
          account.passwordHash,
          _hash(password, account.passwordSalt),
        )) {
      throw const AccountException('Incorrect email address or password.');
    }
    return account;
  }

  Future<void> recoverPassword({
    required String email,
    required String securityPhrase,
    required String newPassword,
  }) async {
    final account = await _findByEmail(email);
    if (account == null) {
      throw const AccountException(
        'No local account was found for this email.',
      );
    }
    final suppliedHash = _hash(
      _normalizePhrase(securityPhrase),
      account.securityPhraseSalt,
    );
    if (!_constantTimeEquals(account.securityPhraseHash, suppliedHash)) {
      throw const AccountException('The recovery phrase does not match.');
    }
    await _replaceAccount(
      account.copyWith(passwordSalt: _createSalt(), passwordHash: ''),
      password: newPassword,
    );
  }

  Future<LocalAccount> updateProfile({
    required LocalAccount account,
    required String displayName,
    required String phone,
  }) async {
    final updated = account.copyWith(
      displayName: displayName.trim(),
      phone: phone.trim(),
    );
    await _replaceAccount(updated);
    return updated;
  }

  Future<LocalAccount> changePassword({
    required LocalAccount account,
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentHash = _hash(currentPassword, account.passwordSalt);
    if (!_constantTimeEquals(account.passwordHash, currentHash)) {
      throw const AccountException('The current password is incorrect.');
    }
    final newSalt = _createSalt();
    final updated = account.copyWith(
      passwordSalt: newSalt,
      passwordHash: _hash(newPassword, newSalt),
    );
    await _replaceAccount(updated);
    return updated;
  }

  Future<LocalAccount> updateAvatar({
    required LocalAccount account,
    String? avatarPath,
    bool remove = false,
  }) async {
    final updated = account.copyWith(
      avatarPath: avatarPath,
      removeAvatar: remove,
    );
    await _replaceAccount(updated);
    return updated;
  }

  Future<LocalAccount?> _findByEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final accounts = await _mutableAccounts();
    for (final account in accounts) {
      if (account.email == normalizedEmail) {
        return account;
      }
    }
    return null;
  }

  Future<List<LocalAccount>> _mutableAccounts() async {
    await loadAccounts();
    return _accounts!;
  }

  Future<void> _replaceAccount(LocalAccount updated, {String? password}) async {
    final accounts = await _mutableAccounts();
    final index = accounts.indexWhere(
      (account) => account.email == updated.email,
    );
    if (index == -1) {
      throw const AccountException('The local account no longer exists.');
    }
    if (password != null) {
      final salt = updated.passwordSalt;
      updated = updated.copyWith(passwordHash: _hash(password, salt));
    }
    accounts[index] = updated;
    await _save(accounts);
  }

  Future<void> _save(List<LocalAccount> accounts) async {
    try {
      final file = await _accountFile();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'accounts': accounts.map((account) => account.toJson()).toList(),
        }),
        flush: true,
      );
      if (await file.exists()) {
        await file.delete();
      }
      await temporary.rename(file.path);
    } on FileSystemException {
      throw const AccountException(
        'The app could not save the local account record.',
      );
    }
  }

  Future<File> _accountFile() async {
    final directory = storageDirectory ?? await _applicationDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}smartrent_accounts.json',
    );
  }

  Future<Directory> _applicationDirectory() async {
    try {
      final path = await _storageChannel.invokeMethod<String>(
        'getAppFilesPath',
      );
      if (path == null || path.isEmpty) {
        throw const AccountException(
          'The app could not locate its private account storage.',
        );
      }
      return Directory(path);
    } on PlatformException catch (error) {
      throw AccountException(
        error.message ?? 'Private account storage is unavailable.',
      );
    } on MissingPluginException {
      throw const AccountException(
        'Restart the Android app to enable private account storage.',
      );
    }
  }

  String _createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String secret, String salt) {
    return sha256.convert(utf8.encode('$salt::$secret')).toString();
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  String _normalizePhrase(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _constantTimeEquals(String expected, String actual) {
    if (expected.length != actual.length) {
      return false;
    }
    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected.codeUnitAt(index) ^ actual.codeUnitAt(index);
    }
    return difference == 0;
  }
}
