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
import 'package:shared_preferences/shared_preferences.dart';

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
  String _weatherIcon = "";
  bool _isLoadingLocation = true;
  bool _isLoadingWeather = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _startListeningToLocation();
    _startWeatherAutoUpdate();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentAddress = prefs.getString('cached_address') ?? "Offline: Unknown";
      _temperature = prefs.getString('cached_temperature') ?? "N/A";
      _weatherDescription = prefs.getString('cached_weather_desc') ?? "No data";
      _weatherIcon = prefs.getString('cached_weather_icon') ?? "";
    });

    if (_currentPosition != null) {
      _fetchWeather(_currentPosition!.latitude, _currentPosition!.longitude);
    }
  }

  Future<void> _cacheLocationData(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_address', address);
  }

  Future<void> _cacheWeatherData(String desc, String temp, String icon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_weather_desc', desc);
    await prefs.setString('cached_temperature', temp);
    await prefs.setString('cached_weather_icon', icon);
    await prefs.setString('weather_timestamp', DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  void _startListeningToLocation() async {
    await _positionStreamSubscription?.cancel();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _setDefaultLocation();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return _setDefaultLocation();
      }
    }

    setState(() => _isLoadingLocation = true);

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_updatePosition);
  }

  void _startWeatherAutoUpdate() {
    _weatherTimer?.cancel();
    _weatherTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentPosition != null) {
        _fetchWeather(_currentPosition!.latitude, _currentPosition!.longitude);
      }
    });
  }

  Future<void> _updatePosition(Position position) async {
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (!mounted) return;

    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final street = (place?.street?.isNotEmpty ?? false) ? place!.street : (place?.name ?? '');

    final address = place != null
        ? "$street, ${place.locality}, ${place.administrativeArea}, ${place.country}"
        : "Address not available";

    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
      _currentAddress = address;
      _isLoadingLocation = false;
    });

    _cacheLocationData(address);
    if (_mapController != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition!));
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

    final prefs = await SharedPreferences.getInstance();
    final lastFetchStr = prefs.getString("weather_timestamp");
    final now = DateTime.now();

    if (lastFetchStr != null) {
      final lastFetch = DateTime.tryParse(lastFetchStr);
      if (lastFetch != null && now.difference(lastFetch) < const Duration(minutes: 10)) {
        return;
      }
    }

    setState(() => _isLoadingWeather = true);

    try {
      final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=${Config.weatherApiKey}");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final desc = data["weather"][0]["main"] ?? "Unknown";
        final temp = "${data["main"]["temp"]?.toStringAsFixed(1) ?? "N/A"}°C";
        final iconCode = data["weather"][0]["icon"] ?? "";

        setState(() {
          _weatherDescription = desc;
          _temperature = temp;
          _weatherIcon = iconCode;
        });

        await _cacheWeatherData(desc, temp, iconCode);
      } else {
        _handleWeatherError("API error ${response.statusCode}");
      }
    } catch (e) {
      _handleWeatherError(e.toString());
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  void _handleWeatherError(String error) {
    debugPrint("Weather error: $error");
    setState(() {
      _weatherDescription = "Weather unavailable";
      _temperature = "";
      _weatherIcon = "";
    });
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
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
                  Text("Project RADAR", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    IconButton(
                      onPressed: () async {
                        try {
                          final position = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );
                          await _updatePosition(position);
                          _startListeningToLocation();
                          _startWeatherAutoUpdate();
                        } catch (e) {
                          debugPrint("Refresh failed: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to refresh location")),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: "Refresh Location & Weather",
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
          _weatherIcon.isNotEmpty
              ? Image.network(
                  "https://openweathermap.org/img/wn/${_weatherIcon}@2x.png",
                  width: 50,
                  height: 50,
                  errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 50),
                )
              : const Icon(Icons.cloud, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Weather Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _isLoadingWeather
                    ? const LinearProgressIndicator()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_weatherDescription, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          Text(_temperature, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
          const Text("My Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Tell the operator your location", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          Text(_currentAddress, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 150,
              child: _initialPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: _initialPosition!, zoom: 16),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _currentPosition != null
                          ? {
                              Marker(
                                markerId: const MarkerId("currentLoc"),
                                position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              ),
                            }
                          : {},
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text("Latitude: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text(_currentPosition?.latitude.toStringAsFixed(5) ?? "N/A", style: const TextStyle(color: Colors.red)),
              ]),
              Row(children: [
                const Text("Longitude: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text(_currentPosition?.longitude.toStringAsFixed(5) ?? "N/A", style: const TextStyle(color: Colors.blue)),
              ]),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (_currentPosition != null && _mapController != null) {
                  _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)));
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
            child: const Icon(Icons.account_circle, size: 60, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                final data = snapshot.data;
                if (data == null) return const Text("No user data found", style: TextStyle(fontSize: 14));
                final name = [data['firstName'], data['middleName'], data['lastName']]
                    .where((e) => (e ?? '').toString().trim().isNotEmpty)
                    .join(' ');
                final address = data['address'] ?? "No address set";
                final isVerified = data['isVerified'] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(address, style: const TextStyle(fontSize: 14)),
                    if (isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(20)),
                        child: const Text("Verified", style: TextStyle(color: Colors.white, fontSize: 12)),
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
}
