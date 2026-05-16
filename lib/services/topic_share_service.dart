import 'dart:convert';

import '../models/timeline_models.dart';

class TopicShareService {
  static const String scheme = 'timeliness';
  static const String host = 'timeline';
  static const String path = '/open';
  static const String shareTokenQueryKey = 'shareToken';

  String buildShareLink({
    required Topic topic,
    required List<TimelineEntry> entries,
  }) {
    final queryParameters = topic.id.startsWith('custom-')
        ? <String, String>{
            'payload': _encodePayload(
              <String, dynamic>{
                'topic': topic.toJson(),
                'entries': entries.map((entry) => entry.toJson()).toList(),
              },
            ),
          }
        : <String, String>{'topic': topic.id};

    return Uri(
      scheme: scheme,
      host: host,
      path: path,
      queryParameters: queryParameters,
    ).toString();
  }

  String buildShareMessage({
    required Topic topic,
    required List<TimelineEntry> entries,
  }) {
    final link = buildShareLink(topic: topic, entries: entries);
    return '我在 Timeliness 里分享了一条事件时间线：${topic.name}\n$link\n打开后可直接查看时间线，并选择是否关注。';
  }

  String buildResolvedShareMessage({
    required String topicName,
    required String shareUrl,
  }) {
    return '我在 Timeliness 里分享了一条事件时间线：$topicName\n$shareUrl\n打开后可直接查看时间线，并选择是否关注。';
  }

  ParsedTopicShare? parseIncomingRoute(String rawRoute) {
    final normalized = rawRoute.trim();
    if (normalized.isEmpty || normalized == '/') {
      return null;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      return null;
    }

    final shareToken = _extractShareToken(uri);
    if (shareToken != null && shareToken.isNotEmpty) {
      return ParsedTopicShare.shareToken(shareToken: shareToken);
    }

    final resolvedPath = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    final isSchemeValid = uri.scheme.isEmpty || uri.scheme == scheme;
    final isHostValid = uri.host.isEmpty || uri.host == host;
    if (!isSchemeValid || !isHostValid || resolvedPath != path) {
      return null;
    }

    final payload = uri.queryParameters['payload'];
    if (payload != null && payload.isNotEmpty) {
      final decoded = _decodePayload(payload);
      return ParsedTopicShare.imported(
        topic: Topic.fromJson(decoded['topic'] as Map<String, dynamic>),
        entries: (decoded['entries'] as List<dynamic>)
            .map((item) => TimelineEntry.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    final topicId = uri.queryParameters['topic'];
    if (topicId == null || topicId.isEmpty) {
      return null;
    }

    return ParsedTopicShare.reference(topicId: topicId);
  }

  String? _extractShareToken(Uri uri) {
    final queryToken = uri.queryParameters[shareTokenQueryKey] ?? uri.queryParameters['token'];
    if (queryToken != null && queryToken.isNotEmpty) {
      final isAppRoute = uri.scheme == scheme;
      final appPath = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      if (!isAppRoute || (uri.host == host && appPath == path)) {
        return queryToken;
      }
    }

    final isWebRoute = uri.scheme == 'https' || uri.scheme == 'http';
    if (!isWebRoute) {
      return null;
    }
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final shareIndex = segments.indexOf('share');
    if (shareIndex >= 0 && shareIndex + 1 < segments.length) {
      return segments[shareIndex + 1];
    }
    return null;
  }

  String _encodePayload(Map<String, dynamic> payload) {
    return base64UrlEncode(utf8.encode(jsonEncode(payload)));
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }
}

class ParsedTopicShare {
  const ParsedTopicShare.reference({
    required this.topicId,
  })  : shareToken = null,
        importedTopic = null,
        importedEntries = const <TimelineEntry>[];

  const ParsedTopicShare.shareToken({
    required this.shareToken,
  })  : topicId = null,
        importedTopic = null,
        importedEntries = const <TimelineEntry>[];

  ParsedTopicShare.imported({
    required Topic topic,
    required List<TimelineEntry> entries,
  })  : topicId = topic.id,
        shareToken = null,
        importedTopic = topic,
        importedEntries = entries;

  final String? topicId;
  final String? shareToken;
  final Topic? importedTopic;
  final List<TimelineEntry> importedEntries;

  bool get isImportedPayload => importedTopic != null;

  bool get isShareToken => shareToken != null;
}
