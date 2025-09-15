import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../services/alert_service.dart';
import '../../services/emergency_contact_service.dart';
import '../../widgets/emergency_buttons.dart';
import '../incidents/incident_report_screen.dart';
import '../alerts/report_tracker_screen.dart';

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
  bool _isRefreshing = false;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _setCurrentTime();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      Position position = await AlertService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        );
        _locationReady = true;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to get location'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _setCurrentTime() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd hh:mm a');
    setState(() {
      _currentTime = formatter.format(now);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _refreshMap() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Add a small delay to show the refreshing animation
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _fetchLocation();
    
    // Animate camera to new position
    if (_locationReady) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition.latitude, _currentPosition.longitude),
        ),
      );
    }
  }

  void _navigateToIncidentReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncidentReportPage()),
    );
  }

  void _navigateToReportTracker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportTrackerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final headerHeight = screenHeight * 0.08;
    final mapHeight = screenHeight * 0.35;
    final sectionSpacing = screenHeight * 0.025;
    final sidePadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          heroTag: "report_tracker",
          backgroundColor: Colors.green,
          onPressed: () => _navigateToReportTracker(context),
          child: const Icon(Icons.track_changes, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F73A3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
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
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing),

              // Map Container
              Container(
                height: mapHeight,
                margin: EdgeInsets.symmetric(horizontal: sidePadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _locationReady
                          ? GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: _initialPosition,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              buildingsEnabled: true,
                              compassEnabled: true,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Color(0xFF3F73A3)),
                                ),
                              ),
                            ),
                    ),
                    
                    // Refresh Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF3F73A3)),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF3F73A3),
                                  size: 24,
                                ),
                          onPressed: _isRefreshing ? null : _refreshMap,
                          tooltip: 'Refresh Location',
                        ),
                      ),
                    ),
                    
                    // Location Accuracy Indicator
                    if (_locationReady)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_currentPosition.accuracy.toStringAsFixed(1)}m accuracy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing * 1.5),

              // Service Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildSquareButton(
                          icon: 'assets/ambulance.png',
                          label: 'Ambulance',
                          onTap: () =>
                              AlertService.launchPhone(context, '09123456789'),
                        ),
                        buildSquareButton(
                          icon: 'assets/firetruck.png',
                          label: 'Fire Truck',
                          onTap: () =>
                              AlertService.launchPhone(context, '09123456789'),
                        ),
                        buildSquareButton(
                          icon: 'assets/police.png',
                          label: 'Police',
                          onTap: () =>
                              AlertService.launchPhone(context, '09123456789'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing * 1.5),

              // SOS Button (calls first saved contact)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: buildFullWidthButton(
                        icon: 'assets/sos.png',
                        label: 'SOS EMERGENCY',
                        onTap: () async {
                          final contacts =
                              await EmergencyContactService().loadContacts();
                          if (contacts.isNotEmpty) {
                            final firstPhone = contacts.first['phone'];
                            if (firstPhone != null && firstPhone.isNotEmpty) {
                              AlertService.launchPhone(context, firstPhone);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('No phone number available for SOS call.'),
                                  backgroundColor: Colors.red[400],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('No emergency contacts available.'),
                                backgroundColor: Colors.red[400],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing * 1.5),

              // Incident Report
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Issues',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildFullWidthButton(
                      icon: 'assets/report.png',
                      label: 'Incident Report',
                      onTap: () => _navigateToIncidentReport(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}