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

    // Define dynamic sizes for better UX
    final headerHeight = screenHeight * 0.07;
    final mapHeight = screenHeight * 0.30;
    final sectionSpacing = screenHeight * 0.02;
    final sidePadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              height: headerHeight,
              color: const Color(0xFF3F73A3),
              padding: EdgeInsets.symmetric(
                vertical: headerHeight * 0.2,
                horizontal: sidePadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Map
            SizedBox(
              height: mapHeight,
              child: _locationReady
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _initialPosition,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            SizedBox(height: sectionSpacing),

            // Three-button row: Ambulance, Fire Truck, Police
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridButton(
                      icon: 'assets/ambulance.png',
                      label: 'Ambulance',
                      onTap: () => _launchPhone('09123456789'),
                      iconSize: 45,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: sidePadding),
                  Expanded(
                    child: _buildGridButton(
                      icon: 'assets/firetruck.png',
                      label: 'Fire Truck',
                      onTap: () => _launchPhone('09123456789'),
                      iconSize: 45,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: sidePadding),
                  Expanded(
                    child: _buildGridButton(
                      icon: 'assets/police.png',
                      label: 'Police',
                      onTap: () => _launchPhone('09123456789'),
                      iconSize: 45,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // SOS full-width button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: _buildFullWidthButton(
                icon: 'assets/sos.png',
                label: 'SOS',
                onTap: () => _launchPhone('09777788472'),
                iconSize: 30,
                fontSize: 16,
              ),
            ),

            SizedBox(height: sectionSpacing * 0.5),

            // Incident Report full-width button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: _buildFullWidthButton(
                icon: 'assets/report.png',
                label: 'Incident Report',
                onTap: () => _navigateToIncidentReport(context),
                iconSize: 30,
                fontSize: 16,
              ),
            ),

            const Spacer(),
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
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: iconSize,
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
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
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: iconSize,
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
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
