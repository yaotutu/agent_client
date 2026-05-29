import 'package:agent_client/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final headers = <String, Object>{'Accept': 'application/json'};

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 20),
      headers: headers,
    ),
  );
  dio.interceptors.add(_AgentAuthInterceptor(apiKey: config.apiKey));
  return dio;
});

class _AgentAuthInterceptor extends Interceptor {
  const _AgentAuthInterceptor({required this.apiKey});

  final String apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = apiKey.trim();
    if (key.isNotEmpty && !_isHealthRequest(options.path)) {
      options.headers['Authorization'] = 'Bearer $key';
    }
    handler.next(options);
  }

  bool _isHealthRequest(String path) {
    final uri = Uri.tryParse(path);
    final normalizedPath = uri?.path ?? path;
    return normalizedPath == '/health' || normalizedPath == 'health';
  }
}
