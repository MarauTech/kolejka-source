import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:trainly/api/api_client.dart';

class ResponseAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) respond;
  int calls = 0;
  ResponseAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    calls++;
    return await respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      'content-type': ['application/json'],
      'retry-after': ['60']
    });

ApiClient clientFor(ResponseAdapter adapter) => ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
      ..httpClientAdapter = adapter);

void main() {
  test('HTTP diagnostics never print request or response headers', () async {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);
    final marker = List.generate(24, (i) => String.fromCharCode(65 + i)).join();
    final dio = Dio(BaseOptions(
        baseUrl: 'https://fixture.invalid',
        headers: {'X-API-Key': marker, 'Authorization': marker}));
    dio.httpClientAdapter = ResponseAdapter((_) => ResponseBody.fromString(
          '{}',
          200,
          headers: {
            'content-type': ['application/json'],
            'x-api-key': [marker],
          },
        ));
    await ApiClient(dio: dio).get('/api/v1/data-version');
    expect(messages.join('\n'), isNot(contains(marker)));
    expect(messages.join('\n').toLowerCase(), isNot(contains('x-api-key')));
  });

  test('HTTP 429 is not retried and blocks subsequent requests during cooldown',
      () async {
    final adapter = ResponseAdapter((_) => jsonResponse({}, 429));
    final client = clientFor(adapter);
    for (final path in ['/first', '/second']) {
      await expectLater(
          client.get(path),
          throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 429)));
    }
    expect(adapter.calls, 1);
  });
  for (final status in [500, 503]) {
    test('HTTP $status stops after exactly three attempts', () async {
      final adapter = ResponseAdapter((_) => jsonResponse({}, status));
      await expectLater(
          clientFor(adapter).get('/unavailable'),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'status', status)));
      expect(adapter.calls, 3);
    });
  }
  test(
      'Concurrent identical requests share one response regardless of query order',
      () async {
    final response = Completer<ResponseBody>();
    final adapter = ResponseAdapter((_) => response.future);
    final client = clientFor(adapter);
    final first = client.get('/same', queryParameters: {'a': 1, 'b': 2});
    final second = client.get('/same', queryParameters: {'b': 2, 'a': 1});
    response.complete(jsonResponse({'result': 'ok'}));
    final values = await Future.wait([first, second]);
    expect(adapter.calls, 1);
    expect(values.map((r) => r.data['result']), ['ok', 'ok']);
  });
}
