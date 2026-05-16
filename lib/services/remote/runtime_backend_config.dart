class RuntimeBackendConfig {
  const RuntimeBackendConfig({
    required this.useHttpBackend,
    required this.baseUrl,
  });

  final bool useHttpBackend;
  final String baseUrl;

  bool get isConfigured => useHttpBackend && baseUrl.trim().isNotEmpty;

  static const RuntimeBackendConfig fromEnvironment = RuntimeBackendConfig(
    useHttpBackend: bool.fromEnvironment(
      'TIMELINESS_USE_HTTP_BACKEND',
      defaultValue: false,
    ),
    baseUrl: String.fromEnvironment(
      'TIMELINESS_API_BASE_URL',
      defaultValue: '',
    ),
  );
}
