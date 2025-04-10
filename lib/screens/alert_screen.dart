import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'incident_report_screen.dart';

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

  void _setCurrentTime() {
    setState(() {
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd hh:mm a');
      _currentTime = formatter.format(now);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch phone dialer';
    }
  }

  void _navigateToIncidentReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncidentReportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF3F73A3),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Map
            SizedBox(
              height: screenHeight * 0.25,
              child: _locationReady
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _initialPosition,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Button Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.01,
                  vertical: 1,
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: screenWidth * 0.01,
                        mainAxisSpacing: screenWidth * 0.01,
                        childAspectRatio: 1.0,
                        padding: EdgeInsets.zero,
                        children: [
                          _buildGridButton(
                            icon: 'assets/ambulance.png',
                            label: 'Ambulance',
                            onTap: () => _launchPhone('09123456789'),
                            iconSize: 40,  // Adjust this value
                            fontSize: 14,   // Adjust this value
                          ),
                          _buildGridButton(
                            icon: 'assets/firetruck.png',
                            label: 'Fire Truck',
                            onTap: () => _launchPhone('09123456789'),
                            iconSize: 40,
                            fontSize: 14,
                          ),
                          _buildGridButton(
                            icon: 'assets/police.png',
                            label: 'Police',
                            onTap: () => _launchPhone('09123456789'),
                            iconSize: 40,
                            fontSize: 14,
                          ),
                          _buildGridButton(
                            icon: 'assets/sos.png',
                            label: 'SOS',
                            onTap: () => _launchPhone('09777788472'),
                            iconSize: 40,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                        child: _buildFullWidthButton(
                          icon: 'assets/report.png',
                          label: 'Incident Report',
                          onTap: () => _navigateToIncidentReport(context),
                          iconSize: 28,  // Adjust this value
                          fontSize: 14,  // Adjust this value
                        ),
                      ),
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

  Widget _buildGridButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: iconSize, // Controlled by parameter
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize, // Controlled by parameter
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: iconSize, // Controlled by parameter
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize, // Controlled by parameter
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}