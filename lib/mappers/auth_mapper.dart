import '../dto/auth_dto.dart';
import '../models/auth_models.dart';

class AuthMapper {
  const AuthMapper();

  AuthSession toAuthSession(AuthLoginResponseDto dto) {
    final sessionToken = dto.session.sessionToken;
    if (sessionToken == null || sessionToken.isEmpty) {
      throw StateError('登录响应缺少 sessionToken。');
    }

    return AuthSession(
      userId: dto.user.userId,
      sessionToken: sessionToken,
      refreshToken: dto.session.refreshToken,
      issuedAt: dto.session.issuedAt,
      expiresAt: dto.session.expiresAt,
      identityType: dto.identity.identityType,
      provider: dto.identity.provider,
      primaryPhone: dto.user.primaryPhone,
      displayName: dto.user.displayName,
      avatarUrl: dto.user.avatarUrl,
    );
  }

  AuthSession toAuthSessionFromCurrentUser(
    CurrentUserResponseDto dto, {
    String? sessionToken,
    String? refreshToken,
  }) {
    final resolvedSessionToken = sessionToken ?? dto.session.sessionToken;
    if (resolvedSessionToken == null || resolvedSessionToken.isEmpty) {
      throw StateError('当前用户响应缺少 sessionToken。');
    }

    return AuthSession(
      userId: dto.user.userId,
      sessionToken: resolvedSessionToken,
      refreshToken: refreshToken ?? dto.session.refreshToken,
      issuedAt: dto.session.issuedAt,
      expiresAt: dto.session.expiresAt,
      identityType: dto.identity.identityType,
      provider: dto.identity.provider,
      primaryPhone: dto.user.primaryPhone,
      displayName: dto.user.displayName,
      avatarUrl: dto.user.avatarUrl,
    );
  }
}
