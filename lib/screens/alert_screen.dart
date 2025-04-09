import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Add this dependency
import 'package:intl/intl.dart'; // Add this import

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AlertScreen(),
    );
  }
}

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  late GoogleMapController _mapController;
  late Position _currentPosition;
  late CameraPosition _initialPosition;
  bool _locationReady = false;
  String _currentTime = "";
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setCurrentTime();
  }

  // Fetch current location
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _initialPosition = CameraPosition(
        target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        zoom: 14,
      );
      _locationReady = true;
    });
  }

  // Set current time in 12-hour format with AM/PM
  void _setCurrentTime() {
    setState(() {
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd hh:mm a'); // 12-hour format with AM/PM
      _currentTime = formatter.format(now);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with date/time
            Container(
              color: const Color(0xFF3F73A3), // Color of the alert button
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Map display
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: _locationReady
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _initialPosition,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    )
                  : const Center(child: CircularProgressIndicator()), // Show loading until location is fetched
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    emergencyButton(
                      icon: 'assets/ambulance.png',
                      label: 'Ambulance',
                      onTap: () => debugPrint('Ambulance pressed'),
                    ),
                    emergencyButton(
                      icon: 'assets/firetruck.png',
                      label: 'Fire Dept',
                      onTap: () => debugPrint('Fire Dept pressed'),
                    ),
                    emergencyButton(
                      icon: 'assets/police.png',
                      label: 'Police',
                      onTap: () => debugPrint('Police pressed'),
                    ),
                    emergencyButton(
                      icon: 'assets/sos.png',
                      label: 'SOS',
                      onTap: () => debugPrint('SOS pressed'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emergencyButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, height: 45),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
