import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../services/alert_service.dart';
import '../../widgets/emergency_buttons.dart';
import '../incidents/incident_report_screen.dart';
import '../profile/emergency_contacts_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _fetchLocation();
    _setCurrentTime();
  }

  Future<void> _fetchLocation() async {
    Position position = await AlertService.getCurrentLocation();
    setState(() {
      _currentPosition = position;
      _initialPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );
      _locationReady = true;
    });
  }

  void _setCurrentTime() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd hh:mm a');
    _currentTime = formatter.format(now);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Map
              SizedBox(
                height: mapHeight,
                child:
                    _locationReady
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
                    buildSquareButton(
                      icon: 'assets/ambulance.png',
                      label: 'Ambulance',
                      onTap:
                          () =>
                              AlertService.launchPhone(context, '09123456789'),
                    ),
                    buildSquareButton(
                      icon: 'assets/firetruck.png',
                      label: 'Fire Truck',
                      onTap:
                          () =>
                              AlertService.launchPhone(context, '09123456789'),
                    ),
                    buildSquareButton(
                      icon: 'assets/police.png',
                      label: 'Police',
                      onTap:
                          () =>
                              AlertService.launchPhone(context, '09123456789'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing),

              // SOS Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: buildFullWidthButton(
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

              // Incident Report
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: buildFullWidthButton(
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
}
