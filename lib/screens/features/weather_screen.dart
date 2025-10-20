import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../widgets/customize_appbar.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String city = "Your Location";
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    fetchWeatherByLocation();
  }

  Future<void> fetchWeatherByLocation() async {
    setState(() => isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = Uri.parse(
          'https://wttr.in/${position.latitude},${position.longitude}?format=j1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['current_condition'] == null) {
          setState(() => isLoading = false);
          return;
        }

        setState(() {
          weatherData = data;
          city = data['nearest_area']?[0]['areaName']?[0]['value'] ?? "Unknown";
          isLoading = false;
        });

        _speakWeather(data);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Weather fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _speakWeather(Map<String, dynamic> data) async {
    final current = data['current_condition'][0];
    final temp = current['temp_C'];
    final desc = current['weatherDesc'][0]['value'];
    final feelsLike = current['FeelsLikeC'];
    final humidity = current['humidity'];
    final windSpeed = current['windspeedKmph'];

    String speech =
        "Weather in $city: $desc, temperature $temp°C, feels like $feelsLike°C. Humidity $humidity percent, wind speed $windSpeed kilometers per hour.";
    await flutterTts.speak(speech);
  }

  String getWeatherStatus(Map<String, dynamic> data) {
    final current = data['current_condition'][0];
    final temp = int.parse(current['temp_C']);
    final wind = int.parse(current['windspeedKmph']);
    final humidity = int.parse(current['humidity']);

    if (temp >= 35 || wind >= 80 || humidity >= 90) return "Danger ⚠️";
    if (temp >= 30 || wind >= 50 || humidity >= 70) return "Warning ⚡";
    return "Safe ✅";
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : weatherData == null
            ? const Center(child: Text("Unable to load weather data"))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                city,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Status: ${getWeatherStatus(weatherData!)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getWeatherStatus(weatherData!) ==
                      "Danger ⚠️"
                      ? Colors.red
                      : getWeatherStatus(weatherData!) ==
                      "Warning ⚡"
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _speakWeather(weatherData!),
                icon: const Icon(Icons.volume_up),
                label: const Text("Speak Weather"),
              ),
              const SizedBox(height: 20),
              _buildWeatherCard(weatherData!),
              const SizedBox(height: 20),
              _buildWeatherDetails(weatherData!),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> data) {
    final current = data['current_condition'][0];
    final temp = current['temp_C'];
    final desc = current['weatherDesc'][0]['value'];
    String iconUrl = current['weatherIconUrl'][0]['value'];

    // 🔧 Force HTTPS even if the API gives malformed links
    if (!iconUrl.startsWith('http')) iconUrl = 'https:${iconUrl.replaceAll(RegExp(r"^/+"), "")}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: Image.network(
                iconUrl,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$temp°C",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(Map<String, dynamic> data) {
    final current = data['current_condition'][0];
    final humidity = current['humidity'];
    final windSpeed = current['windspeedKmph'];
    final feelsLike = current['FeelsLikeC'];
    final pressure = current['pressure'];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 3 / 2,
      children: [
        _buildDetailCard("Humidity", "$humidity%", Icons.opacity, Colors.blue),
        _buildDetailCard(
            "Feels Like", "$feelsLike°C", Icons.thermostat, Colors.orange),
        _buildDetailCard(
            "Wind Speed", "$windSpeed km/h", Icons.air, Colors.lightBlue),
        _buildDetailCard(
            "Pressure", "$pressure hPa", Icons.speed, Colors.green),
      ],
    );
  }

  Widget _buildDetailCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
