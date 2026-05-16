import 'package:webview_windows/webview_windows.dart';

import '../models/timeline_models.dart';

enum SourceArticleOpenKind {
  direct,
  searchFallback,
  unavailable,
}

class SourceArticleRequest {
  const SourceArticleRequest({
    required this.kind,
    required this.uri,
    this.noticeMessage,
    this.errorMessage,
  });

  final SourceArticleOpenKind kind;
  final Uri? uri;
  final String? noticeMessage;
  final String? errorMessage;

  bool get canOpenInApp => uri != null;
}

class SourceArticleService {
  const SourceArticleService();

  SourceArticleRequest createRequest(TimelineEntry entry) {
    final rawUrl = entry.sourceUrl?.trim();
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (_containsWhitespace(rawUrl)) {
        return _buildSearchFallback(
          entry,
          noticeMessage: '原文链接格式异常，已改为搜索结果页。',
        );
      }

      final parsed = Uri.tryParse(rawUrl);
      if (parsed != null && _isSupportedWebUri(parsed)) {
        return SourceArticleRequest(
          kind: SourceArticleOpenKind.direct,
          uri: parsed,
        );
      }

      return _buildSearchFallback(
        entry,
        noticeMessage: parsed == null
            ? '原文链接格式异常，已改为搜索结果页。'
            : '当前原文链接不是网页地址，已改为搜索结果页。',
      );
    }

    return _buildSearchFallback(
      entry,
      noticeMessage: '当前节点未附带原文链接，已打开搜索结果页。',
    );
  }

  String messageForLoadError(
    WebErrorStatus status, {
    required bool isFallbackSearch,
  }) {
    final target = isFallbackSearch ? '搜索结果页' : '原文页面';

    switch (status) {
      case WebErrorStatus.WebErrorStatusServerUnreachable:
      case WebErrorStatus.WebErrorStatusTimeout:
      case WebErrorStatus.WebErrorStatusConnectionAborted:
      case WebErrorStatus.WebErrorStatusConnectionReset:
      case WebErrorStatus.WebErrorStatusDisconnected:
      case WebErrorStatus.WebErrorStatusCannotConnect:
      case WebErrorStatus.WebErrorStatusHostNameNotResolved:
        return '$target暂时无法连接，请稍后重试。';
      case WebErrorStatus.WebErrorStatusCertificateCommonNameIsIncorrect:
      case WebErrorStatus.WebErrorStatusCertificateExpired:
      case WebErrorStatus.WebErrorStatusClientCertificateContainsErrors:
      case WebErrorStatus.WebErrorStatusCertificateRevoked:
      case WebErrorStatus.WebErrorStatusCertificateIsInvalid:
      case WebErrorStatus.WebErrorStatusValidAuthenticationCredentialsRequired:
      case WebErrorStatus.WebErrorStatusValidProxyAuthenticationRequired:
        return '$target的安全校验失败，暂时无法在程序内打开。';
      case WebErrorStatus.WebErrorStatusErrorHTTPInvalidServerResponse:
      case WebErrorStatus.WebErrorStatusRedirectFailed:
        return '$target返回异常，暂时无法在程序内打开。';
      case WebErrorStatus.WebErrorStatusOperationCanceled:
        return '当前页面加载已取消。';
      case WebErrorStatus.WebErrorStatusUnknown:
      case WebErrorStatus.WebErrorStatusUnexpectedError:
        return '$target加载失败，请稍后重试。';
    }
  }

  SourceArticleRequest _buildSearchFallback(
    TimelineEntry entry, {
    required String noticeMessage,
  }) {
    final queryParts = <String>[
      entry.sourceName.trim(),
      entry.title.trim(),
    ].where((part) => part.isNotEmpty).toList();

    if (queryParts.isEmpty) {
      return const SourceArticleRequest(
        kind: SourceArticleOpenKind.unavailable,
        uri: null,
        errorMessage: '当前节点暂未提供可打开的原文链接。',
      );
    }

    return SourceArticleRequest(
      kind: SourceArticleOpenKind.searchFallback,
      uri: Uri.https(
        'www.baidu.com',
        '/s',
        <String, String>{'wd': queryParts.join(' ')},
      ),
      noticeMessage: noticeMessage,
    );
  }

  bool _isSupportedWebUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.hasAuthority;
  }

  bool _containsWhitespace(String value) {
    return value.contains(RegExp(r'\s'));
  }
}
