import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/source_article_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_windows/webview_windows.dart';

void main() {
  const service = SourceArticleService();

  TimelineEntry buildEntry({
    String title = 'AI 大模型发布',
    String sourceName = '试点通报',
    String? sourceUrl,
  }) {
    return TimelineEntry(
      id: 'entry-1',
      topicId: 'topic-1',
      title: title,
      summary: '摘要',
      detail: '详情',
      fullText: '全文',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      timestamp: DateTime(2026, 4, 15, 10, 30),
      isMajor: false,
    );
  }

  test('opens valid web source links directly', () {
    final request = service.createRequest(
      buildEntry(sourceUrl: 'https://example.com/article?id=1'),
    );

    expect(request.kind, SourceArticleOpenKind.direct);
    expect(request.uri?.toString(), 'https://example.com/article?id=1');
    expect(request.noticeMessage, isNull);
  });

  test('falls back to search when source link is missing', () {
    final request = service.createRequest(buildEntry(sourceUrl: null));

    expect(request.kind, SourceArticleOpenKind.searchFallback);
    expect(request.uri?.host, 'www.baidu.com');
    expect(request.noticeMessage, '当前节点未附带原文链接，已打开搜索结果页。');
  });

  test('falls back to search when source link is malformed', () {
    final request = service.createRequest(
      buildEntry(sourceUrl: 'https://exa mple.com/bad url'),
    );

    expect(request.kind, SourceArticleOpenKind.searchFallback);
    expect(request.noticeMessage, '原文链接格式异常，已改为搜索结果页。');
  });

  test('falls back to search when source link uses unsupported scheme', () {
    final request = service.createRequest(
      buildEntry(sourceUrl: 'mailto:editor@example.com'),
    );

    expect(request.kind, SourceArticleOpenKind.searchFallback);
    expect(request.noticeMessage, '当前原文链接不是网页地址，已改为搜索结果页。');
  });

  test('returns network-specific load error message', () {
    final message = service.messageForLoadError(
      WebErrorStatus.WebErrorStatusHostNameNotResolved,
      isFallbackSearch: false,
    );

    expect(message, '原文页面暂时无法连接，请稍后重试。');
  });

  test('returns security-specific load error message', () {
    final message = service.messageForLoadError(
      WebErrorStatus.WebErrorStatusCertificateExpired,
      isFallbackSearch: true,
    );

    expect(message, '搜索结果页的安全校验失败，暂时无法在程序内打开。');
  });

  test('returns invalid-response load error message', () {
    final message = service.messageForLoadError(
      WebErrorStatus.WebErrorStatusErrorHTTPInvalidServerResponse,
      isFallbackSearch: false,
    );

    expect(message, '原文页面返回异常，暂时无法在程序内打开。');
  });
}
