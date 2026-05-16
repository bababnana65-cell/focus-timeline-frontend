import '../../dto/recommendation_dto.dart';
import 'http_api_client.dart';
import 'recommendation_remote_service.dart';

class HttpRecommendationRemoteService implements RecommendationRemoteService {
  HttpRecommendationRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<RecommendationResponseDto> fetchRecommendations() async {
    final data = await _client.get('/recommendations');
    return RecommendationResponseDto.fromJson(data);
  }
}
