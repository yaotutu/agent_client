import 'package:agent_client/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final headers = <String, Object>{'Accept': 'application/json'};

  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 20),
      headers: headers,
    ),
  );
});
