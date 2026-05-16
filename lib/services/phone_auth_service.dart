import '../mappers/auth_mapper.dart';
import '../models/auth_models.dart';
import 'remote/auth_remote_service.dart';

abstract class PhoneAuthService {
  Future<SmsChallenge> sendVerificationCode(String phoneNumber);

  Future<AuthSession> verifyCode({
    required String phoneNumber,
    required String code,
  });
}

class RemotePhoneAuthService implements PhoneAuthService {
  RemotePhoneAuthService({
    required AuthRemoteService remoteService,
    AuthMapper? mapper,
  })  : _remoteService = remoteService,
        _mapper = mapper ?? const AuthMapper();

  final AuthRemoteService _remoteService;
  final AuthMapper _mapper;

  @override
  Future<SmsChallenge> sendVerificationCode(String phoneNumber) async {
    final response = await _remoteService.sendCode(phoneNumber);
    final debugCode = _remoteService is MockAuthRemoteService
        ? _remoteService.debugCodeForPhone(phoneNumber)
        : null;

    return SmsChallenge(
      phoneNumber: phoneNumber,
      cooldownSeconds: response.cooldownSeconds,
      expiresInSeconds: response.expiresInSeconds,
      debugCode: debugCode,
    );
  }

  @override
  Future<AuthSession> verifyCode({
    required String phoneNumber,
    required String code,
  }) async {
    final response = await _remoteService.login(
      phoneNumber: phoneNumber,
      code: code,
    );
    return _mapper.toAuthSession(response);
  }
}

class MockPhoneAuthService extends RemotePhoneAuthService {
  MockPhoneAuthService({
    AuthRemoteService? remoteService,
    super.mapper,
  }) : super(
          remoteService: remoteService ?? MockAuthRemoteService(),
        );
}
