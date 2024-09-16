import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kissan_konnect/core/color.dart'; // Ensure this file contains the color definitions
import '../services/weather_service.dart'; // Ensure you have this service for fetching weather data

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String _city = 'Kharar'; // Example city name
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = _formatTime(DateTime.now());
    _fetchWeather();
    _startClock();
  }

  void _startClock() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = _formatTime(DateTime.now());
      });
    });
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchWeather() async {
    try {
      final data = await _weatherService.fetchWeather(_city);
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        _isLoading = false;
      });
      // Handle error (e.g., show a snackbar or dialog)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              _isLoading ? _buildLoadingIndicator() : _buildWeatherBox(),
              const SizedBox(height: 20),
              _buildFeaturedPlants(),
              const SizedBox(height: 20),
              _buildPlantTips(),
              const SizedBox(height: 20),
              _buildNewsUpdates(),
              const SizedBox(height: 20),
              _buildRecentActivities(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Text(
        'Kissan Konnect',
        style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 24),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: CircleAvatar(
            backgroundColor: green,
            radius: 20,
            child: ClipOval(
              child: Image.asset('assets/images/pro.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: _buildSearchField(),
        ),
        const SizedBox(width: 10),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45.0,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: green),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.15),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search plants, diseases...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Icon(Icons.search, color: green, size: 25),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 45.0,
      width: 45.0,
      decoration: BoxDecoration(
        color: green,
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Icon(Icons.filter_list, color: Colors.white),
    );
  }

  Widget _buildWeatherBox() {
    if (_weatherData == null) {
      return Center(child: Text('No weather data available'));
    }

    final weather = _weatherData!['weather'][0];
    final main = _weatherData!['main'];
    final temperature = main['temp'];
    final description = weather['description'];
    final humidity = main['humidity'];
    final rain = _weatherData?.containsKey('rain') == true 
        ? _weatherData!['rain']['1h'] ?? 0
        : 0;

    IconData weatherIcon;
    if (description.contains('rain')) {
      weatherIcon = Icons.grain;
    } else if (description.contains('clear')) {
      weatherIcon = Icons.wb_sunny;
    } else {
      weatherIcon = Icons.cloud;
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: green, width: 2),
        gradient: LinearGradient(
          colors: [Color(0xFFEFFFE7), Color(0xFFDFFFC7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(weatherIcon, color: green, size: 30),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _city,
                    style: TextStyle(
                      color: black.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 22.0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${temperature}°C, ${description}',
                    style: TextStyle(
                      color: black.withOpacity(0.8),
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.thermostat, color: green, size: 20),
              const SizedBox(width: 10),
              Text(
                '${temperature}°C',
                style: TextStyle(
                  color: black.withOpacity(0.8),
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.opacity, color: green, size: 20),
              const SizedBox(width: 10),
              Text(
                'Humidity: ${humidity}%',
                style: TextStyle(
                  color: black.withOpacity(0.8),
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.grain, color: green, size: 20),
              const SizedBox(width: 10),
              Text(
                'Rain: ${rain} mm',
                style: TextStyle(
                  color: black.withOpacity(0.8),
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, color: green, size: 20),
              const SizedBox(width: 10),
              Text(
                'Time: $_currentTime',
                style: TextStyle(
                  color: black.withOpacity(0.8),
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPlants() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: green, width: 2),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Plants',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
          ),
          const SizedBox(height: 15),
          // Add your featured plants content here
          Text(
            'Explore a variety of plants suitable for different climates and soil types. Learn about their care requirements and how to grow them successfully in your garden.',
            style: TextStyle(
              color: black.withOpacity(0.8),
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTips() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: green, width: 2),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plant Care Tips',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
          ),
          const SizedBox(height: 15),
          // Add your plant tips content here
          Text(
            'Keep your plants healthy by watering them correctly, providing enough light, and using the right soil. Learn about common pests and diseases and how to prevent them.',
            style: TextStyle(
              color: black.withOpacity(0.8),
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsUpdates() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: green, width: 2),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest News',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
          ),
          const SizedBox(height: 15),
          // Add your news updates content here
          Text(
            'Stay updated with the latest news on agriculture, gardening, and plant care. Find out about new technologies, market trends, and best practices.',
            style: TextStyle(
              color: black.withOpacity(0.8),
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: green, width: 2),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.bold,
              fontSize: 22.0,
            ),
          ),
          const SizedBox(height: 15),
          // Add your recent activities content here
          Text(
            'Track your recent activities such as plant diagnoses, interactions in the community, and more. Keep a record of your progress and achievements.',
            style: TextStyle(
              color: black.withOpacity(0.8),
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(color: green),
    );
  }
}
