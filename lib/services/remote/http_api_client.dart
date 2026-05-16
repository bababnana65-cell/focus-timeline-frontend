import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpApiClient {
  HttpApiClient({
    required String baseUrl,
    required String? Function() sessionTokenProvider,
    required String? Function() guestKeyProvider,
    http.Client? client,
  })  : _baseUri = Uri.parse(_normalizeBaseUrl(baseUrl)),
        _sessionTokenProvider = sessionTokenProvider,
        _guestKeyProvider = guestKeyProvider,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final String? Function() _sessionTokenProvider;
  final String? Function() _guestKeyProvider;
  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
    bool includeGuestKey = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      authenticated: authenticated,
      includeGuestKey: includeGuestKey,
      extraHeaders: headers,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool includeGuestKey = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      authenticated: authenticated,
      includeGuestKey: includeGuestKey,
      extraHeaders: headers,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool includeGuestKey = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      authenticated: authenticated,
      includeGuestKey: includeGuestKey,
      extraHeaders: headers,
    );
  }

  void close() {
    _client.close();
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    required bool authenticated,
    required bool includeGuestKey,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _resolveUri(path, queryParameters: queryParameters);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };
    final sessionToken = _sessionTokenProvider();
    if (authenticated) {
      if (sessionToken != null && sessionToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }
    }
    if (includeGuestKey || sessionToken == null || sessionToken.isEmpty) {
      final guestKey = _guestKeyProvider();
      if (guestKey != null && guestKey.isNotEmpty) {
        headers['X-Timeliness-Guest-Key'] = guestKey;
      }
    }

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        );
      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    final payload = _decodePayload(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpApiException.fromPayload(
        statusCode: response.statusCode,
        payload: payload,
      );
    }

    final success = payload['success'];
    if (success is bool && !success) {
      throw HttpApiException.fromPayload(
        statusCode: response.statusCode,
        payload: payload,
      );
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Uri _resolveUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _baseUri.resolve(normalizedPath);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        ...queryParameters,
      },
    );
  }

  Map<String, dynamic> _decodePayload(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    throw HttpApiException(
      message: 'Unexpected response payload.',
      statusCode: response.statusCode,
    );
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed;
    }
    return '$trimmed/';
  }
}

class HttpApiException implements Exception {
  const HttpApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  factory HttpApiException.fromPayload({
    required int statusCode,
    required Map<String, dynamic> payload,
  }) {
    final error = payload['error'];
    final detailMessage = _messageFromDetail(payload['detail']);
    if (error is Map<String, dynamic>) {
      return HttpApiException(
        message: _messageFromError(error) ??
            detailMessage ??
            'Request failed.',
        code: error['code'] as String?,
        statusCode: statusCode,
      );
    }
    if (error is Map) {
      final casted = error.cast<String, dynamic>();
      return HttpApiException(
        message: _messageFromError(casted) ??
            detailMessage ??
            'Request failed.',
        code: casted['code'] as String?,
        statusCode: statusCode,
      );
    }
    return HttpApiException(
      message: detailMessage ?? 'Request failed.',
      statusCode: statusCode,
    );
  }

  static String? _messageFromError(Map<String, dynamic> error) {
    final message = error['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }

  static String? _messageFromDetail(Object? detail) {
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (detail is List) {
      for (final item in detail) {
        if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
        if (item is Map<String, dynamic>) {
          final message = item['msg'] ?? item['message'] ?? item['detail'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        } else if (item is Map) {
          final casted = item.cast<String, dynamic>();
          final message =
              casted['msg'] ?? casted['message'] ?? casted['detail'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    }
    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    if (code != null && code!.isNotEmpty) {
      buffer.write('[$code] ');
    }
    buffer.write(message);
    return buffer.toString();
  }
}
