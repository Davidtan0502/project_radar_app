import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  String _currentAddress = "Fetching location...";
  LatLng? _initialPosition; // Changed to nullable
  String _weatherDescription = "Fetching weather...";
  String _temperature = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Fallback to default position if service not enabled
      setState(() {
        _initialPosition = const LatLng(14.58639, 121.02979);
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Fallback to default position if permission denied
        setState(() {
          _initialPosition = const LatLng(14.58639, 121.02979);
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _initialPosition = LatLng(position.latitude, position.longitude); // Set initial position to current location
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          _currentAddress =
              "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        }
      });

      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      await _fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to default position if error occurs
      setState(() {
        _initialPosition = const LatLng(14.58639, 121.02979);
      });
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    const apiKey = "1e0dbc808580ffe843728e24a729dcee";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherDescription = data["weather"][0]["description"];
          _temperature = "${data["main"]["temp"].toString()}°C";
        });
      } else {
        debugPrint("Weather API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Weather fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F73A3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  "Project RADAR",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Weather Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Weather Today",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _weatherDescription,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _temperature,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Location Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tell the operator your location",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Latitude", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                              Text(_currentPosition?.latitude.toStringAsFixed(5) ?? "Loading...", style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              const Text("Longitude", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                              Text(_currentPosition?.longitude.toStringAsFixed(5) ?? "Loading...", style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 150,
                            height: 100,
                            child: _initialPosition == null
                                ? const Center(child: CircularProgressIndicator())
                                : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _initialPosition!,
                                      zoom: 14,
                                    ),
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                    },
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    markers: _currentPosition != null
                                        ? {
                                            Marker(
                                              markerId: const MarkerId("currentLocation"),
                                              position: LatLng(
                                                _currentPosition!.latitude,
                                                _currentPosition!.longitude,
                                              ),
                                            ),
                                          }
                                        : {},
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(Icons.account_circle, size: 60, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: _getUserProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: LinearProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data == null) {
                            return const Text(
                              "No user data found.",
                              style: TextStyle(fontSize: 14),
                            );
                          }

                          final data = snapshot.data!;
                          final name = [
                            data['firstName'],
                            data['middleName'],
                            data['lastName']
                          ].where((part) => part != null && part.toString().trim().isNotEmpty).join(' ');

                          final address = data['address'] ?? "No Address Set";
                          final isVerified = data['isVerified'] ?? false;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[900],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Verified",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}