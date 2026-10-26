import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/workspace_api.dart';
import 'common.dart';

class WeatherPage extends StatefulWidget {
  final WorkspaceApi? api;
  const WeatherPage({super.key, this.api});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _city = TextEditingController();
  List<dynamic> _locations = [];
  Map<String, dynamic>? _forecast;
  Map<String, dynamic>? _location;
  bool _busy = false;
  String? _error;
  WorkspaceApi get api => widget.api ?? workspaceApi;
  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_city.text.trim().length < 2) {
      setState(() {
        _error = 'Enter at least two letters of a city name.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _locations = [];
      _forecast = null;
      _location = null;
    });
    try {
      final response = await api.locations(_city.text.trim());
      if (mounted) {
        setState(() {
          _locations = response['locations'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _load(Map<String, dynamic> location) async {
    setState(() {
      _busy = true;
      _error = null;
      _forecast = null;
      _location = location;
    });
    try {
      final forecast =
          await api.forecast(location['latitude'], location['longitude']);
      if (mounted) {
        setState(() {
          _forecast = forecast;
          _locations = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  String _condition(num code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code <= 48) return 'Fog';
    if (code <= 67) return 'Rain / drizzle';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorms';
  }

  @override
  Widget build(BuildContext context) {
    final current = _forecast?['current'];
    final daily = _forecast?['daily'];
    return workspaceBody([
      sectionLabel('Weather / city forecast'),
      pageTitle(context, 'Plan with the forecast.'),
      const Text(
          'Search a city to see current conditions and the next five days. Your device location is not requested.',
          style: TextStyle(color: muted, fontSize: 16)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(
            child: TextField(
                controller: _city,
                enabled: !_busy,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                    labelText: 'City name',
                    hintText: 'e.g. Kharar',
                    border: OutlineInputBorder()))),
        const SizedBox(width: 12),
        IconButton.filled(
            tooltip: 'Search cities',
            onPressed: _busy ? null : _search,
            icon: const Icon(Icons.search))
      ]),
      const SizedBox(height: 12),
      const Text(
          'City searches and selected city coordinates are sent to Open-Meteo for weather data.',
          style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 24),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null)
        errorNotice(_error!, () {
          if (_location != null) {
            _load(_location!);
          } else {
            _search();
          }
        }),
      if (_locations.isNotEmpty) ...[
        sectionLabel('Choose the matching city'),
        const SizedBox(height: 12),
        ..._locations.map((location) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(location['name']),
            subtitle: Text('${location['region']}, ${location['country']}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: _busy
                ? null
                : () => _load(Map<String, dynamic>.from(location)))),
      ],
      if (current != null) ...[
        const SizedBox(height: 16),
        Text('${_location!['name']}, ${_location!['country']}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        Text('${current['temperature_2m']}°',
            style: const TextStyle(
                fontSize: 76, fontWeight: FontWeight.w500, color: ink)),
        Text(_condition(current['weather_code']),
            style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 24),
        Wrap(spacing: 32, runSpacing: 16, children: [
          Text('Humidity ${current['relative_humidity_2m']}%'),
          Text('Wind ${current['wind_speed_10m']} km/h'),
          Text('Precipitation ${current['precipitation']} mm')
        ]),
        const SizedBox(height: 16),
        Text(
            'Modelled conditions: ${current['time']} · ${_forecast!['timezone']}\nProvider data, not an on-farm sensor measurement.',
            style: const TextStyle(color: muted, fontSize: 12)),
        const Divider(height: 48),
        sectionLabel('Five-day outlook'),
        const SizedBox(height: 16),
        ...List.generate(
            (daily['time'] as List).length,
            (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text(DateFormat('EEE, d MMM')
                          .format(DateTime.parse(daily['time'][i])))),
                  Expanded(
                      flex: 3,
                      child: Text(_condition(daily['weather_code'][i]),
                          style: const TextStyle(color: muted))),
                  Expanded(
                      flex: 2,
                      child: Text(
                          '${daily['temperature_2m_min'][i]}–${daily['temperature_2m_max'][i]}°C')),
                  Expanded(
                      flex: 2,
                      child: Text(
                          '${daily['precipitation_probability_max'][i]}% rain',
                          textAlign: TextAlign.right)),
                ]))),
        TextButton.icon(
            onPressed: _busy ? null : () => _load(_location!),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh forecast')),
      ],
      if (!_busy && _error == null && _forecast == null && _locations.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 72),
            child: Column(children: [
              Icon(Icons.cloud_outlined, size: 48, color: muted),
              SizedBox(height: 16),
              Text('Start with a city.', style: TextStyle(fontSize: 22)),
              SizedBox(height: 8),
              Text('Weather data needs an internet connection.',
                  style: TextStyle(color: muted))
            ])),
      const SizedBox(height: 24),
      TextButton(
          onPressed: () => launchUrl(Uri.parse('https://open-meteo.com/'),
              mode: LaunchMode.externalApplication),
          child: const Text('Weather data by Open-Meteo · CC BY 4.0')),
    ], width: 850);
  }
}
