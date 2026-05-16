class AuthSession {
  factory AuthSession({
    String? userId,
    String? sessionToken,
    String? refreshToken,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? identityType,
    String? provider,
    String? primaryPhone,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? loggedInAt,
  }) {
    final resolvedPrimaryPhone = primaryPhone ?? phoneNumber;
    final resolvedIssuedAt = issuedAt ?? loggedInAt ?? DateTime.now();
    final resolvedUserId = userId ?? _deriveUserId(resolvedPrimaryPhone);
    return AuthSession._internal(
      userId: resolvedUserId,
      sessionToken: sessionToken,
      refreshToken: refreshToken,
      issuedAt: resolvedIssuedAt,
      expiresAt: expiresAt,
      identityType: identityType ?? 'phone',
      provider: provider ?? 'sms',
      primaryPhone: resolvedPrimaryPhone,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  AuthSession._internal({
    required this.userId,
    String? sessionToken,
    this.refreshToken,
    required this.issuedAt,
    DateTime? expiresAt,
    required this.identityType,
    required this.provider,
    required this.primaryPhone,
    this.displayName,
    this.avatarUrl,
  })  : sessionToken = sessionToken ?? _deriveSessionToken(userId, issuedAt),
        expiresAt = expiresAt ?? issuedAt.add(const Duration(days: 7));

  final String userId;
  final String sessionToken;
  final String? refreshToken;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String identityType;
  final String provider;
  final String? primaryPhone;
  final String? displayName;
  final String? avatarUrl;

  String get phoneNumber => primaryPhone ?? '';

  DateTime get loggedInAt => issuedAt;

  String get maskedPhoneNumber {
    final value = phoneNumber;
    if (value.length < 7) {
      return value;
    }
    return '${value.substring(0, 3)}****${value.substring(value.length - 4)}';
  }

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'sessionToken': sessionToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'identityType': identityType,
      'provider': provider,
      if (primaryPhone != null) 'primaryPhone': primaryPhone,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (primaryPhone != null) 'phoneNumber': primaryPhone,
      'loggedInAt': issuedAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final primaryPhone = json['primaryPhone'] as String? ?? json['phoneNumber'] as String?;
    final issuedAtRaw = json['issuedAt'] as String? ?? json['loggedInAt'] as String?;

    return AuthSession(
      userId: json['userId'] as String? ?? _deriveUserId(primaryPhone),
      sessionToken: json['sessionToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      issuedAt: issuedAtRaw == null ? null : DateTime.parse(issuedAtRaw),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      identityType: json['identityType'] as String? ?? 'phone',
      provider: json['provider'] as String? ?? 'sms',
      primaryPhone: primaryPhone,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  static String _deriveUserId(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'user_local';
    }
    return 'user_$phoneNumber';
  }

  static String _deriveSessionToken(String userId, DateTime issuedAt) {
    return 'local_${userId}_${issuedAt.millisecondsSinceEpoch}';
  }
}

class SmsChallenge {
  const SmsChallenge({
    required this.phoneNumber,
    required this.cooldownSeconds,
    required this.expiresInSeconds,
    this.debugCode,
  });

  final String phoneNumber;
  final int cooldownSeconds;
  final int expiresInSeconds;
  final String? debugCode;
}
