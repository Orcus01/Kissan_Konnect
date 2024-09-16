import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '1cf0b92df8f6b8b25b7d4d6ac99de193'; // Replace with your OpenWeatherMap API key
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final url = Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric');
    print('Fetching weather data from: $url'); // Log URL for debugging

    final response = await http.get(url);

    print('Response status: ${response.statusCode}'); // Log status code for debugging
    print('Response body: ${response.body}'); // Log response body for debugging

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
