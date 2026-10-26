import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kissan_konnect/services/workspace_api.dart';

void main() {
  test('Sends image bytes to configured local endpoint with encoded crop',
      () async {
    final api = WorkspaceApi(
        baseUri: Uri.parse('http://localhost:8765/api/'),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/predict');
          expect(request.url.queryParameters['crop'], 'Bell pepper');
          expect(request.bodyBytes, [1, 2, 3]);
          expect(request.headers['Content-Type'], 'application/octet-stream');
          return http.Response('{"status":"uncertain"}', 200);
        }));
    addTearDown(api.close);
    expect(
        (await api.predict(
            Uint8List.fromList([1, 2, 3]), 'Bell pepper'))['status'],
        'uncertain');
  });
  test('Provider validation error is preserved for user recovery', () async {
    final api = WorkspaceApi(
        baseUri: Uri.parse('http://localhost/api/'),
        client: MockClient((_) async =>
            http.Response('{"detail":"Choose a sharper photo"}', 422)));
    addTearDown(api.close);
    await expectLater(
        api.predict(Uint8List(0), 'Tomato'),
        throwsA(isA<WorkspaceException>()
            .having((e) => e.message, 'message', 'Choose a sharper photo')));
  });
  test('Non-JSON service failures produce a useful connection error', () async {
    final api = WorkspaceApi(
        baseUri: Uri.parse('http://localhost/api/'),
        client: MockClient((_) async => http.Response('not JSON', 502)));
    addTearDown(api.close);
    await expectLater(api.model(), throwsA(isA<WorkspaceException>()));
  });
  test('Decodes UTF-8 model metadata without a response charset', () async {
    final api = WorkspaceApi(
        baseUri: Uri.parse('http://localhost/api/'),
        client: MockClient((_) async => http.Response.bytes(
            utf8.encode('{"name":"ConCaPlant · MobileNetV3"}'), 200,
            headers: {'content-type': 'application/json'})));
    addTearDown(api.close);
    expect((await api.model())['name'], 'ConCaPlant · MobileNetV3');
  });
}
