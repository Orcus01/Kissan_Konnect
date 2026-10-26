import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kissan_konnect/services/weather_service.dart';

void main() {
  test('Missing configuration makes no network request', () async {
    final service = WeatherService(
        apiKey: '',
        client: MockClient((_) async {
          fail('No request should be sent without a key');
        }));
    addTearDown(service.dispose);
    await expectLater(service.fetchWeather('Kharar'), throwsStateError);
  });

  test('City names are encoded and metric weather is returned', () async {
    final service = WeatherService(
        apiKey: 'test-only',
        client: MockClient((request) async {
          expect(request.url.queryParameters['q'], 'New Delhi');
          expect(request.url.queryParameters['units'], 'metric');
          return http.Response(
              jsonEncode({
                'main': {'temp': 24},
                'weather': [
                  {'description': 'clear'}
                ]
              }),
              200);
        }));
    addTearDown(service.dispose);
    expect((await service.fetchWeather(' New Delhi '))['main']['temp'], 24);
  });

  test('Failed provider response reports failure', () async {
    final service = WeatherService(
        apiKey: 'test-only',
        client: MockClient((_) async => http.Response('{}', 401)));
    addTearDown(service.dispose);
    await expectLater(service.fetchWeather('Kharar'), throwsException);
  });

  test('Malformed success response is rejected', () async {
    final service = WeatherService(
        apiKey: 'test-only',
        client: MockClient((_) async => http.Response('{"weather":[]}', 200)));
    addTearDown(service.dispose);
    await expectLater(service.fetchWeather('Kharar'), throwsFormatException);
  });
}
