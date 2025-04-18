import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Config (replace this in production)
class Config {
  static const weatherApiKey = "1e0dbc808580ffe843728e24a729dcee";
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  LatLng? _initialPosition;
  String _currentAddress = "Fetching location...";
  String _weatherDescription = "Fetching weather...";
  String _temperature = "";
  String _weatherIconCode = "";
  bool _isLoadingLocation = true;
  bool _isLoadingWeather = false;
  DateTime? _lastWeatherFetch;
  Map<String, dynamic>? _cachedWeatherData;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningToLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return doc.data();
      } catch (e) {
        debugPrint("Error fetching user profile: $e");
      }
    }
    return null;
  }

void _startListeningToLocation() async {
  // Cancel the previous stream
  await _positionStreamSubscription?.cancel();

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return _setDefaultLocation();

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return _setDefaultLocation();
    }
  }

  setState(() {
    _isLoadingLocation = true;
  });

  _positionStreamSubscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // meters before updating
    ),
  ).listen((Position position) {
    _updatePosition(position);
  });
}


  Future<void> _updatePosition(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = (place.street?.isNotEmpty ?? false)
            ? place.street
            : place.name ?? '';
        _currentAddress =
            "$street, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      } else {
        _currentAddress = "Address not available";
      }
    });

    if (_mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_initialPosition!),
      );
    }

    await _fetchWeather(position.latitude, position.longitude);
  }

  void _setDefaultLocation() {
    setState(() {
      _initialPosition = const LatLng(14.58639, 121.02979);
      _currentAddress = "Location services disabled";
      _isLoadingLocation = false;
    });
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    if (_isLoadingWeather) return;

    if (_lastWeatherFetch != null &&
        DateTime.now().difference(_lastWeatherFetch!) <
            const Duration(minutes: 10) &&
        _cachedWeatherData != null) {
      return _processWeatherData(_cachedWeatherData!);
    }

    setState(() => _isLoadingWeather = true);

    try {
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather"
        "?lat=$lat&lon=$lon&units=metric&appid=${Config.weatherApiKey}",
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedWeatherData = data;
        _lastWeatherFetch = DateTime.now();
        _processWeatherData(data);
      } else {
        _handleWeatherError("API Error: ${response.statusCode}");
      }
    } on SocketException {
      _handleWeatherError("No internet connection");
    } on TimeoutException {
      _handleWeatherError("Request timed out");
    } catch (e) {
      _handleWeatherError("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  void _processWeatherData(Map<String, dynamic> data) {
    setState(() {
      _weatherDescription = data["weather"][0]["description"] ?? "N/A";
      _temperature = "${data["main"]["temp"]?.toStringAsFixed(1) ?? 'N/A'}°C";
      _weatherIconCode = data["weather"][0]["icon"] ?? "";
    });
  }

  void _handleWeatherError(String error) {
    debugPrint("Weather fetch error: $error");
    setState(() {
      _weatherDescription = "Weather unavailable";
      _temperature = "";
      _weatherIconCode = "";
    });
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Project RADAR",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    onPressed: _startListeningToLocation,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: "Restart Location Stream",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildWeatherCard(),
              const SizedBox(height: 20),
              _buildLocationCard(),
              const SizedBox(height: 20),
              _buildProfileCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return _cardContainer(
      child: Row(
        children: [
          _weatherIconCode.isNotEmpty
              ? Image.network(
                  "https://openweathermap.org/img/wn/${_weatherIconCode}@2x.png",
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.wb_sunny, color: Colors.orange),
                )
              : const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Weather Today",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _isLoadingWeather
                    ? const LinearProgressIndicator()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherDescription,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            _temperature,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          if (_weatherDescription.contains("unavailable"))
                            TextButton(
                              onPressed: () {
                                if (_currentPosition != null) {
                                  _fetchWeather(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  );
                                }
                              },
                              child: const Text("Retry"),
                            ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildLocationCard() {
  return _cardContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("My Location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Tell the operator your location",
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 16),
        Text(_currentAddress, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),

        // MAP PREVIEW
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 150,
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
                              markerId: const MarkerId("currentLoc"),
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

        const SizedBox(height: 12),

        // LAT & LONG ROW
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text("Latitude: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                Text(
                  _currentPosition?.latitude.toStringAsFixed(5) ?? "N/A",
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Longitude: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
                Text(
                  _currentPosition?.longitude.toStringAsFixed(5) ?? "N/A",
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 6),

        // CENTER MAP BUTTON
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              if (_currentPosition != null && _mapController != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text("Center Map"),
            style: TextButton.styleFrom(foregroundColor: Colors.blue[800]),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildProfileCard() {
    return _cardContainer(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.account_circle,
                size: 60, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                final data = snapshot.data;
                if (data == null) {
                  return const Text("No user data found",
                      style: TextStyle(fontSize: 14));
                }

                final name = [
                  data['firstName'],
                  data['middleName'],
                  data['lastName']
                ].where((e) => (e ?? '').toString().trim().isNotEmpty).join(' ');

                final address = data['address'] ?? "No address set";
                final isVerified = data['isVerified'] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(address, style: const TextStyle(fontSize: 14)),
                    if (isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Verified",
                          style:
                              TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
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
      child: child,
    );
  }
}
