import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_radar_app/widgets/capitalize_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/account_information.dart';

// Added imports required by the Recent Incidents module:
import 'package:intl/intl.dart';
import 'package:project_radar_app/screens/alerts/report_tracker_screen.dart';

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

  final SupabaseClient supabase = Supabase.instance.client;

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

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await supabase
          .from('app_users')
          .select(
              'id, first_name, last_name, email, phone, user_category, address, resident_address, school_address, work_address, home_address, dob, is_verified, photo_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      final rawPhoto = (response['photo_url'] ?? '').toString().trim();
      String finalPhoto = '';

      if (rawPhoto.isEmpty) {
        finalPhoto = '';
      } else if (rawPhoto.startsWith('http://') ||
          rawPhoto.startsWith('https://')) {
        finalPhoto = rawPhoto;
      } else {
        finalPhoto = supabase.storage.from('profiles').getPublicUrl(rawPhoto);
      }

      if (finalPhoto.startsWith('http')) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        finalPhoto = finalPhoto.contains('?')
            ? '$finalPhoto&v=$ts'
            : '$finalPhoto?v=$ts';
      }

      final Map<String, dynamic> out = Map<String, dynamic>.from(response);
      out['photoURL'] = finalPhoto;
      return out;
    } catch (e) {
      debugPrint('DEBUG: _getUserProfile error -> $e');
      return null;
    }
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

  bool _containsLabel(String value, List<String> labels) {
    if (value.trim().isEmpty) return false;
    final escaped = labels.map(RegExp.escape).join('|');
    final pattern = RegExp(r'\b(' + escaped + r')\b', caseSensitive: false);
    return pattern.hasMatch(value);
  }

  bool _hasStreetLabel(String value) {
    return _containsLabel(value, [
      'street', 'st', 'st\\.', 'str', 'str\\.', 'road', 'rd', 'rd\\.', 'avenue', 
      'ave', 'ave\\.', 'av', 'av\\.', 'boulevard', 'blvd', 'blvd\\.', 'lane', 
      'ln', 'ln\\.', 'drive', 'dr', 'dr\\.', 'place', 'pl', 'pl\\.', 'way', 
      'highway', 'hwy', 'hwy\\.', 'court', 'ct', 'ct\\.', 'circle', 'cir', 'cir\\.', 
      'terrace', 'ter', 'ter\\.'
    ]);
  }

  bool _hasBarangayLabel(String value) {
    return _containsLabel(value, [
      'barangay', 'brgy', 'brgy\\.', 'brg', 'brg\\.', 'bgy', 'bgy\\.', 'pob', 'poblacion'
    ]);
  }

  bool _hasCityLabel(String value) {
    return _containsLabel(value, [
      'city', 'city\\.', 'municipality', 'mun', 'mun\\.', 'municipal', 'town', 'town\\.'
    ]);
  }

  Future<void> _updatePosition(Position position) async {
    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (!mounted) return;

    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final trimmed = ((place?.street ?? place?.name) ?? '').trim();
    final streetDisplay =
        trimmed.isNotEmpty ? (_hasStreetLabel(trimmed) ? trimmed : '$trimmed Street') : '';

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

  Widget _cardContainer({required Widget child, Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _composeShortAddress(Map<String, dynamic>? m, {String fallback = ''}) {
    if (m == null || m.isEmpty) return fallback;
    final schoolName = (m['school_name'] ?? '').toString().trim();
    final house = (m['house'] ?? '').toString().trim();
    final street = (m['street'] ?? '').toString().trim();
    final barangay = (m['barangay'] ?? '').toString().trim();
    final town = (m['town'] ?? '').toString().trim();
    final city = (m['city'] ?? '').toString().trim();
    final zip = (m['zip'] ?? '').toString().trim();
    final country = (m['country'] ?? '').toString().trim();

    final parts = <String>[];

    if (schoolName.isNotEmpty) parts.add(schoolName);
    if (house.isNotEmpty) parts.add(house);

    if (street.isNotEmpty) {
      final streetPart = _hasStreetLabel(street) ? street : '$street Street';
      parts.add(streetPart);
    }

    if (barangay.isNotEmpty) {
      final barangayPart = _hasBarangayLabel(barangay) ? barangay : 'Barangay $barangay';
      parts.add(barangayPart);
    }

    if (town.isNotEmpty) parts.add(town);
    if (city.isNotEmpty && city != town) parts.add(city);
    if (zip.isNotEmpty) parts.add(zip);
    if (country.isNotEmpty) parts.add(country);

    final composed = parts.where((p) => p.trim().isNotEmpty).join(', ');
    return composed.isNotEmpty ? composed : fallback;
  }

  bool _isProfileCompleteForCategory(Map<String, dynamic> data) {
    final category = (data['user_category'] ?? '').toString().toUpperCase();
    final dob = (data['dob'] ?? '').toString().trim();
    if (dob.isEmpty) return false;

    bool hasNonEmpty(Map<String, dynamic>? m, List<String> keys) {
      if (m == null) return false;
      for (final k in keys) {
        final v = (m[k] ?? '').toString().trim();
        if (v.isEmpty) return false;
      }
      return true;
    }

    bool hasTownOrCity(Map<String, dynamic>? m) {
      if (m == null) return false;
      final town = (m['town'] ?? '').toString().trim();
      if (town.isNotEmpty) return true;

      final cityKeys = ['city', 'municipality', 'cityMunicipality', 'city_municipality'];
      for (final k in cityKeys) {
        final v = (m[k] ?? '').toString().trim();
        if (v.isNotEmpty) return true;
      }
      return false;
    }

    if (category == 'RESIDENT') {
      final resident = data['resident_address'] is Map ? Map<String, dynamic>.from(data['resident_address']) : null;
      return hasNonEmpty(resident, ['house', 'street', 'barangay', 'zip']) && hasTownOrCity(resident);
    } else if (category == 'EMPLOYEE') {
      final work = data['work_address'] is Map ? Map<String, dynamic>.from(data['work_address']) : null;
      final home = data['home_address'] is Map ? Map<String, dynamic>.from(data['home_address']) : null;
      return hasNonEmpty(work, ['street', 'barangay', 'zip']) && hasTownOrCity(work) &&
             hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && hasTownOrCity(home);
    } else if (category == 'STUDENT') {
      final school = data['school_address'] is Map ? Map<String, dynamic>.from(data['school_address']) : null;
      final home = data['home_address'] is Map ? Map<String, dynamic>.from(data['home_address']) : null;
      return hasNonEmpty(school, ['schoolName', 'street', 'barangay', 'zip']) && hasTownOrCity(school) &&
             hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && hasTownOrCity(home);
    } else {
      final fallback = (data['address'] ?? '').toString().trim();
      final anyMapPresent = (data['resident_address'] is Map && (data['resident_address'] as Map).isNotEmpty) ||
                           (data['work_address'] is Map && (data['work_address'] as Map).isNotEmpty) ||
                           (data['school_address'] is Map && (data['school_address'] as Map).isNotEmpty) ||
                           (data['home_address'] is Map && (data['home_address'] as Map).isNotEmpty);
      return fallback.isNotEmpty || anyMapPresent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF3F73A3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: isSmallScreen ? 12 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Compact
              _buildHeader(isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              // Weather Card - Compact
              _buildWeatherCard(isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              // Location Card - Responsive height
              _buildLocationCard(screenHeight, isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Recent Incidents - Compact
              _buildRecentIncidents(isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Profile Card - Compact
              _buildProfileCard(isSmallScreen),
              SizedBox(height: isSmallScreen ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "RADAR",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                "Emergency Response System",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                try {
                  final position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );
                  await _updatePosition(position);
                  _startListeningToLocation();
                  _startWeatherAutoUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Location refreshed"),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Failed to refresh location"),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.refresh, 
                color: Colors.white, 
                size: isSmallScreen ? 20 : 22
              ),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              constraints: const BoxConstraints(),
              tooltip: "Refresh Location & Weather",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(bool isSmallScreen) {
    return _cardContainer(
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 48 : 52,
            height: isSmallScreen ? 48 : 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _weatherIcon.isNotEmpty
                ? Image.network(
                    "https://openweathermap.org/img/wn/$_weatherIcon@2x.png",
                    width: isSmallScreen ? 40 : 44,
                    height: isSmallScreen ? 40 : 44,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.cloud,
                      size: isSmallScreen ? 28 : 30,
                      color: Colors.blue[600],
                    ),
                  )
                : Icon(
                    Icons.cloud,
                    size: isSmallScreen ? 28 : 30,
                    color: Colors.blue[600],
                  ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weather Today",
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                _isLoadingWeather
                    ? SizedBox(
                        height: isSmallScreen ? 16 : 18,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue[600]!,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherDescription,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 1 : 2),
                          Text(
                            _temperature,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 16 : 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue[800],
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

  Widget _buildLocationCard(double screenHeight, bool isSmallScreen) {
    final mapHeight = screenHeight * 0.20; // Responsive height based on screen

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red[600],
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Text(
                "My Location",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 16 : 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            "Tell the operator your location",
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.place, color: Colors.red[400], size: isSmallScreen ? 14 : 16),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    _currentAddress,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: mapHeight,
              child: _initialPosition == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              "Loading map...",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
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
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed,
                                ),
                              ),
                            }
                          : {},
                    ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCoordinateItem(
                  "Latitude",
                  _currentPosition?.latitude.toStringAsFixed(5) ?? "N/A",
                  Colors.red,
                  isSmallScreen,
                ),
                _buildCoordinateItem(
                  "Longitude",
                  _currentPosition?.longitude.toStringAsFixed(5) ?? "N/A",
                  Colors.blue,
                  isSmallScreen,
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton.icon(
                onPressed: () {
                  if (_currentPosition != null && _mapController != null) {
                    _mapController.animateCamera(CameraUpdate.newLatLng(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                    ));
                  }
                },
                icon: Icon(
                  Icons.my_location, 
                  size: isSmallScreen ? 16 : 18, 
                  color: Colors.blue[800]
                ),
                label: Text(
                  "Center Map",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16, 
                    vertical: isSmallScreen ? 6 : 8
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value, Color color, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentIncidents(bool isSmallScreen) {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: Colors.orange[600],
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Text(
                    "Recent Incidents",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportTrackerScreen(initialTab: 0),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                  ),
                  child: Text(
                    "See all",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          SizedBox(
            height: isSmallScreen ? 160 : 170,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('incidents')
                  .stream(primaryKey: ['id'])
                  .order('timestamp', ascending: false)
                  .limit(8), // Reduced limit for smaller screens
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(isSmallScreen);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(isSmallScreen);
                }

                final incidents = snapshot.data ?? [];
                final filteredIncidents = incidents
                    .where((incident) =>
                        (incident['status'] ?? '').toString().toLowerCase() != 'declined')
                    .toList();

                if (filteredIncidents.isEmpty) {
                  return _buildEmptyState(isSmallScreen);
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredIncidents.length,
                  separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 8 : 10),
                  itemBuilder: (context, index) {
                    final data = filteredIncidents[index];
                    final incidentType = data['incident_type'] ?? 'Unknown type';
                    final address = data['address'] ?? 'Unknown address';
                    final timestamp = data['timestamp'];
                    final time = timestamp != null
                        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(timestamp))
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
                        icon = Icons.warning;
                        color = Colors.green;
                    }

                    return Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 38 : 40,
                            height: isSmallScreen ? 38 : 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon, 
                              color: color, 
                              size: isSmallScreen ? 18 : 20
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incidentType.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 14 : 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  address,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: isSmallScreen ? 12 : 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w500,
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

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: isSmallScreen ? 36 : 40),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Error loading incidents',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isSmallScreen ? 12 : 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 38 : 40,
              height: isSmallScreen ? 38 : 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: isSmallScreen ? 14 : 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Container(
                    width: double.infinity,
                    height: isSmallScreen ? 12 : 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Container(
                    width: 70,
                    height: isSmallScreen ? 10 : 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.grey[400], size: isSmallScreen ? 36 : 40),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'No recent incidents',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isSmallScreen ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            'All clear in your area',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isSmallScreen ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isSmallScreen) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountInformationScreen()),
        );
      },
      child: _cardContainer(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildProfileShimmer(isSmallScreen);
            }

            final data = snapshot.data;
            if (data == null) {
              return _buildNoUserData(isSmallScreen);
            }

            final photo = (data['photoURL'] ?? '').toString().trim();
            final name = [data['first_name'], data['last_name']]
                .where((e) => (e ?? '').toString().trim().isNotEmpty)
                .map((e) => capitalizeName(e.toString()))
                .join(' ');

            final category = (data['user_category'] ?? '').toString().toUpperCase();
            final fallback = (data['address'] ?? "No address set").toString();

            String displayedAddress = fallback;
            if (category == 'RESIDENT') {
              final addr = data['resident_address'] is Map ? Map<String, dynamic>.from(data['resident_address']) : null;
              displayedAddress = _composeShortAddress(addr, fallback: fallback);
            } else if (category == 'STUDENT') {
              final addr = data['school_address'] is Map ? Map<String, dynamic>.from(data['school_address']) : null;
              displayedAddress = _composeShortAddress(addr, fallback: fallback);
            } else if (category == 'EMPLOYEE') {
              final addr = data['work_address'] is Map ? Map<String, dynamic>.from(data['work_address']) : null;
              displayedAddress = _composeShortAddress(addr, fallback: fallback);
            }

            final storedVerifiedRaw = data['is_verified'];
            final bool storedVerified = storedVerifiedRaw == true ||
                storedVerifiedRaw == 1 ||
                storedVerifiedRaw == '1' ||
                (storedVerifiedRaw is String && ['true', 'yes'].contains(storedVerifiedRaw.toLowerCase().trim()));

            final shouldShowVerified = storedVerified || (data['dob']?.toString().trim().isNotEmpty ?? false);

            final addressLabel = category == 'RESIDENT'
                ? 'Address:'
                : category == 'STUDENT'
                    ? 'School Address:'
                    : category == 'EMPLOYEE'
                        ? 'Work Address:'
                        : 'Address:';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + category
                Column(
                  children: [
                    Container(
                      width: isSmallScreen ? 56 : 60,
                      height: isSmallScreen ? 56 : 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: photo.isEmpty
                            ? Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.account_circle,
                                  size: isSmallScreen ? 56 : 60,
                                  color: Colors.grey[400],
                                ),
                              )
                            : Image.network(
                                photo,
                                width: isSmallScreen ? 56 : 60,
                                height: isSmallScreen ? 56 : 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.account_circle,
                                      size: isSmallScreen ? 56 : 60,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[500]!, Colors.blue[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.isNotEmpty ? category : 'UNSET',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              name.isNotEmpty ? name : 'Unknown User',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 16 : 17,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (shouldShowVerified) ...[
                            SizedBox(width: isSmallScreen ? 4 : 6),
                            Icon(
                              Icons.verified,
                              size: isSmallScreen ? 16 : 18,
                              color: Colors.blueAccent[400],
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: isSmallScreen ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: isSmallScreen ? 4 : 6),
                                Text(
                                  addressLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                    fontSize: isSmallScreen ? 12 : 13,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              displayedAddress.isNotEmpty ? displayedAddress : 'No address provided',
                              style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileShimmer(bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: isSmallScreen ? 56 : 60,
              height: isSmallScreen ? 56 : 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Container(
              width: 50,
              height: isSmallScreen ? 16 : 18,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: isSmallScreen ? 18 : 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              Container(
                width: double.infinity,
                height: isSmallScreen ? 50 : 55,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoUserData(bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 56 : 60,
          height: isSmallScreen ? 56 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: Icon(
            Icons.account_circle,
            size: isSmallScreen ? 56 : 60,
            color: Colors.grey[400],
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "No user data found",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                "Please check your connection",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}