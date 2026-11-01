enum AccountRole { customer, admin }

extension AccountRoleDetails on AccountRole {
  String get label => this == AccountRole.admin ? 'Administrator' : 'Customer';
}

class LocalAccount {
  const LocalAccount({
    required this.displayName,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.passwordSalt,
    required this.securityPhraseHash,
    required this.securityPhraseSalt,
    required this.createdAt,
    this.avatarPath,
    this.role = AccountRole.customer,
    this.isActive = true,
  });

  final String displayName;
  final String email;
  final String phone;
  final String passwordHash;
  final String passwordSalt;
  final String securityPhraseHash;
  final String securityPhraseSalt;
  final DateTime createdAt;
  final String? avatarPath;
  final AccountRole role;
  final bool isActive;

  factory LocalAccount.fromJson(Map<String, dynamic> json) {
    return LocalAccount(
      displayName: json['display_name']?.toString() ?? 'SmartRent User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      passwordHash: json['password_hash']?.toString() ?? '',
      passwordSalt: json['password_salt']?.toString() ?? '',
      securityPhraseHash: json['security_phrase_hash']?.toString() ?? '',
      securityPhraseSalt: json['security_phrase_salt']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      avatarPath: json['avatar_path']?.toString(),
      role: json['role']?.toString() == AccountRole.admin.name
          ? AccountRole.admin
          : AccountRole.customer,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'security_phrase_hash': securityPhraseHash,
      'security_phrase_salt': securityPhraseSalt,
      'created_at': createdAt.toIso8601String(),
      'avatar_path': avatarPath,
      'role': role.name,
      'is_active': isActive,
    };
  }

  LocalAccount copyWith({
    String? displayName,
    String? phone,
    String? passwordHash,
    String? passwordSalt,
    String? avatarPath,
    bool removeAvatar = false,
    AccountRole? role,
    bool? isActive,
  }) {
    return LocalAccount(
      displayName: displayName ?? this.displayName,
      email: email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      securityPhraseHash: securityPhraseHash,
      securityPhraseSalt: securityPhraseSalt,
      createdAt: createdAt,
      avatarPath: removeAvatar ? null : avatarPath ?? this.avatarPath,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
