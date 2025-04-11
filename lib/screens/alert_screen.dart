import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'incident_report_screen.dart';
import 'emergency_contacts_screen.dart'; // ← new import

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
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _initialPosition = CameraPosition(
        target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        zoom: 16,
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
    await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );
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

    final headerHeight = screenHeight * 0.08;
    final mapHeight = screenHeight * 0.35;
    final sectionSpacing = screenHeight * 0.02;
    final sidePadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: headerHeight,
                color: const Color(0xFF3F73A3),
                padding: EdgeInsets.symmetric(
                  vertical: headerHeight * 0.3,
                  horizontal: sidePadding,
                ),
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

              // Service Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSquareButton(
                      icon: 'assets/ambulance.png',
                      label: 'Ambulance',
                      onTap: () => _launchPhone('09123456789'),
                    ),
                    _buildSquareButton(
                      icon: 'assets/firetruck.png',
                      label: 'Fire Truck',
                      onTap: () => _launchPhone('09123456789'),
                    ),
                    _buildSquareButton(
                      icon: 'assets/police.png',
                      label: 'Police',
                      onTap: () => _launchPhone('09123456789'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing),

              // SOS Full-Width Button → now navigates to EmergencyContactsScreen
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: _buildFullWidthButton(
                  icon: 'assets/sos.png',
                  label: 'SOS',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen(),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: sectionSpacing),

              // Incident Report Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: _buildFullWidthButton(
                  icon: 'assets/report.png',
                  label: 'Incident Report',
                  onTap: () => _navigateToIncidentReport(context),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(icon, fit: BoxFit.contain),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
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

  Widget _buildFullWidthButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 35,
                child: Image.asset(icon, fit: BoxFit.contain),
              ),
              const SizedBox(width: 15),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
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
