import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

import '../models/timeline_models.dart';
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

class _SourceArticleScreenState extends State<SourceArticleScreen> {
  static const SourceArticleService _sourceArticleService = SourceArticleService();

  final WebviewController _controller = WebviewController();

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
    unawaited(_controller.dispose());
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
          IconButton(
            tooltip: '刷新',
            onPressed: _isControllerReady
                ? () async {
                    await _controller.reload();
                  }
                : null,
            icon: const Icon(Icons.refresh_rounded),
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  if (_isControllerReady && widget.request.canOpenInApp)
                    FilledButton(
                      onPressed: _retryLoad,
                      child: const Text('重试'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

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
                  child: _isControllerReady
                      ? Webview(
                          _controller,
                          permissionRequested: (_, __, ___) => WebviewPermissionDecision.allow,
                        )
                      : const SizedBox.shrink(),
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

    // Flutter Web doesn't ship webview_windows. Hand the URL off to the
    // browser tab system instead — same UX as native 'open in browser'.
    if (kIsWeb) {
      final uri = widget.request.uri!;
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (launched) {
        // Pop back to the timeline so the user sees their previous context;
        // the article will load in a separate tab.
        Navigator.of(context).pop();
      } else {
        _setFailure('无法打开原文链接：$uri');
      }
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.windows) {
      _setFailure('当前平台暂未启用应用内原文窗口。');
      return;
    }

    final version = await WebviewController.getWebViewVersion();
    if (version == null) {
      _setFailure('当前系统缺少 WebView2 运行环境，无法在程序内显示原文。');
      return;
    }

    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(AppTheme.background);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.sameWindow);
    } on PlatformException {
      if (!mounted) {
        return;
      }
      _setFailure('原文窗口初始化失败，请稍后重试。');
      return;
    }

    if (mounted) {
      setState(() {
        _isControllerReady = true;
        _viewState = SourceArticleViewState.loading;
      });
    }

    _titleSubscription = _controller.title.listen((value) {
      if (!mounted || value.trim().isEmpty) {
        return;
      }
      setState(() => _title = value);
    });
    _urlSubscription = _controller.url.listen((value) {
      if (!mounted) {
        return;
      }
      setState(() => _currentUrl = value);
    });
    _loadingSubscription = _controller.loadingState.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (state == LoadingState.loading) {
          _viewState = SourceArticleViewState.loading;
        }
        if (state == LoadingState.navigationCompleted) {
          _viewState = SourceArticleViewState.ready;
        }
      });
    });
    _errorSubscription = _controller.onLoadError.listen((status) {
      if (!mounted) {
        return;
      }
      _setFailure(
        _sourceArticleService.messageForLoadError(
          status,
          isFallbackSearch: widget.request.kind == SourceArticleOpenKind.searchFallback,
        ),
      );
    });

    try {
      await _controller.loadUrl(widget.request.uri!.toString());
    } on PlatformException {
      if (!mounted) {
        return;
      }
      _setFailure('原文地址暂时无法打开，请稍后重试。');
      return;
    }
  }

  Future<void> _retryLoad() async {
    if (!_isControllerReady || widget.request.uri == null) {
      return;
    }

    setState(() {
      _viewState = SourceArticleViewState.loading;
    });
    await _controller.loadUrl(widget.request.uri!.toString());
  }

  void _setFailure(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _viewState = SourceArticleViewState.failure;
      _statusMessageText = message;
    });
  }

  String get _statusMessage => _statusMessageText ?? '原文页面加载失败，请稍后重试。';

  bool get _isShowingProgress {
    return _viewState == SourceArticleViewState.preparing ||
        _viewState == SourceArticleViewState.loading;
  }
}

enum SourceArticleViewState {
  preparing,
  loading,
  ready,
  failure,
}
