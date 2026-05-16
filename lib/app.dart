import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/app_local_storage.dart';
import 'services/mock_timeline_repository.dart';
import 'services/phone_auth_service.dart';
import 'services/push_device_service.dart';
import 'services/remote/app_remote_services.dart';
import 'services/timeline_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/brand_logo_mark.dart';

class EventTimelineRoot extends StatefulWidget {
  const EventTimelineRoot({super.key});

  @override
  State<EventTimelineRoot> createState() => _EventTimelineRootState();
}

class _EventTimelineRootState extends State<EventTimelineRoot>
    with WidgetsBindingObserver {
  TimelineController? _controller;
  AppRemoteServices? _remoteServices;
  PushDeviceService? _pushDeviceService;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pushDeviceService?.dispose();
    _remoteServices?.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPushRoute(String route) async {
    final controller = _controller;
    if (controller == null) {
      return false;
    }
    await controller.handleIncomingRoute(route);
    return true;
  }

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    final controller = _controller;
    if (controller == null) {
      return false;
    }
    await controller.handleIncomingRoute(routeInformation.uri.toString());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return MaterialApp(
        title: '事件时间轴',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: const _AppScrollBehavior(),
        home: _LaunchScreen(errorMessage: _bootstrapError),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: '事件时间轴',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          scrollBehavior: const _AppScrollBehavior(),
          home: controller.isBootstrapping
              ? _LaunchScreen(errorMessage: _bootstrapError)
              : HomeShell(controller: controller),
        );
      },
    );
  }

  Future<void> _bootstrap() async {
    try {
      final repository = MockTimelineRepository();
      final localStorage = AppLocalStorage();
      await localStorage.init();

      late final TimelineController controller;
      final remoteServices = AppRemoteServicesFactory.create(
        repository: repository,
        sessionTokenProvider: () => controller.session?.sessionToken,
        guestKeyProvider: () => controller.guestKey,
      );
      final pushDeviceService =
          createPushDeviceService(localStorage: localStorage);

      controller = TimelineController(
        repository: repository,
        authService: MockPhoneAuthService(
          remoteService: remoteServices.auth,
        ),
        followedTopicRemoteService: remoteServices.followedTopics,
        topicRemoteService: remoteServices.topics,
        recommendationRemoteService: remoteServices.recommendations,
        shareRemoteService: remoteServices.shares,
        favoriteTimelineBucketRemoteService:
            remoteServices.favoriteTimelineBuckets,
        profileRemoteService: remoteServices.profile,
        preferServerRuntimeTopics: remoteServices.usesHttpBackend,
        localStorage: localStorage,
        creationService: remoteServices.creation,
        pushDeviceService: pushDeviceService,
        pushDeviceRemoteService: remoteServices.pushDevices,
      );

      _controller = controller;
      _remoteServices = remoteServices;
      _pushDeviceService = pushDeviceService;

      await controller.initialize();
      await _handleInitialRoute();
    } catch (error) {
      _bootstrapError = '初始化失败：$error';
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _handleInitialRoute() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (initialRoute.isEmpty || initialRoute == '/') {
      return;
    }

    await controller.handleIncomingRoute(initialRoute);
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen({
    this.errorMessage,
  });

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    AppTheme.background,
                    AppTheme.backgroundRaised,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const BrandLogoMark(size: 82, radius: 18),
                    const SizedBox(height: 22),
                    Text(
                      '事件时间轴',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '按小时、天、月梳理事件进展，准备推荐内容与可浏览时间线。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                    ),
                    if (errorMessage != null) ...<Widget>[
                      const SizedBox(height: 14),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.danger,
                              height: 1.5,
                            ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        children: <Widget>[
                          CircularProgressIndicator(
                            color: AppTheme.accent,
                          ),
                          SizedBox(height: 18),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _LaunchMetric(
                                  value: 'Day',
                                  label: '默认聚合',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _LaunchMetric(
                                  value: 'Hot',
                                  label: '重大高亮',
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _LaunchMetric(
                                  value: 'Sync',
                                  label: '状态恢复',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchMetric extends StatelessWidget {
  const _LaunchMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
