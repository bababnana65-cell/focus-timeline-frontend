import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

import '../models/timeline_models.dart';
import '../services/remote/runtime_backend_config.dart';
import '../services/source_article_service.dart';
import '../theme/app_theme.dart';
import '../widgets/source_attribution_badges.dart';

class SourceArticleScreen extends StatefulWidget {
  const SourceArticleScreen({
    super.key,
    required this.entry,
    required this.request,
  });

  final TimelineEntry entry;
  final SourceArticleRequest request;

  @override
  State<SourceArticleScreen> createState() => _SourceArticleScreenState();
}

/// State the in-app reader walks through.
///   preparing  - building / fetching
///   loading    - native webview is loading
///   ready      - native webview finished loading
///   webExtractedReady - Web platform: backend returned an extracted body
///   webExtractedEmpty - Web platform: backend couldn't extract (offer open-in-tab)
///   failure    - any unrecoverable error
enum SourceArticleViewState {
  preparing,
  loading,
  ready,
  webExtractedReady,
  webExtractedEmpty,
  failure,
}

class _ExtractedArticle {
  const _ExtractedArticle({
    required this.title,
    required this.byline,
    required this.publishedAt,
    required this.domain,
    required this.contentText,
    required this.leadImage,
  });

  final String? title;
  final String? byline;
  final String? publishedAt;
  final String domain;
  final String contentText;
  final String? leadImage;
}

class _SourceArticleScreenState extends State<SourceArticleScreen> {
  static const SourceArticleService _sourceArticleService = SourceArticleService();

  // Native-only webview controller; left null on Web.
  WebviewController? _controller;

  StreamSubscription<String>? _titleSubscription;
  StreamSubscription<String>? _urlSubscription;
  StreamSubscription<LoadingState>? _loadingSubscription;
  StreamSubscription<WebErrorStatus>? _errorSubscription;

  SourceArticleViewState _viewState = SourceArticleViewState.preparing;
  bool _isControllerReady = false;
  String? _currentUrl;
  String? _noticeMessage;
  String? _statusMessageText;
  late String _title;

  // Web-extract state
  _ExtractedArticle? _extracted;
  String? _extractError;

  @override
  void initState() {
    super.initState();
    _title = widget.entry.title;
    _noticeMessage = widget.request.noticeMessage;
    _initializeViewer();
  }

