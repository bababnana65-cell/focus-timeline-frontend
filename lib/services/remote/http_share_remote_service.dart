import '../../dto/share_dto.dart';
import 'http_api_client.dart';
import 'share_remote_service.dart';

class HttpShareRemoteService implements ShareRemoteService {
  HttpShareRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<ShareCreateResultDto> createShare({
    required String topicId,
  }) async {
    final data = await _client.post(
      '/shares',
      body: <String, dynamic>{
        'topicId': topicId,
      },
    );
    return ShareCreateResultDto.fromJson(data);
  }

  @override
  Future<ShareResolveDto> resolveShare(String shareToken) async {
    final data = await _client.get('/shares/$shareToken');
    return ShareResolveDto.fromJson(data);
  }
}
