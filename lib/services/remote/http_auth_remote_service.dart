import '../../dto/auth_dto.dart';
import 'auth_remote_service.dart';
import 'http_api_client.dart';

class HttpAuthRemoteService implements AuthRemoteService {
  HttpAuthRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<AuthSendCodeResponseDto> sendCode(String phoneNumber) async {
    final data = await _client.post(
      '/auth/send-code',
      authenticated: false,
      body: <String, dynamic>{
        'phone': phoneNumber,
      },
    );
    return AuthSendCodeResponseDto.fromJson(data);
  }

  @override
  Future<AuthLoginResponseDto> login({
    required String phoneNumber,
    required String code,
  }) async {
    final data = await _client.post(
      '/auth/login',
      authenticated: false,
      body: <String, dynamic>{
        'phone': phoneNumber,
        'code': code,
      },
    );
    return AuthLoginResponseDto.fromJson(data);
  }

  @override
  Future<CurrentUserResponseDto?> getCurrentUser(String sessionToken) async {
    final data = await _client.get('/users/me');
    if (data.isEmpty) {
      return null;
    }
    return CurrentUserResponseDto.fromJson(data);
  }

  @override
  Future<void> logout(String sessionToken) async {
    await _client.post('/auth/logout', body: const <String, dynamic>{});
  }
}