  @override
  void dispose() {
    _titleSubscription?.cancel();
    _urlSubscription?.cancel();
    _loadingSubscription?.cancel();
    _errorSubscription?.cancel();
    if (_controller != null) {
      unawaited(_controller!.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_currentUrl != null)
              Text(
                _currentUrl!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
          ],
        ),
        actions: <Widget>[
          if (widget.request.canOpenInApp)
            IconButton(
              tooltip: '在浏览器打开',
              onPressed: () =>
                  launchUrl(widget.request.uri!, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          IconButton(
            tooltip: '关闭',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_viewState == SourceArticleViewState.failure) {
      return _buildFailure(context);
    }
    if (_viewState == SourceArticleViewState.webExtractedEmpty) {
      return _buildWebFallback(context);
    }
    if (_viewState == SourceArticleViewState.webExtractedReady) {
      return _buildWebReader(context);
    }
    // Preparing / loading / ready  — native webview path
    return _buildNativeWebview(context);
  }

  Widget _buildFailure(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.language_rounded, size: 44, color: AppTheme.accent),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 16),
            if (widget.request.canOpenInApp)
              FilledButton.icon(
                onPressed: () =>
                    launchUrl(widget.request.uri!, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('在浏览器打开原文'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebReader(BuildContext context) {
    final article = _extracted!;
    final body = article.contentText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SourceAttributionBadges(entry: widget.entry, compact: true),
            const SizedBox(height: 12),
            if (article.title != null && article.title!.isNotEmpty)
              Text(
                article.title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: <Widget>[
                if (article.byline != null && article.byline!.isNotEmpty)
                  _MetaPill(text: article.byline!),
                if (article.publishedAt != null && article.publishedAt!.isNotEmpty)
                  _MetaPill(text: article.publishedAt!),
                _MetaPill(text: article.domain),
              ],
            ),
            if (article.leadImage != null && article.leadImage!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.leadImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SelectableText(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.75,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(widget.request.uri!, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('在浏览器查看原网页'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.article_outlined, size: 44, color: AppTheme.accent),
            const SizedBox(height: 16),
            Text(
              _extractError ?? '后端暂时无法提取该网页的正文。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  launchUrl(widget.request.uri!, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('在浏览器打开原文'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeWebview(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                if (_noticeMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: AppTheme.highlightSoft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppTheme.highlight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _noticeMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6C5835),
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SourceAttributionBadges(
                      entry: widget.entry,
                      compact: true,
                    ),
                  ),
                ),
                Expanded(
                  child: (_controller != null && _isControllerReady)
                      ? Webview(
                          _controller!,
                          permissionRequested: (_, __, ___) =>
                              WebviewPermissionDecision.allow,
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
        if (_isShowingProgress)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Future<void> _initializeViewer() async {
    if (!widget.request.canOpenInApp) {
      _setFailure(widget.request.errorMessage ?? '当前节点暂未提供可打开的原文链接。');
      return;
    }

    // ---- Web: backend-extract + native Flutter render ----
    if (kIsWeb) {
      await _loadExtractedForWeb();
      return;
    }

    // ---- Native Windows: in-app WebView2 ----
    if (defaultTargetPlatform != TargetPlatform.windows) {
      _setFailure('当前平台暂未启用应用内原文窗口。');
      return;
    }

    final version = await WebviewController.getWebViewVersion();
    if (version == null) {
      _setFailure('当前系统缺少 WebView2 运行环境，无法在程序内显示原文。');
      return;
    }

    _controller = WebviewController();
    try {
      await _controller!.initialize();
      await _controller!.setBackgroundColor(AppTheme.background);
      await _controller!.setPopupWindowPolicy(WebviewPopupWindowPolicy.sameWindow);
    } on PlatformException {
      if (!mounted) return;
      _setFailure('原文窗口初始化失败，请稍后重试。');
      return;
    }

    if (mounted) {
      setState(() {
        _isControllerReady = true;
        _viewState = SourceArticleViewState.loading;
      });
    }
    _wireWebviewStreams();
    await _controller!.loadUrl(widget.request.uri!.toString());
  }

  Future<void> _loadExtractedForWeb() async {
    final uri = widget.request.uri!;
    // Build backend URL from RuntimeBackendConfig (dart-define).
    final backend = RuntimeBackendConfig.fromEnvironment.baseUrl;
    if (backend.isEmpty) {
      _setFailure('未配置后端地址，无法在应用内显示原文。');
      return;
    }
    final endpoint = Uri.parse(
      '${backend.endsWith('/') ? backend.substring(0, backend.length - 1) : backend}'
      '/articles/extract',
    ).replace(queryParameters: <String, String>{'url': uri.toString()});

    try {
      final resp = await http.get(endpoint);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw http.ClientException('HTTP ${resp.statusCode}');
      }
      final raw = jsonDecode(utf8.decode(resp.bodyBytes));
      // Envelope: {success, data}
      final data = (raw is Map && raw['data'] is Map)
          ? (raw['data'] as Map).cast<String, dynamic>()
          : (raw as Map).cast<String, dynamic>();
      if (data['ok'] == true && (data['contentText'] as String? ?? '').isNotEmpty) {
        final article = _ExtractedArticle(
          title: (data['title'] as String?)?.trim().isEmpty ?? true
              ? widget.entry.title
              : (data['title'] as String),
          byline: data['byline'] as String?,
          publishedAt: data['publishedAt'] as String?,
          domain: (data['domain'] as String?) ?? uri.host,
          contentText: data['contentText'] as String,
          leadImage: data['leadImage'] as String?,
        );
        if (!mounted) return;
        setState(() {
          _extracted = article;
          _title = article.title ?? widget.entry.title;
          _currentUrl = uri.toString();
          _viewState = SourceArticleViewState.webExtractedReady;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _extractError =
              (data['fallbackReason'] as String?) ?? '后端无法提取该网页正文，请直接在浏览器查看。';
          _viewState = SourceArticleViewState.webExtractedEmpty;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extractError = '正文提取失败：$e';
        _viewState = SourceArticleViewState.webExtractedEmpty;
      });
    }
  }

  void _wireWebviewStreams() {
    if (_controller == null) return;
    _titleSubscription = _controller!.title.listen((value) {
      if (!mounted || value.trim().isEmpty) return;
      setState(() => _title = value);
    });
    _urlSubscription = _controller!.url.listen((value) {
      if (!mounted) return;
      setState(() => _currentUrl = value);
    });
    _loadingSubscription = _controller!.loadingState.listen((state) {
      if (!mounted) return;
      if (state == LoadingState.navigationCompleted) {
        setState(() {
          _viewState = SourceArticleViewState.ready;
          _statusMessageText = null;
        });
      } else if (state == LoadingState.loading) {
        setState(() => _viewState = SourceArticleViewState.loading);
      }
    });
    _errorSubscription = _controller!.onLoadError.listen((status) {
      if (!mounted) return;
      _setFailure(_sourceArticleService.messageForLoadError(
        status,
        isFallbackSearch: widget.request.kind == SourceArticleOpenKind.searchFallback,
      ));
    });
  }

  void _setFailure(String message) {
    if (!mounted) return;
    setState(() {
      _viewState = SourceArticleViewState.failure;
      _statusMessageText = message;
    });
  }

  Future<void> _retryLoad() async {
    if (_controller == null) return;
    setState(() {
      _viewState = SourceArticleViewState.loading;
      _statusMessageText = null;
    });
    await _controller!.loadUrl(widget.request.uri!.toString());
  }

  String get _statusMessage =>
      _statusMessageText ?? widget.request.errorMessage ?? '原文加载失败。';

  bool get _isShowingProgress => _viewState == SourceArticleViewState.loading;
}


class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
            ),
      ),
    );
  }
}
