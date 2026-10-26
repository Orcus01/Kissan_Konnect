import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('OPENWEATHER_API_KEY');

  final http.Client _client;
  final String _apiKey;

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    if (_apiKey.isEmpty) throw StateError('Weather is not configured.');
    if (city.trim().isEmpty) throw ArgumentError('Enter a city.');
    final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': city.trim(),
      'appid': _apiKey,
      'units': 'metric',
    });
    final response =
        await _client.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather unavailable (${response.statusCode}).');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> ||
        data['main'] is! Map ||
        data['weather'] is! List ||
        (data['weather'] as List).isEmpty) {
      throw const FormatException('Invalid weather response.');
    }
    return data;
  }

  void dispose() => _client.close();
}
