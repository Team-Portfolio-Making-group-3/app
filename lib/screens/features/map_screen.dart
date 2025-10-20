import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ added for saving
import '../../widgets/customize_appbar.dart';
import 'main_feature_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool isListening = false;
  String searchQuery = '';
  LatLng? currentLocation;
  Set<Marker> markers = {};
  Polyline? routePolyline;
  List<dynamic> routeSteps = [];
  int nextStepIndex = 0;

  final String googleApiKey = "AIzaSyAFSTLE1gAErYYL7OcfffKhyBj4MJ1uDz0";
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  Timer? _speechTimeout;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
      });
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() => isListening = true);
    _speech.listen(
      onResult: (result) {
        _speechTimeout?.cancel();
        _speechTimeout = Timer(const Duration(seconds: 3), () {
          if (isListening) _stopListeningAndSearch();
        });

        if (result.finalResult) {
          searchQuery = result.recognizedWords;
          _stopListeningAndSearch();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    _speechTimeout = Timer(const Duration(seconds: 3), () {
      if (isListening) _stopListeningAndSearch();
    });
  }

  void _stopListeningAndSearch() {
    _speech.stop();
    setState(() => isListening = false);
    _speechTimeout?.cancel();
    if (searchQuery.isNotEmpty) _searchAndSpeakResults();
  }

  Future<void> _searchAndSpeakResults() async {
    if (currentLocation == null || searchQuery.isEmpty) return;

    final lat = currentLocation!.latitude;
    final lng = currentLocation!.longitude;
    final radius = 1000;

    final url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=$radius&keyword=${Uri.encodeComponent(searchQuery)}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Set<Marker> newMarkers = {};
      List<String> placeNames = [];

      for (var place in data['results']) {
        final LatLng position = LatLng(
            place['geometry']['location']['lat'],
            place['geometry']['location']['lng']);
        final name = place['name'];
        final address = place['vicinity'] ?? "No address available";
        placeNames.add(name);

        newMarkers.add(Marker(
          markerId: MarkerId(name),
          position: position,
          infoWindow: InfoWindow(
            title: name,
            snippet: 'Tap to Track',
            onTap: () => _onLocationSelected(position, name, address),
          ),
        ));
      }

      setState(() => markers = newMarkers);

      for (String name in placeNames) {
        if (!isSpeaking) {
          isSpeaking = true;
          await flutterTts.speak(name);
          await flutterTts.awaitSpeakCompletion(true);
          isSpeaking = false;
        }
      }
    } else {
      print("Places API error: ${response.body}");
    }
  }

  /// ✅ Called when user taps on a location marker
  Future<void> _onLocationSelected(
      LatLng destination, String name, String address) async {
    await _saveLocationToFirebase(name, address, destination);
    await _startRouteTracking(destination, name);
  }

  /// ✅ Saves location info to Firestore
  Future<void> _saveLocationToFirebase(
      String name, String address, LatLng destination) async {
    try {
      await FirebaseFirestore.instance.collection('saved_locations').add({
        'name': name,
        'address': address,
        'latitude': destination.latitude,
        'longitude': destination.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Location saved: $name");
    } catch (e) {
      print("❌ Failed to save location: $e");
    }
  }

  Future<void> _startRouteTracking(LatLng destination, String name) async {
    if (currentLocation == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation!.latitude},${currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final steps = data['routes'][0]['legs'][0]['steps'];
      final polylinePoints =
      _decodePolyline(data['routes'][0]['overview_polyline']['points']);

      setState(() {
        routeSteps = steps;
        routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        );
      });

      _startNavigationVoice();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainFeatureScreen(
            destinationName: name,
            destinationLatLng: destination,
          ),
        ),
      );
    } else {
      print("Directions API error: ${response.body}");
    }
  }

  void _startNavigationVoice() {
    if (routeSteps.isEmpty || currentLocation == null) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position pos) async {
      if (nextStepIndex >= routeSteps.length) return;

      final nextStep = routeSteps[nextStepIndex];
      final endLat = nextStep['end_location']['lat'];
      final endLng = nextStep['end_location']['lng'];
      final distanceToNextStep = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        endLat,
        endLng,
      );

      if (distanceToNextStep < 10) {
        nextStepIndex++;
      } else if (distanceToNextStep <= 30) {
        final instruction =
        nextStep['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
        if (!isSpeaking) {
          isSpeaking = true;
          await flutterTts.speak(instruction);
          await flutterTts.awaitSpeakCompletion(true);
          isSpeaking = false;
        }
      }
    });
  }

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

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: GoogleMap(
        initialCameraPosition:
        CameraPosition(target: currentLocation!, zoom: 16),
        markers: markers,
        myLocationEnabled: true,
        polylines: routePolyline != null ? {routePolyline!} : {},
        onMapCreated: (controller) => _mapController = controller,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startListening,
        backgroundColor: Colors.blue[700],
        child: Icon(isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
