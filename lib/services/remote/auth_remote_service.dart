import 'dart:math';

import '../../dto/auth_dto.dart';

abstract class AuthRemoteService {
  Future<AuthSendCodeResponseDto> sendCode(String phoneNumber);

  Future<AuthLoginResponseDto> login({
    required String phoneNumber,
    required String code,
  });

  Future<CurrentUserResponseDto?> getCurrentUser(String sessionToken);

  Future<void> logout(String sessionToken);
}

class MockAuthRemoteService implements AuthRemoteService {
  final Map<String, String> _activeCodes = <String, String>{};
  final Map<String, AuthLoginResponseDto> _sessionsByToken = <String, AuthLoginResponseDto>{};
  final Random _random = Random();

  @override
  Future<AuthSendCodeResponseDto> sendCode(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final code = (100000 + _random.nextInt(900000)).toString();
    _activeCodes[phoneNumber] = code;

    return const AuthSendCodeResponseDto(
      sent: true,
      cooldownSeconds: 60,
      expiresInSeconds: 60,
    );
  }

  String? debugCodeForPhone(String phoneNumber) => _activeCodes[phoneNumber];

  @override
  Future<AuthLoginResponseDto> login({
    required String phoneNumber,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final expectedCode = _activeCodes[phoneNumber];

    if (expectedCode == null) {
      throw Exception('请先发送验证码。');
    }

    if (expectedCode != code) {
      throw Exception('验证码错误，请重新输入。');
    }

    _activeCodes.remove(phoneNumber);

    final issuedAt = DateTime.now();
    final userId = 'user_$phoneNumber';
    final sessionToken = 'sess_${phoneNumber}_${issuedAt.millisecondsSinceEpoch}';
    final dto = AuthLoginResponseDto(
      session: AuthSessionDto(
        sessionToken: sessionToken,
        refreshToken: null,
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      ),
      user: UserSummaryDto(
        userId: userId,
        primaryPhone: phoneNumber,
      ),
      identity: const IdentityDto(
        identityId: 'identity_phone_sms',
        identityType: 'phone',
        provider: 'sms',
      ),
    );
    _sessionsByToken[sessionToken] = dto;
    return dto;
  }

  @override
  Future<CurrentUserResponseDto?> getCurrentUser(String sessionToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final login = _sessionsByToken[sessionToken];
    if (login == null) {
      return null;
    }
    return CurrentUserResponseDto(
      user: login.user,
      identity: login.identity,
      session: login.session,
    );
  }

  @override
  Future<void> logout(String sessionToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _sessionsByToken.remove(sessionToken);
  }
}
