import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartrent_my/core/validators.dart';
import 'package:smartrent_my/services/local_account_service.dart';

void main() {
  group('Account and profile validation', () {
    test('accepts only passwords between 8 and 30 characters', () {
      expect(AppValidators.password('1234567'), isNotNull);
      expect(AppValidators.password('12345678'), isNull);
      expect(AppValidators.password(List.filled(30, 'a').join()), isNull);
      expect(AppValidators.password(List.filled(31, 'a').join()), isNotNull);
      expect(AppValidators.password('password with spaces'), isNotNull);
    });

    test('validates account names, emails, phones and recovery phrases', () {
      expect(AppValidators.personName('Nur Aisyah'), isNull);
      expect(AppValidators.personName('User123'), isNotNull);
      expect(AppValidators.email('student@example.com'), isNull);
      expect(AppValidators.email('student.example.com'), isNotNull);
      expect(AppValidators.phone('012-345 6789'), isNull);
      expect(AppValidators.phone('123'), isNotNull);
      expect(AppValidators.securityPhrase('my first blue car'), isNull);
      expect(AppValidators.securityPhrase('blue car'), isNotNull);
    });
  });

  group('Local account storage', () {
    late Directory directory;
    late LocalAccountService service;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'smartrent_account_member_test_',
      );
      service = LocalAccountService(storageDirectory: directory);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('registers, normalises and authenticates an account', () async {
      final account = await service.register(
        displayName: '  Nur Aisyah  ',
        email: '  STUDENT@Example.com ',
        password: 'Password123',
        securityPhrase: 'my first blue car',
      );

      expect(account.displayName, 'Nur Aisyah');
      expect(account.email, 'student@example.com');
      expect(account.passwordHash, isNot('Password123'));

      final signedIn = await service.authenticate(
        email: 'STUDENT@example.com',
        password: 'Password123',
      );
      expect(signedIn.email, 'student@example.com');
    });

    test('rejects duplicate email registration', () async {
      await service.register(
        displayName: 'First Student',
        email: 'student@example.com',
        password: 'Password123',
        securityPhrase: 'my first blue car',
      );

      await expectLater(
        service.register(
          displayName: 'Second Student',
          email: 'STUDENT@example.com',
          password: 'Password456',
          securityPhrase: 'my second red car',
        ),
        throwsA(
          isA<AccountException>().having(
            (error) => error.message,
            'message',
            contains('already exists'),
          ),
        ),
      );
    });

    test('recovers a password using a normalised recovery phrase', () async {
      await service.register(
        displayName: 'Test Student',
        email: 'student@example.com',
        password: 'OldPassword123',
        securityPhrase: 'my first blue car',
      );

      await expectLater(
        service.recoverPassword(
          email: 'student@example.com',
          securityPhrase: 'the wrong recovery phrase',
          newPassword: 'NewPassword456',
        ),
        throwsA(isA<AccountException>()),
      );

      await service.recoverPassword(
        email: 'student@example.com',
        securityPhrase: '  MY first   BLUE car ',
        newPassword: 'NewPassword456',
      );

      await expectLater(
        service.authenticate(
          email: 'student@example.com',
          password: 'OldPassword123',
        ),
        throwsA(isA<AccountException>()),
      );
      final recovered = await service.authenticate(
        email: 'student@example.com',
        password: 'NewPassword456',
      );
      expect(recovered.displayName, 'Test Student');
    });

    test('updates profile information and avatar path', () async {
      final account = await service.register(
        displayName: 'Original Name',
        email: 'student@example.com',
        password: 'Password123',
        securityPhrase: 'my first blue car',
      );

      final updated = await service.updateProfile(
        account: account,
        displayName: 'Updated Student',
        phone: '012-3456789',
      );
      final withAvatar = await service.updateAvatar(
        account: updated,
        avatarPath: 'profile/student.png',
      );
      final withoutAvatar = await service.updateAvatar(
        account: withAvatar,
        remove: true,
      );

      expect(updated.displayName, 'Updated Student');
      expect(updated.phone, '012-3456789');
      expect(withAvatar.avatarPath, 'profile/student.png');
      expect(withoutAvatar.avatarPath, isNull);
    });
  });
}
