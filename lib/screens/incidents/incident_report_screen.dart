import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:project_radar_app/screens/incidents/deepseek_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';

import 'location_picker_screen.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class IncidentReportPage extends StatefulWidget {
  const IncidentReportPage({super.key});

  @override
  State<IncidentReportPage> createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cellphoneController = TextEditingController();
  final _concernController = TextEditingController();
  final _otherIncidentTypeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();

  String? _incidentType;
  // Updated incident types with new options
  final List<String> _incidentTypes = ['Fire', 'Flood', 'Accident', 'Other'];
  final List<String> _otherIncidentTypes = [
    'Medical Assistance',
    'Medical Attention',
    'Landslide',
    'Earthquake',
    'Building Collapse',
    'Mass Panic',
    'Riot',
    'Food Poisoning'
  ];
  String? _selectedOtherIncidentType;
  
  final Color _primaryColor = const Color(0xFF3F73A3);
  final Color _backgroundColor = const Color(0xFFF0F4F8);
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isSubmitting = false;
  bool _isLoadingLocation = true;
  Timer? _addressTypingTimer;
  bool _isConfirmed = false; // Checkbox state

  // Replace Firebase with Supabase
  final SupabaseClient supabase = Supabase.instance.client;
  List<File> _selectedImages = [];

  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  bool _isMapInitialized = false;

  // suppression flag to avoid loops when setting address programmatically
  bool _suppressAddressController = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    // Only add listener once and respect suppression flag
    _addressController.addListener(() {
      if (_suppressAddressController) return; // don't react to programmatic sets
      _addressTypingTimer?.cancel();
      _addressTypingTimer = Timer(const Duration(milliseconds: 1000), () {
        // If address is readOnly (it is in UI), user won't type; but keep this safe
        _updateLatLongFromAddress(_addressController.text);
      });
    });

    _loadUserInfo().then((_) {
      _getCurrentLocation().then((_) {
        _animationController.forward();
        if (mounted) setState(() => _isLoadingLocation = false);
      });
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked.map((x) => File(x.path)).toList();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

Future<List<String>> _uploadImages(String incidentId) async {
  List<String> urls = [];
  final user = supabase.auth.currentUser;
  
  if (user == null) {
    print('❌ User not authenticated');
    return urls;
  }

  for (final img in _selectedImages) {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(img)}.jpg';
      final filePath = '${user.id}/$incidentId/$fileName';

      print('🔼 Attempting to upload image: $filePath');
      
      // Read file as bytes
      final Uint8List fileBytes = await img.readAsBytes();
      
      // Upload bytes instead of File object
      final uploadResponse = await supabase.storage
          .from('incidents')
          .uploadBinary(
            filePath, 
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            )
          );

      print('✅ Upload response: $uploadResponse');

      // Get public URL
      final publicUrl = supabase.storage
          .from('incidents')
          .getPublicUrl(filePath);

      print('🔗 Public URL: $publicUrl');
      
      urls.add(publicUrl);
      
    } catch (e) {
      print('❌ Error uploading image: $e');
      print('❌ Error details: ${e.toString()}');
    }
  }

  print('📊 Upload completed: ${urls.length}/${_selectedImages.length} images uploaded');
  return urls;
}

  Future<void> _updateLatLongFromAddress(String address) async {
    if (address.trim().isEmpty) return;
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLoc = LatLng(loc.latitude, loc.longitude);

        setState(() {
          _latitudeController.text = loc.latitude.toStringAsFixed(6);
          _longitudeController.text = loc.longitude.toStringAsFixed(6);
          _currentLocation = newLoc;
          _updateMarker(_currentLocation!);
        });

        // safe animate (await so camera moves before further updates)
        await _safeAnimateCamera(CameraUpdate.newLatLng(_currentLocation!));
        await _updateAddressDetailsFromLatLng(_currentLocation!);
      }
    } catch (e) {
      print('Error updating lat/long from address: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('app_users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return;
      
      if (!mounted) return;
      setState(() {
        final first = response['first_name'] as String? ?? '';
        final last = response['last_name'] as String? ?? '';
        _nameController.text = [first, last].where((s) => s.isNotEmpty).join(' ');

        String phone = response['phone'] as String? ?? '';
        if (phone.startsWith('+63') && phone.length == 13) {
          phone = '0${phone.substring(3)}';
        }
        _cellphoneController.text = phone;
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Location services are disabled. Please enable them.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location permission denied'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission permanently denied'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        return;
      }

      if (mounted) setState(() => _isLoadingLocation = true);

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _latitudeController.text = pos.latitude.toStringAsFixed(6);
        _longitudeController.text = pos.longitude.toStringAsFixed(6);
        _updateMarker(_currentLocation!);
      });

      if (_isMapInitialized) {
        await _safeAnimateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation!, zoom: 18),
          ),
        );
      }

      await _updateAddressDetailsFromLatLng(_currentLocation!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _latitudeController.clear();
          _longitudeController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching location: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _updateAddressDetailsFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addr = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        // Use suppression to avoid re-triggering the address listener
        _suppressAddressController = true;
        _addressController.text = addr;
        _barangayController.text = place.locality ?? '';
        _streetController.text = place.street ?? '';
        // Reset suppression shortly after programmatic change
        Future.delayed(const Duration(milliseconds: 150), () {
          _suppressAddressController = false;
        });
      }
    } catch (e) {
      print('Error getting address details: $e');
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  // Helper to check if lat/lng look valid
  bool _looksLikeValidLatLng(double lat, double lng) {
    return lat.abs() <= 90 && lng.abs() <= 180 && !(lat == 0.0 && lng == 0.0);
  }

  // Helper to parse dynamic values into double safely
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is num) return v.toDouble();
    return 0.0;
  }

  /// Safe animate helper: avoids calling animateCamera when the platform view isn't connected
  Future<void> _safeAnimateCamera(CameraUpdate cu) async {
    if (!mounted) return;
    if (_mapController == null) {
      // Map controller not ready yet
      print('safeAnimateCamera skipped: map controller is null');
      return;
    }
    if (!_isMapInitialized) {
      print('safeAnimateCamera skipped: map not initialized');
      return;
    }

    try {
      await _mapController!.animateCamera(cu);
    } catch (e, st) {
      // Log and swallow - prevents platform channel exception from bubbling up
      print('safeAnimateCamera failed: $e\n$st');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cellphoneController.dispose();
    _concernController.dispose();
    _otherIncidentTypeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _barangayController.dispose();
    _streetController.dispose();
    try {
      _mapController?.dispose();
    } catch (e) {
      // ignore errors disposing controller
    }
    _isMapInitialized = false;
    _addressTypingTimer?.cancel();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _addressController.clear();
    _concernController.clear();
    _otherIncidentTypeController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _barangayController.clear();
    _streetController.clear();
    setState(() {
      _incidentType = null;
      _selectedOtherIncidentType = null;
      _isSubmitting = false;
      _selectedImages.clear();
      _isConfirmed = false; // Reset checkbox state
    });
  }

Future<void> _triggerWebSpamAnalysis(String incidentId) async {
  try {
    // This will trigger the web spam filter to re-analyze with AI data
    await supabase
        .from('incident_analysis_triggers')
        .insert({
          'incident_id': incidentId,
          'trigger_type': 'ai_analysis_sync',
          'created_at': DateTime.now().toIso8601String(),
        });
    
    print('🔄 Triggered web spam analysis for incident: $incidentId');
  } catch (e) {
    print('⚠️ Could not trigger web spam analysis: $e');
  }
}

Future<void> _submitForm() async {
  // NEW: Check if checkbox is checked
  if (!_isConfirmed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please confirm that the information is true and accurate'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    return;
  }

  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() => _isSubmitting = true);

  try {
    final description = _concernController.text.trim();
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Run AI analysis with fallback support
    final aiAnalysis = await DeepSeekService.analyzeIncidentReport(description);
    
    // Log the analysis method used
    final analysisMethod = aiAnalysis['analysis_method'] ?? 'unknown';
    
    print('🔍 Analysis completed using: $analysisMethod');
    if (aiAnalysis['ai_service_available'] == false) {
      print('⚠️ Using fallback analysis due to: ${aiAnalysis['fallback_reason']}');
    }
    
    // Submit to database
    final incidentId = 'incident_${DateTime.now().millisecondsSinceEpoch}_${user.id}';
    
    // Upload images
    List<String> imageUrls = [];
    if (_selectedImages.isNotEmpty) {
      imageUrls = await _uploadImages(incidentId);
    }

    // Determine the final incident type
    String finalIncidentType;
    if (_incidentType == 'Other') {
      finalIncidentType = _selectedOtherIncidentType ?? 'Other';
    } else {
      finalIncidentType = _incidentType ?? '';
    }

    // Prepare data for insertion
    final Map<String, dynamic> incidentData = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'contact_number': _cellphoneController.text.trim(),
      'incident_type': finalIncidentType,
      'description': _concernController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending', // Use lowercase 'pending'
      'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
      'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
      'barangay': _barangayController.text.trim(),
      'street': _streetController.text.trim(),
      'user_id': user.id,
      'image_urls': imageUrls,
      
      // AI Analysis Results
      'suspicion_score': (aiAnalysis['suspicion_score'] as num).toDouble(),
      'requires_review': aiAnalysis['requires_review'] ?? false,
      'ai_analysis': aiAnalysis['explanation'] ?? 'Analysis completed',
      'matched_patterns': aiAnalysis['matched_patterns'] ?? [],
      'analysis_method': analysisMethod,
      
      // Initialize spam fields
      'is_spam': false,
      'spam_score': 0,
    };

    // Remove any fields that might not exist in your table
    incidentData.removeWhere((key, value) => value == null);

    print('📦 Submitting incident data: ${incidentData.keys.toList()}');

    final response = await supabase
        .from('incidents')
        .insert(incidentData)
        .select();

    if (response.isNotEmpty) {
      final createdIncident = response.first;
      print('✅ Incident created with ID: ${createdIncident['id']}');
      
      // Trigger web spam filter sync
      _triggerWebSpamAnalysis(createdIncident['id'].toString());
    }

    // Show appropriate success message
    String successMessage = 'Incident report submitted successfully!';
    if (aiAnalysis['ai_service_available'] == false) {
      successMessage += '';
    } else if (aiAnalysis['requires_review'] == true) {
      successMessage += ' It will be reviewed by admin due to content analysis.';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: (aiAnalysis['ai_service_available'] == true) ? Colors.green : const Color.fromARGB(255, 76, 175, 80),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    _resetForm();
    if (mounted) Navigator.pop(context);
    
  } catch (e) {
    print('❌ Error submitting incident: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your contact number';
    final cleaned = v.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^09\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 11-digit phone starting with 09';
    }
    return null;
  }

  Widget _buildLocationPickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isLoadingLocation || _currentLocation == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(_primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Getting your location...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 18,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController = controller;
                      setState(() => _isMapInitialized = true);

                      // Ensure the map recenters to the current location when the controller is ready
                      if (_currentLocation != null) {
                        try {
                          await _safeAnimateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(target: _currentLocation!, zoom: 18),
                            ),
                          );
                        } catch (e) {
                          print('Error animating camera onMapCreated: $e');
                        }
                      }
                    },
                    onTap: (LatLng position) {
                      setState(() {
                        _currentLocation = position;
                        _latitudeController.text =
                            position.latitude.toStringAsFixed(6);
                        _longitudeController.text =
                            position.longitude.toStringAsFixed(6);
                        _updateMarker(position);
                      });
                      _updateAddressDetailsFromLatLng(position);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final initialLat = _currentLocation?.latitude ?? 0;
                  final initialLng = _currentLocation?.longitude ?? 0;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        initialLat: initialLat,
                        initialLng: initialLng,
                      ),
                    ),
                  );

                  if (result != null && mounted) {
                    // Robust parsing of returned values
                    double lat = _toDouble(result["lat"]);
                    double lng = _toDouble(result["lng"]);

                    bool isValid(double a, double b) =>
                        _looksLikeValidLatLng(a, b);

                    // If lat/lng look invalid but swapped values look valid, swap them.
                    if (!isValid(lat, lng) && isValid(lng, lat)) {
                      final tmp = lat;
                      lat = lng;
                      lng = tmp;
                      print(
                          'Detected swapped lat/lng from picker — swapped them.');
                    }

                    // If still invalid (e.g., 0,0) fall back to current device location if available
                    if (!isValid(lat, lng)) {
                      if (_currentLocation != null) {
                        lat = _currentLocation!.latitude;
                        lng = _currentLocation!.longitude;
                        print(
                            'Picker returned invalid coords; falling back to device location.');
                      } else {
                        print(
                            'Picker returned invalid coords and no device location available.');
                      }
                    }

                    // Optional: log if the returned location is extremely far from device location
                    if (_currentLocation != null) {
                      try {
                        final distance = Geolocator.distanceBetween(
                            _currentLocation!.latitude,
                            _currentLocation!.longitude,
                            lat,
                            lng);
                        if (distance > 50000) {
                          // 50 km threshold
                          print(
                              'Picker returned coordinates far from user location: ${distance.toStringAsFixed(0)} meters');
                        }
                      } catch (e) {
                        print('Error computing distance: $e');
                      }
                    }

                    // Update UI / map — suppress address listener while setting address
                    setState(() {
                      _latitudeController.text = lat.toStringAsFixed(6);
                      _longitudeController.text = lng.toStringAsFixed(6);
                      _currentLocation = LatLng(lat, lng);
                      _updateMarker(_currentLocation!);
                    });

                    // When setting address fields from picker result, suppress listener
                    _suppressAddressController = true;
                    final pickAddr = result["address"];
                    if (pickAddr != null) {
                      _addressController.text = pickAddr;
                    }
                    _barangayController.text =
                        result["barangay"] ?? _barangayController.text;
                    _streetController.text =
                        result["street"] ?? _streetController.text;
                    Future.delayed(const Duration(milliseconds: 150), () {
                      _suppressAddressController = false;
                    });

                    if (_mapController != null && _isMapInitialized) {
                      await _safeAnimateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _currentLocation!, zoom: 18),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.location_pin, size: 18),
                label: const Text('Change Pin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
    TextFormField(
      controller: _addressController,
      readOnly: true,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Address',
        prefixIcon: Icon(Icons.location_on_outlined, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintText: "Select location on map",
      ),
      validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
      // ADD THESE TO COMPLETELY DISABLE INTERACTION:
      enableInteractiveSelection: false,
      focusNode: AlwaysDisabledFocusNode(),
    ),
        SizedBox(
            height: 0,
            width: 0,
            child:
                TextFormField(controller: _barangayController, enabled: false)),
        SizedBox(
            height: 0,
            width: 0,
            child: TextFormField(controller: _streetController, enabled: false)),
        SizedBox(
            height: 0,
            width: 0,
            child:
                TextFormField(controller: _latitudeController, enabled: false)),
        SizedBox(
            height: 0,
            width: 0,
            child:
                TextFormField(controller: _longitudeController, enabled: false)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
      ),
      validator: (v) => v == null || v.isEmpty ? validator : null,
      enableInteractiveSelection: !readOnly,
      focusNode: readOnly ? AlwaysDisabledFocusNode() : null,
    );
  }

  Widget _buildConcernField() {
    return TextFormField(
      controller: _concernController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: 'Detailed Description',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.description_outlined, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Please describe the incident in detail' : null,
    );
  }

  // Build confirmation checkbox
  Widget _buildConfirmationCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _isConfirmed,
            onChanged: (bool? value) {
              setState(() {
                _isConfirmed = value ?? false;
              });
            },
            activeColor: _primaryColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'I confirm that all the information provided is true and accurate to the best of my knowledge.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Images (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos to help us better understand the situation',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _pickImage,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: BorderSide(color: _primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined),
                SizedBox(width: 8),
                Text('Select Images'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          Text(
            'Selected Images (${_selectedImages.length})',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: _primaryColor,
              expandedHeight: 140,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: 1,
                  child: Text(
                    'Incident Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryColor, Color.lerp(_primaryColor, Colors.black, 0.2)!],
                    ),
                  ),
                  child: const Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.report_problem, size: 100, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, __) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.report_problem_outlined, size: 48, color: _primaryColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Report an Incident',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Please fill out all fields to submit your report',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Name field - now read-only
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: 'Please enter your name',
                                readOnly: true, // NEW: Made read-only
                              ),
                              const SizedBox(height: 16),

                              _buildLocationPickerSection(),
                              const SizedBox(height: 16),

                              // Contact Number field
                              TextFormField(
                                controller: _cellphoneController,
                                keyboardType: TextInputType.phone,
                                readOnly: true, // NEW: Made read-only
                                decoration: InputDecoration(
                                  labelText: 'Contact Number',
                                  prefixIcon: Icon(Icons.phone_outlined, color: _primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), 
                                    borderSide: BorderSide(color: Colors.grey.shade300)
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), 
                                    borderSide: BorderSide(color: _primaryColor, width: 2)
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                validator: _validatePhone,
                                enableInteractiveSelection: false,
                                focusNode: AlwaysDisabledFocusNode(),
                              ),
                              const SizedBox(height: 16),

                              // Incident Type dropdown
                              DropdownButtonFormField<String>(
                                value: _incidentType,
                                decoration: InputDecoration(
                                  labelText: 'Incident Type',
                                  prefixIcon: Icon(Icons.warning_amber_outlined, color: _primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), 
                                    borderSide: BorderSide(color: Colors.grey.shade300)
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), 
                                    borderSide: BorderSide(color: _primaryColor, width: 2)
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                ),
                                dropdownColor: Colors.white,
                                items: _incidentTypes.map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                                )).toList(),
                                onChanged: (v) => setState(() => _incidentType = v),
                                validator: (v) => v == null ? 'Please select an incident type' : null,
                                style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                              ),

                              // Other Incident Type dropdown (replaced text field)
                              if (_incidentType == 'Other') ...[
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedOtherIncidentType,
                                  decoration: InputDecoration(
                                    labelText: 'Specify Incident Type',
                                    prefixIcon: Icon(Icons.list_outlined, color: _primaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide(color: Colors.grey.shade300)
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide(color: _primaryColor, width: 2)
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    labelStyle: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  dropdownColor: Colors.white,
                                  items: _otherIncidentTypes.map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedOtherIncidentType = v),
                                  validator: (v) => v == null ? 'Please select an incident type' : null,
                                  style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                ),
                              ],
                              const SizedBox(height: 16),

                              _buildConcernField(),
                              const SizedBox(height: 16),

                              // Confirmation checkbox
                              _buildConfirmationCheckbox(),
                              const SizedBox(height: 16),

                              _buildImageUploadSection(),
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSubmitting ? Colors.grey.shade400 : _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    shadowColor: Color.lerp(_primaryColor, Colors.black, 0.3),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'SUBMIT REPORT',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}