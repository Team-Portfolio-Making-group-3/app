import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import '../widgets/customize_appbar.dart';
import '../service/tts_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isListening = false;
  bool ttsEnabled = true;
  bool speechEnabled = true;
  String spokenText = "";

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final String googleApiKey = "AIzaSyAFSTLE1gAErYYL7OcfffKhyBj4MJ1uDz0"; // Replace with your key

  @override
  void initState() {
    super.initState();
    _initLocation();
    TtsService.instance.init();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      TtsService.instance.speak("Please enable location services");
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
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
    );

    TtsService.instance.speak("Map centered on your location");
  }

  Future<void> _startVoiceSearch() async {
    if (!speechEnabled) return;

    bool available = await _speech.initialize();
    if (!available) {
      TtsService.instance.speak("Voice recognition not available");
      return;
    }

    setState(() {
      isListening = true;
      spokenText = "";
    });

    _speech.listen(onResult: (val) async {
      setState(() => spokenText = val.recognizedWords);
      if (val.finalResult && spokenText.isNotEmpty) {
        setState(() => isListening = false);
        await _speech.stop();
        TtsService.instance.speak("Searching nearby $spokenText");
        await _searchNearby(spokenText);
      }
    });
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _searchNearby(String query) async {
    if (_currentLocation == null) return;

    String keyword = query
        .toLowerCase()
        .replaceAll(RegExp(r'find|show me|near me|at my area|search for'), '')
        .trim();

    if (keyword.isEmpty) {
      await TtsService.instance.speak("Please say a place to search");
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=${_currentLocation!.latitude},${_currentLocation!.longitude}"
        "&radius=2000"
        "&keyword=${Uri.encodeComponent(keyword)}"
        "&key=$googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        _markers.clear();
        List<String> descriptions = [];

        for (var place in data["results"]) {
          final loc = place["geometry"]["location"];
          final name = place["name"];
          final lat = loc["lat"];
          final lng = loc["lng"];
          final vicinity = place["vicinity"] ?? "Unknown location";

          double distance = _calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            lat,
            lng,
          );

          if (distance <= 2) {
            _markers.add(
              Marker(
                markerId: MarkerId(name),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: name,
                  snippet:
                  "$vicinity • ${distance.toStringAsFixed(2)} km away",
                  onTap: () => _trackDestination(name, LatLng(lat, lng)),
                ),
              ),
            );
            descriptions.add(
                "$name at $vicinity, ${distance.toStringAsFixed(1)} kilometers away");
          }
        }

        setState(() {});

        if (_markers.isNotEmpty) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_markers.first.position, 14),
          );
          await TtsService.instance.speak(
            "I found ${_markers.length} nearby $keyword within 2 kilometers. "
                "For example, ${descriptions.take(2).join('. Also, ')}.",
          );
        } else {
          await TtsService.instance
              .speak("No $keyword found within 2 kilometers");
        }
      } else {
        await TtsService.instance.speak("No results found for $keyword nearby");
      }
    } catch (e) {
      await TtsService.instance.speak("Error while searching nearby places");
    }
  }

  /// 🗺️ Track the destination and draw route
  Future<void> _trackDestination(String name, LatLng destination) async {
    TtsService.instance.speak("Tracking route to $name");
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(destination, 15));
    _polylines.clear();

    await _drawRoute(_currentLocation!, destination);
  }

  /// 🚗 Draw route between two points using Google Directions API
  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> polylineCoordinates = _decodePolyline(points);

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                width: 6,
                points: polylineCoordinates,
              ),
            );
          });

          TtsService.instance.speak("Route is shown on the map.");
        } else {
          TtsService.instance.speak("No route found.");
        }
      } else {
        TtsService.instance.speak("Failed to get directions.");
      }
    } catch (e) {
      TtsService.instance.speak("Error occurred while fetching the route.");
    }
  }

  /// 🧭 Helper: Decode encoded polyline string into coordinates
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final latD = lat / 1E5;
      final lngD = lng / 1E5;
      polyline.add(LatLng(latD, lngD));
    }

    return polyline;
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
                  if (_currentLocation != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) =>
                        _mapController = controller,
                        myLocationEnabled: true,
                        markers: _markers,
                        polylines: _polylines,
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
                              color: Colors.white, fontSize: 18),
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
                        _buildButton(
                          icon: Icons.mic,
                          label: isListening ? "Listening..." : "Voice",
                          color: Colors.green[700]!,
                          onTap: _startVoiceSearch,
                          size: buttonSize,
                        ),
                        _buildButton(
                          icon: Icons.info,
                          label: "Help",
                          color: Colors.orange[700]!,
                          onTap: () => TtsService.instance.speak(
                            "Tap the microphone and say a place like hospital or restaurant to search nearby. Tap a marker to view route.",
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

  Widget _buildButton({
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
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size / 2, color: Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
