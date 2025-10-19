import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/customize_appbar.dart';
import '../service/tts_service.dart';
import 'dart:math' show cos, sqrt, asin;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentCenter;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool ttsEnabled = true;
  bool speechEnabled = true;
  bool isListening = false;
  String spokenText = '';

  Set<Marker> _markers = {};

  // Replace with your Google Places API key
  final String googlePlacesApiKey = "AIzaSyAFSTLE1gAErYYL7OcfffKhyBj4MJ1uDz0";

  @override
  void initState() {
    super.initState();
    _initLocation();
    TtsService.instance.init();
  }

  /// Get current location
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      TtsService.instance.speak("Please enable location services to use the map");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        TtsService.instance.speak("Location permission denied");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentCenter = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentCenter!, 15),
    );

    TtsService.instance.speak("Map is centered on your current location");
  }

  /// Voice search
  Future<void> _startVoiceSearch() async {
    if (!speechEnabled) return;
    bool available = await _speech.initialize();
    if (!available) {
      TtsService.instance.speak("Voice recognition is not available");
      return;
    }

    setState(() => isListening = true);
    spokenText = '';

    _speech.listen(
      onResult: (val) async {
        setState(() => spokenText = val.recognizedWords);

        if (val.finalResult && spokenText.isNotEmpty) {
          setState(() => isListening = false);
          await _speech.stop();
          TtsService.instance.speak("Searching nearby $spokenText");
          await _searchNearby(spokenText);
        }
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  /// Compute distance in km between two coordinates
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2*R*asin...
  }

  /// Search for nearby places (2km)
  /// Search for nearby places (2km)
  Future<void> _searchNearby(String query) async {
    if (_currentCenter == null) return;

    String keyword = query
        .toLowerCase()
        .replaceAll(RegExp(r'find|show me|near me|at my area|search for'), '')
        .trim();

    if (keyword.isEmpty) {
      await TtsService.instance.speak("Please say a place to search");
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentCenter!.latitude},${_currentCenter!.longitude}'
        '&radius=2000'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&key=$googlePlacesApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          _markers.clear();
          List<String> descriptions = [];

          for (var place in data['results']) {
            final loc = place['geometry']['location'];
            final name = place['name'];
            final lat = loc['lat'] as double;
            final lng = loc['lng'] as double;
            final vicinity = place['vicinity'] ?? "Unknown address";

            double distance = _calculateDistance(
              _currentCenter!.latitude,
              _currentCenter!.longitude,
              lat,
              lng,
            );

            // Filter within 2km
            if (distance <= 2) {
              _markers.add(
                Marker(
                  markerId: MarkerId(name),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: name,
                    snippet: "$vicinity • ${distance.toStringAsFixed(2)} km away",
                    onTap: () {
                      _trackDestination(name, LatLng(lat, lng));
                    },
                  ),
                ),
              );

              descriptions.add("$name at $vicinity, ${distance.toStringAsFixed(1)} kilometers away");
            }
          }

          setState(() {});

          if (_markers.isNotEmpty) {
            // Focus the camera
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_markers.first.position, 14),
            );

            // ✅ Wait a moment for map update, then speak results clearly
            await Future.delayed(const Duration(milliseconds: 800));

            await TtsService.instance.speak(
              "I found ${_markers.length} nearby $keyword within 2 kilometers. "
                  "For example, ${descriptions.take(2).join('. Also, ')}.",
            );
          } else {
            await TtsService.instance.speak("No $keyword found within 2 kilometers");
          }
        } else {
          await TtsService.instance.speak("No results found for $keyword nearby");
        }
      } else {
        await TtsService.instance.speak("Error fetching nearby places");
      }
    } catch (e) {
      await TtsService.instance.speak("An error occurred while searching");
    }
  }


  /// When user taps a marker, start tracking destination
  void _trackDestination(String name, LatLng destination) {
    TtsService.instance.speak("Tracking route to $name");
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(destination, 16),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 70.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  if (_currentCenter != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentCenter!,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        myLocationEnabled: true,
                        markers: _markers,
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),

                  if (isListening)
                    Positioned(
                      top: 100,
                      left: 30,
                      right: 30,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          spokenText.isEmpty ? "Listening..." : spokenText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureButton(
                          icon: Icons.mic,
                          label: isListening ? "Listening..." : "Voice",
                          color: Colors.green[700]!,
                          onTap: _startVoiceSearch,
                          size: buttonSize,
                        ),
                        _buildFeatureButton(
                          icon: Icons.info,
                          label: "Help",
                          color: Colors.orange[700]!,
                          onTap: () => TtsService.instance.speak(
                            "Press the microphone and say a place like hospital, mall, or restaurant to find nearby locations within 2 kilometers. Tap a marker to track it.",
                          ),
                          size: buttonSize,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size / 2, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
