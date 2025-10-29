import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/alert_service.dart';
import '../../services/emergency_contact_service.dart';
import '../profile/account management files/edit_account_info.dart';
import '../../widgets/emergency_buttons.dart';
import '../incidents/incident_report_screen.dart';
import '../alerts/report_tracker_screen.dart';
import '../profile/profile navigation/account_information.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _setCurrentTime();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('app_users')
            .select()
            .eq('id', user.id)
            .single();
        
        if (response != null) {
          setState(() {
            _userData = Map<String, dynamic>.from(response);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  bool _isUserVerified() {
    if (_userData == null) return false;
    
    // Check if user is verified in database
    final isVerified = _userData!['is_verified'] ?? false;
    if (!isVerified) return false;

    // Check if profile is complete (same logic as other screens)
    final dob = (_userData!['dob'] ?? '').toString().trim();
    final hasDob = dob.isNotEmpty;
    if (!hasDob) return false;

    final residentAddress = _userData!['resident_address'] is Map 
        ? Map<String, dynamic>.from(_userData!['resident_address']) 
        : null;

    if (residentAddress == null) return false;

    final hasHouseNo = (residentAddress['house'] ?? '').toString().trim().isNotEmpty;
    final hasStreet = (residentAddress['street'] ?? '').toString().trim().isNotEmpty;
    final hasBarangay = (residentAddress['barangay'] ?? '').toString().trim().isNotEmpty;
    final hasZipCode = (residentAddress['zip'] ?? '').toString().trim().isNotEmpty;
    final hasCity = (residentAddress['city'] ?? '').toString().trim().isNotEmpty;

    return hasHouseNo && hasStreet && hasBarangay && hasZipCode && hasCity;
  }

  void _showVerificationRequiredDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Verification Required",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "To report incidents, you need to complete your profile verification. Please fill in your date of birth and complete address information.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // Navigate to EditAccountinfo and wait for result
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditAccountinfo(),
                          ),
                        );
                        
                        // Reload user data when returning from edit screen
                        if (result == true || result == 'updated') {
                          await _loadUserData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F73A3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Verify Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _handleIncidentReport() {
    if (_isUserVerified()) {
      _navigateToIncidentReport(context);
    } else {
      _showVerificationRequiredDialog();
    }
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

  // New method to open phone's contact list
  Future<void> _openPhoneContacts() async {
    try {
      const url = 'content://com.android.contacts/contacts';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: Try to open the dialer instead
        const dialerUri = 'tel:';
        if (await canLaunchUrl(Uri.parse(dialerUri))) {
          await launchUrl(Uri.parse(dialerUri));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot open contacts'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot open contacts'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
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
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom + 8, // ✅ dynamic bottom padding
    ),
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
                              AlertService.launchPhone(context, '09326622322'),
                        ),
                        buildSquareButton(
                          icon: 'assets/firetruck.png',
                          label: 'Fire Truck',
                          onTap: () =>
                              AlertService.launchPhone(context, '09326622322'),
                        ),
                        buildSquareButton(
                          icon: 'assets/police.png',
                          label: 'Police',
                          onTap: () =>
                              AlertService.launchPhone(context, '09326622322'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: sectionSpacing * 1.5),

              // SOS Button (now opens phone contacts)
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
                        onTap: _openPhoneContacts, // Changed to open contacts
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
                      onTap: _handleIncidentReport,
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