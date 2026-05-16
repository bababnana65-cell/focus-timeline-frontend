import 'http_api_client.dart';
import 'profile_remote_service.dart';

class HttpProfileRemoteService implements ProfileRemoteService {
  HttpProfileRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<List<String>> fetchInterestCategoryIds() async {
    final data = await _client.get('/me/interests');
    return _readCategoryIds(data);
  }

  @override
  Future<List<String>> saveInterestCategoryIds(List<String> categoryIds) async {
    final data = await _client.post(
      '/me/interests',
      body: <String, dynamic>{
        'interestCategoryIds': categoryIds,
      },
    );
    return _readCategoryIds(data, fallback: categoryIds);
  }

  @override
  Future<void> submitFeedback({
    required String message,
    String category = 'suggestion',
  }) async {
    await _client.post(
      '/feedback',
      body: <String, dynamic>{
        'message': message,
        'category': category,
        'source': 'profile',
      },
      includeGuestKey: true,
    );
  }

  List<String> _readCategoryIds(
    Map<String, dynamic> data, {
    List<String> fallback = const <String>[],
  }) {
    final raw = data['interestCategoryIds'] ??
        data['categoryIds'] ??
        data['categories'] ??
        data['items'];
    if (raw is List) {
      return raw.whereType<String>().toList(growable: false);
    }
    return fallback;
  }
}
