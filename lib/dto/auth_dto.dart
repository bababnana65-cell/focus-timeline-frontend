class AuthSendCodeResponseDto {
  const AuthSendCodeResponseDto({
    required this.sent,
    required this.cooldownSeconds,
    required this.expiresInSeconds,
  });

  final bool sent;
  final int cooldownSeconds;
  final int expiresInSeconds;

  factory AuthSendCodeResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthSendCodeResponseDto(
      sent: json['sent'] as bool,
      cooldownSeconds: json['cooldownSeconds'] as int,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }
}

class AuthSessionDto {
  const AuthSessionDto({
    this.sessionToken,
    required this.issuedAt,
    required this.expiresAt,
    this.refreshToken,
  });

  final String? sessionToken;
  final String? refreshToken;
  final DateTime issuedAt;
  final DateTime expiresAt;

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      sessionToken: json['sessionToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class UserSummaryDto {
  const UserSummaryDto({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.primaryPhone,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? primaryPhone;

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) {
    return UserSummaryDto(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      primaryPhone: json['primaryPhone'] as String?,
    );
  }
}

class IdentityDto {
  const IdentityDto({
    required this.identityId,
    required this.identityType,
    required this.provider,
  });

  final String identityId;
  final String identityType;
  final String provider;

  factory IdentityDto.fromJson(Map<String, dynamic> json) {
    return IdentityDto(
      identityId: json['identityId'] as String,
      identityType: json['identityType'] as String,
      provider: json['provider'] as String,
    );
  }
}

class AuthLoginResponseDto {
  const AuthLoginResponseDto({
    required this.session,
    required this.user,
    required this.identity,
  });

  final AuthSessionDto session;
  final UserSummaryDto user;
  final IdentityDto identity;

  factory AuthLoginResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponseDto(
      session: AuthSessionDto.fromJson(json['session'] as Map<String, dynamic>),
      user: UserSummaryDto.fromJson(json['user'] as Map<String, dynamic>),
      identity: IdentityDto.fromJson(json['identity'] as Map<String, dynamic>),
    );
  }
}

class CurrentUserResponseDto {
  const CurrentUserResponseDto({
    required this.user,
    required this.identity,
    required this.session,
  });

  final UserSummaryDto user;
  final IdentityDto identity;
  final AuthSessionDto session;

  factory CurrentUserResponseDto.fromJson(Map<String, dynamic> json) {
    return CurrentUserResponseDto(
      user: UserSummaryDto.fromJson(json['user'] as Map<String, dynamic>),
      identity: IdentityDto.fromJson(json['identity'] as Map<String, dynamic>),
      session: AuthSessionDto.fromJson(json['session'] as Map<String, dynamic>),
    );
  }
}
