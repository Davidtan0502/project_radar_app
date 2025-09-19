import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_radar_app/widgets/capitalize_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_radar_app/screens/profile/account_information.dart';

// Added imports required by the Recent Incidents module:
import 'package:intl/intl.dart';
import 'package:project_radar_app/screens/alerts/report_tracker_screen.dart';

import 'package:shimmer/shimmer.dart';
import 'package:firebase_storage/firebase_storage.dart'; // << added

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
    await prefs.setString(
      'weather_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  // UPDATED: _getUserProfile now resolves photoURL (storage path -> download URL)
  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) return null;

      // Resolve photo URL if necessary:
      try {
        final rawPhoto = (data['photoURL'] ?? user.photoURL ?? '').toString();
        String finalPhoto = '';

        if (rawPhoto.trim().isEmpty) {
          finalPhoto = '';
        } else {
          final p = rawPhoto.trim();
          // if it's already an http(s) URL, use directly
          if (p.startsWith('http://') || p.startsWith('https://')) {
            finalPhoto = p;
          } else {
            // try to treat as Firebase Storage path/ref
            try {
              final ref = FirebaseStorage.instance.ref().child(p);
              final url = await ref.getDownloadURL();
              finalPhoto = url;
              debugPrint('DEBUG: Resolved storage path "$p" -> $url');
            } catch (e) {
              // fallback: maybe the DB already stored an encoded URL (rare) or the path is wrong
              debugPrint('DEBUG: unable to resolve photo storage path "$p": $e');
              finalPhoto = p; // leave as-is; Image.network will try it (and fail on web if CORS)
            }
          }
        }

        // Create a copy to avoid mutating Firestore map directly
        final Map<String, dynamic> out = Map<String, dynamic>.from(data);
        out['photoURL'] = finalPhoto;
        return out;
      } catch (e) {
        debugPrint('DEBUG: _getUserProfile error resolving photo -> $e');
        return Map<String, dynamic>.from(data);
      }
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
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
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

  // ------------ label detection helpers ------------
  bool _containsLabel(String value, List<String> labels) {
    if (value.trim().isEmpty) return false;
    final escaped = labels.map(RegExp.escape).join('|');
    final pattern = RegExp(r'\b(' + escaped + r')\b', caseSensitive: false);
    return pattern.hasMatch(value);
  }

  bool _hasStreetLabel(String value) {
    return _containsLabel(value, [
      'street',
      'st',
      'st\\.',
      'str',
      'str\\.',
      'road',
      'rd',
      'rd\\.',
      'avenue',
      'ave',
      'ave\\.',
      'av',
      'av\\.',
      'boulevard',
      'blvd',
      'blvd\\.',
      'lane',
      'ln',
      'ln\\.',
      'drive',
      'dr',
      'dr\\.',
      'place',
      'pl',
      'pl\\.',
      'way',
      'highway',
      'hwy',
      'hwy\\.',
      'court',
      'ct',
      'ct\\.',
      'circle',
      'cir',
      'cir\\.',
      'terrace',
      'ter',
      'ter\\.'
    ]);
  }

  bool _hasBarangayLabel(String value) {
    return _containsLabel(value, [
      'barangay',
      'brgy',
      'brgy\\.',
      'brg',
      'brg\\.',
      'bgy',
      'bgy\\.',
      'pob',
      'poblacion'
    ]);
  }

  bool _hasCityLabel(String value) {
    return _containsLabel(value, [
      'city',
      'city\\.',
      'municipality',
      'mun',
      'mun\\.',
      'municipal',
      'town',
      'town\\.'
    ]);
  }
  // ------------ end helpers ------------

  Future<void> _updatePosition(Position position) async {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (!mounted) return;

    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final rawStreet =
        (place?.street?.isNotEmpty ?? false) ? place!.street : (place?.name ?? '');

    final trimmed = ((place?.street ?? place?.name) ?? '').trim();
    final streetDisplay = trimmed.isNotEmpty ? (_hasStreetLabel(trimmed) ? trimmed : '$trimmed Street') : '';

    final locality = place?.locality ?? '';
    final adminArea = place?.administrativeArea ?? '';
    final country = place?.country ?? '';

    final address = place != null
        ? "${streetDisplay.isNotEmpty ? '$streetDisplay, ' : ''}${locality.isNotEmpty ? '$locality, ' : ''}${adminArea.isNotEmpty ? '$adminArea, ' : ''}$country"
        : "Address not available";

    setState(() {
      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
      _currentAddress = address;
      _isLoadingLocation = false;
    });

    _cacheLocationData(address);
    _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition!));

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
      if (lastFetch != null &&
          now.difference(lastFetch) < const Duration(minutes: 10)) {
        return;
      }
    }

    setState(() => _isLoadingWeather = true);

    try {
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=${Config.weatherApiKey}",
      );
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

  // Helper: compose a short address summary from an address map (used on Home card)
  String _composeShortAddress(Map<String, dynamic>? m, {String fallback = ''}) {
    if (m == null || m.isEmpty) return fallback;
    final schoolName = (m['schoolName'] ?? '').toString().trim();
    final house = (m['house'] ?? '').toString().trim();
    final street = (m['street'] ?? '').toString().trim();
    final barangay = (m['barangay'] ?? '').toString().trim();
    final town = (m['town'] ?? '').toString().trim();
    final city = (m['city'] ?? '').toString().trim();
    final zip = (m['zip'] ?? '').toString().trim();
    final country = (m['country'] ?? '').toString().trim(); // <-- added

    final parts = <String>[];

    // Prefer showing schoolName (if available) first for school maps
    if (schoolName.isNotEmpty) parts.add(schoolName);

    if (house.isNotEmpty) parts.add(house);

    // Street: append "Street" if the provided value does not already contain a street-like label
    if (street.isNotEmpty) {
      final streetPart = _hasStreetLabel(street) ? street : '$street Street';
      parts.add(streetPart);
    }

    // Barangay: prefix only if not already present
    if (barangay.isNotEmpty) {
      final barangayPart = _hasBarangayLabel(barangay) ? barangay : 'Barangay $barangay';
      parts.add(barangayPart);
    }

    if (town.isNotEmpty) parts.add(town);

    // Only add city if it's present and not equal to town (reduces duplication)
    if (city.isNotEmpty && city != town) {
      // keep city as-is (we don't auto-append "City" in the short form)
      parts.add(city);
    }

    if (zip.isNotEmpty) parts.add(zip);

    // add country (always last if present)
    if (country.isNotEmpty) parts.add(country);

    final composed = parts.where((p) => p.trim().isNotEmpty).join(', ');

    return composed.isNotEmpty ? composed : fallback;
  }

  // Helper: check whether required fields are present for the given category
  bool _isProfileCompleteForCategory(Map<String, dynamic> data) {
    final category = (data['userCategory'] ?? '').toString().toUpperCase();

    bool hasNonEmpty(Map<String, dynamic>? m, List<String> keys) {
      if (m == null) return false;
      for (final k in keys) {
        final v = (m[k] ?? '').toString().trim();
        if (v.isEmpty) return false;
      }
      return true;
    }

    // new helper: returns true if map has either a non-empty 'town' OR any city-like key
    bool hasTownOrCity(Map<String, dynamic>? m) {
      if (m == null) return false;
      final town = (m['town'] ?? '').toString().trim();
      if (town.isNotEmpty) return true;

      // check for several city-like keys
      final cityKeys = [
        'city',
        'municipality',
        'cityMunicipality',
        'city_municipality',
        'homeCity',
        'workCity',
        'schoolCity'
      ];
      for (final k in cityKeys) {
        final v = (m[k] ?? '').toString().trim();
        if (v.isNotEmpty) return true;
      }
      return false;
    }

    if (category == 'RESIDENT') {
      final resident = data['residentAddress'] is Map ? Map<String, dynamic>.from(data['residentAddress']) : null;
      // require house, street, barangay, zip AND (town OR city/municipality)
      return hasNonEmpty(resident, ['house', 'street', 'barangay', 'zip']) && hasTownOrCity(resident);
    } else if (category == 'EMPLOYEE') {
      final work = data['workAddress'] is Map ? Map<String, dynamic>.from(data['workAddress']) : null;
      final home = data['homeAddress'] is Map ? Map<String, dynamic>.from(data['homeAddress']) : null;
      // require work address complete (street, barangay, zip + town/city) and home complete (house,street,barangay,zip + town/city)
      return hasNonEmpty(work, ['street', 'barangay', 'zip']) && hasTownOrCity(work) &&
             hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && hasTownOrCity(home);
    } else if (category == 'STUDENT') {
      final school = data['schoolAddress'] is Map ? Map<String, dynamic>.from(data['schoolAddress']) : null;
      final home = data['homeAddress'] is Map ? Map<String, dynamic>.from(data['homeAddress']) : null;
      // require school (schoolName,street,barangay,zip + town/city) AND home (house,street,barangay,zip + town/city)
      return hasNonEmpty(school, ['schoolName', 'street', 'barangay', 'zip']) && hasTownOrCity(school) &&
             hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && hasTownOrCity(home);
    } else {
      // unknown category: require at least one of legacy address or any address map
      final fallback = (data['address'] ?? '').toString().trim();
      final anyMapPresent = (data['residentAddress'] is Map && (data['residentAddress'] as Map).isNotEmpty) ||
                           (data['workAddress'] is Map && (data['workAddress'] as Map).isNotEmpty) ||
                           (data['schoolAddress'] is Map && (data['schoolAddress'] as Map).isNotEmpty) ||
                           (data['homeAddress'] is Map && (data['homeAddress'] as Map).isNotEmpty);
      return fallback.isNotEmpty || anyMapPresent;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "RADAR",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
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
                          const SnackBar(
                            content: Text("Failed to refresh location"),
                          ),
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

              // <-- Inserted Recent Incidents here (merged from the first file)
              _buildRecentIncidents(),
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
                "https://openweathermap.org/img/wn/$_weatherIcon@2x.png",
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
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _temperature,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
          const Text(
            "My Location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tell the operator your location",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
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
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition!,
                        zoom: 16,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Latitude: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    _currentPosition?.latitude.toStringAsFixed(5) ?? "N/A",
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    "Longitude: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    _currentPosition?.longitude.toStringAsFixed(5) ?? "N/A",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.animateCamera(CameraUpdate.newLatLng(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                  ));
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

  // ---------- RECENT INCIDENTS (merged) ----------
  Widget _buildRecentIncidents() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Incidents",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ReportTrackerScreen(initialTab: 0),
                    ),
                  );
                },
                child: const Text(
                  "See all",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 185,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // filter out declined locally
                final docs = (snapshot.data?.docs ?? [])
                    .where((doc) =>
                        (doc['status'] ?? '').toString().toLowerCase() !=
                        'declined')
                    .toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recent incidents found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final incidentType = data['incidentType'] ?? 'Unknown type';
                    final address = data['address'] ?? 'Unknown address';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final time = timestamp != null
                        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                        : 'Unknown time';

                    IconData icon;
                    Color color;

                    switch (incidentType.toString().toLowerCase()) {
                      case 'fire':
                        icon = Icons.local_fire_department;
                        color = Colors.redAccent;
                        break;
                      case 'flood':
                        icon = Icons.water_drop;
                        color = Colors.blueAccent;
                        break;
                      case 'accident':
                        icon = Icons.car_crash;
                        color = Colors.orangeAccent;
                        break;
                      default:
                        icon = Icons.report;
                        color = Colors.green;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incidentType.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UPDATED profile card ----------
  // Keep the updated profile card from the second file (aligns avatar with name)
  Widget _buildProfileCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20), // match your card radius
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountInformationScreen()),
        );
      },
      child: _cardContainer(
        child: Row(
          // <--- changed: align top so avatar aligns with the name text
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar: replaced static icon with FutureBuilder that uses _getUserProfile()
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _getUserProfile(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final pdata = snap.data;
                  if (pdata == null) {
                    return const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.grey,
                    );
                  }
                  final photo = (pdata['photoURL'] ?? '').toString().trim();
                  if (photo.isEmpty) {
                    return const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.grey,
                    );
                  }

                  // Use Image.network with errorBuilder to fall back cleanly
                  return ClipOval(
                    child: Image.network(
                      photo,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        debugPrint('DEBUG: failed to load profile image -> $photo');
                        return const Icon(
                          Icons.account_circle,
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    ),
                  );
                },
              ),
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
                    return const Text(
                      "No user data found",
                      style: TextStyle(fontSize: 14),
                    );
                  }

                  final name = [data['firstName'], data['lastName']]
                      .where((e) => (e ?? '').toString().trim().isNotEmpty)
                      .map((e) => capitalizeName(e.toString()))
                      .join(' ');

                  // determine category (short token expected: RESIDENT/EMPLOYEE/STUDENT)
                  final category = (data['userCategory'] ?? '').toString().toUpperCase();

                  // pick address according to category (prefer maps)
                  String displayedAddress = '';
                  final fallback = (data['address'] ?? "No address set").toString();

                  if (category == 'RESIDENT') {
                    final resident = data['residentAddress'] is Map ? Map<String, dynamic>.from(data['residentAddress']) : null;
                    displayedAddress = _composeShortAddress(resident, fallback: fallback);
                  } else if (category == 'STUDENT') {
                    final school = data['schoolAddress'] is Map ? Map<String, dynamic>.from(data['schoolAddress']) : null;
                    displayedAddress = _composeShortAddress(school, fallback: fallback);
                  } else if (category == 'EMPLOYEE') {
                    final work = data['workAddress'] is Map ? Map<String, dynamic>.from(data['workAddress']) : null;
                    displayedAddress = _composeShortAddress(work, fallback: fallback);
                  } else {
                    displayedAddress = fallback;
                  }

                  // verification status stored in DB (e.g. email verified)
                  final storedVerifiedRaw = data['isVerified'];
                  // tolerant conversion: accept bool true, numeric 1, '1', 'true', 'yes' (case-insensitive)
                  final bool storedVerified = storedVerifiedRaw == true ||
                      storedVerifiedRaw == 1 ||
                      storedVerifiedRaw == '1' ||
                      (storedVerifiedRaw is String && storedVerifiedRaw.toLowerCase().trim() == 'true') ||
                      (storedVerifiedRaw is String && storedVerifiedRaw.toLowerCase().trim() == 'yes');

                  // check completeness depending on category
                  final isComplete = _isProfileCompleteForCategory(data);

                  // show verified only when storedVerified AND isComplete
                  final shouldShowVerified = storedVerified == true && isComplete;

                  // prepare address label
                  final addressLabel = category == 'RESIDENT'
                      ? 'Address:'
                      : category == 'STUDENT'
                          ? 'School Address:'
                          : category == 'EMPLOYEE'
                              ? 'Work Address:'
                              : 'Address:';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row: name + verified next to the name, then category pill on the right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // name + verified kept together so they are adjacent
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (shouldShowVerified) ...[
                                  const SizedBox(width: 2),
                                  // check icon immediately after the name
                                  const Icon(Icons.verified, size: 17, color: Colors.blueAccent),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // category pill (inline with the name, stays to the right)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 228, 228, 228),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.isNotEmpty ? category : 'UNSET',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Address label on its own line, address below (wraps)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addressLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            displayedAddress.isNotEmpty ? displayedAddress : '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
