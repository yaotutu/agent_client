import 'dart:typed_data';

import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/core/network/dio_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('dio defaults do not force JSON Content-Type on GET requests', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.headers['Accept'], 'application/json');
    expect(dio.options.headers.containsKey('Content-Type'), isFalse);
  });

  test('dio sends the bundled api key by default', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final adapter = _RecordingAdapter();

    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await dio.get<Object?>('/agents');

    final authorization = adapter.authorizationFor('GET /agents');
    expect(authorization, startsWith('Bearer '));
    expect(authorization?.length, greaterThan('Bearer '.length));
  });

  test('dio adds bearer auth to application requests except health', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            apiBaseUrl: 'http://example.test',
            apiKey: 'test-api-key',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final adapter = _RecordingAdapter();

    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await dio.get<Object?>('/agents');
    await dio.get<Object?>('/health');

    expect(adapter.authorizationFor('GET /agents'), 'Bearer test-api-key');
    expect(adapter.authorizationFor('GET /health'), isNull);
  });

  test('dio adds bearer auth to stream requests', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            apiBaseUrl: 'http://example.test',
            apiKey: 'test-api-key',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final adapter = _RecordingAdapter();

    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await dio.post<ResponseBody>(
      '/agents/default/sessions/session-1/messages',
      data: {'content': 'hello', 'stream': true},
      options: Options(
        responseType: ResponseType.stream,
        headers: const {'Accept': 'text/event-stream'},
      ),
    );

    expect(
      adapter.authorizationFor(
        'POST /agents/default/sessions/session-1/messages',
      ),
      'Bearer test-api-key',
    );
    expect(
      adapter.acceptFor('POST /agents/default/sessions/session-1/messages'),
      'text/event-stream',
    );
  });

  test('dio omits authorization when api key is empty', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(apiBaseUrl: 'http://example.test', apiKey: ''),
        ),
      ],
    );
    addTearDown(container.dispose);
    final adapter = _RecordingAdapter();

    final dio = container.read(dioProvider)..httpClientAdapter = adapter;

    await dio.get<Object?>('/agents');

    expect(adapter.authorizationFor('GET /agents'), isNull);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <String, Map<String, Object?>>{};

  String? authorizationFor(String request) {
    return requests[request]?['Authorization']?.toString();
  }

  String? acceptFor(String request) {
    return requests[request]?['Accept']?.toString();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests['${options.method} ${options.path}'] = Map.of(options.headers);
    if (options.responseType == ResponseType.stream) {
      return ResponseBody(Stream<Uint8List>.empty(), 200);
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}
