import 'package:agent_client/core/network/dio_provider.dart';
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
}
