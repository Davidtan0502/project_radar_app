import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:project_radar_app/screens/incidents/config_loader.dart';
import 'package:project_radar_app/screens/incidents/suspicious_content_screen.dart';
import '../../services/config.dart';
import 'location_picker_screen.dart';

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
  final _landmarkController = TextEditingController();
  final _cellphoneController = TextEditingController();
  final _concernController = TextEditingController();
  final _otherIncidentTypeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();

  String? _incidentType;
  final List<String> _incidentTypes = ['Fire', 'Flood', 'Accident', 'Other'];
  final Color _primaryColor = const Color(0xFF3F73A3);
  final Color _backgroundColor = const Color(0xFFF0F4F8);
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isSubmitting = false;
  bool _isLoadingLocation = true;
  Timer? _addressTypingTimer;

  final CollectionReference _incidentsCollection =
      FirebaseFirestore.instance.collection('incidents');
  List<File> _selectedImages = [];

  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  bool _isMapInitialized = false;

  // NEW: suppression flag to avoid loops when setting address programmatically
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

    ConfigLoader.loadConfig();
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
    final storage = FirebaseStorage.instance;
    List<String> urls = [];

    for (final img in _selectedImages) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child('incidents/$incidentId/$fileName');

      try {
        final snapshot = await ref.putFile(img);
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print('Error uploading image $fileName: $e');
      }
    }

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return;
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        final first = data['firstName'] as String? ?? '';
        final last = data['lastName'] as String? ?? '';
        _nameController.text = [first, last].where((s) => s.isNotEmpty).join(' ');

        String phone = data['phone'] as String? ?? '';
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
    _landmarkController.dispose();
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
    _landmarkController.clear();
    _concernController.clear();
    _otherIncidentTypeController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _barangayController.clear();
    _streetController.clear();
    setState(() {
      _incidentType = null;
      _isSubmitting = false;
      _selectedImages.clear();
    });
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final description = _concernController.text.trim();

      print('=== DEBUG: Starting content analysis ===');
      print('Description: "$description"');

      final aiAnalysis = await _analyzeContent(description);
      final isSuspicious = aiAnalysis['isSuspicious'] ?? false;
      final suspicionScore = aiAnalysis['score'] ?? 0.0;
      final matchedPatterns = aiAnalysis['matchedPatterns'] ?? [];
      final aiExplanation = aiAnalysis['explanation'] ?? '';

      print('=== DEBUG: Analysis Results ===');
      print('Suspicious: $isSuspicious');
      print('Score: $suspicionScore');
      print('Matched Patterns: $matchedPatterns');
      print('Explanation: $aiExplanation');
      print('==============================');

      if (isSuspicious) {
        print('DEBUG: Navigating to suspicious content screen');
        final shouldProceed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuspiciousContentScreen(
              description: description,
              suspicionScore: suspicionScore,
              matchedPatterns: matchedPatterns,
              explanation: aiExplanation,
              onConfirm: () {
                print('DEBUG: User confirmed submission');
                Navigator.pop(context, true);
              },
              onCancel: () {
                print('DEBUG: User canceled submission');
                Navigator.pop(context, false);
              },
            ),
          ),
        );

        if (shouldProceed != true) {
          print('DEBUG: User canceled, stopping submission');
          setState(() => _isSubmitting = false);
          return;
        }
        print('DEBUG: User confirmed, proceeding with submission');
      } else {
        print('DEBUG: Content not suspicious, proceeding directly');
      }

      final docRef = await _incidentsCollection.add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'contactNumber': _cellphoneController.text.trim(),
        'incidentType': _incidentType == 'Other'
            ? _otherIncidentTypeController.text.trim()
            : _incidentType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'status': isSuspicious ? 'Under Review' : 'Pending',
        'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        'barangay': _barangayController.text.trim(),
        'street': _streetController.text.trim(),
        'suspicionScore': suspicionScore,
        'requiresReview': isSuspicious,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'aiAnalysis': aiExplanation,
        if (matchedPatterns.isNotEmpty) 'matchedPatterns': matchedPatterns,
        'statusUpdates': [
          {
            'status': isSuspicious ? 'Under Review' : 'Pending',
            'timestamp': Timestamp.now(),
            'note': 'Report submitted',
          }
        ],
      });

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(docRef.id);
        if (imageUrls.isNotEmpty) {
          await docRef.update({'imageUrls': imageUrls});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuspicious
                ? 'Report submitted and flagged for review'
                : 'Incident report submitted successfully!'),
            backgroundColor: isSuspicious ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      _resetForm();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<Map<String, dynamic>> _analyzeContent(String text) async {
    if (text.isEmpty) {
      return {
        'isSuspicious': false,
        'score': 0.0,
        'matchedPatterns': [],
        'explanation': 'No content to analyze',
      };
    }

    try {
      // Load all suspicious patterns from config
      final suspiciousPatterns = await ConfigLoader.getAllSuspiciousPatterns();
      final inappropriateLanguage = await ConfigLoader.getAllInappropriateLanguage();
      final disrespectfulContent = await ConfigLoader.getAllDisrespectfulContent();
      final lustfulContent = await ConfigLoader.getAllLustfulContent();
      final implausibleScenarios = await ConfigLoader.getAllImplausibleScenarios();
      final vagueDescriptions = await ConfigLoader.getAllVagueDescriptions();

      // Combine all patterns for analysis
      final allPatterns = [
        ...suspiciousPatterns,
        ...inappropriateLanguage,
        ...disrespectfulContent,
        ...lustfulContent,
        ...implausibleScenarios,
        ...vagueDescriptions,
      ];

      print('DEBUG: Loaded ${allPatterns.length} total patterns');

      final lowerText = text.toLowerCase();
      List<String> matchedPatterns = [];
      double score = 0.0;

      // SIMPLE AND AGGRESSIVE PATTERN MATCHING
      for (final pattern in allPatterns) {
        final lowerPattern = pattern.toLowerCase();
        
        // Direct contains check - most aggressive
        if (lowerText.contains(lowerPattern)) {
          matchedPatterns.add(pattern);
          print('DEBUG: MATCHED PATTERN: "$pattern" in text: "$lowerText"');
        }
      }

      print('DEBUG: Found ${matchedPatterns.length} matched patterns');

      // VERY SENSITIVE SCORING - ANY MATCH TRIGGERS SUSPICION
      if (matchedPatterns.isNotEmpty) {
        // Base score - any match gives at least 0.5
        score = 0.5 + (matchedPatterns.length * 0.1);
        score = score.clamp(0.0, 1.0);
        
        // Extra points for high severity patterns
        final highSeverityPatterns = [
          ...inappropriateLanguage,
          ...disrespectfulContent,
          ...lustfulContent,
        ];
        
        final highSeverityMatches = matchedPatterns.where((pattern) => 
          highSeverityPatterns.contains(pattern)).length;
        
        if (highSeverityMatches > 0) {
          score = (score + (highSeverityMatches * 0.2)).clamp(0.0, 1.0);
        }
      }

      // FORCE SUSPICIOUS IF ANY PATTERNS MATCHED
      final isSuspicious = matchedPatterns.isNotEmpty;

      String explanation;
      if (matchedPatterns.isEmpty) {
        explanation = 'No suspicious patterns detected';
      } else {
        final topPatterns = matchedPatterns.take(5).join(', ');
        explanation = 'Detected ${matchedPatterns.length} suspicious pattern(s): $topPatterns${matchedPatterns.length > 5 ? '...' : ''}';
        
        if (score >= 0.7) {
          explanation += ' - High suspicion level';
        } else if (score >= 0.4) {
          explanation += ' - Medium suspicion level';
        } else {
          explanation += ' - Low suspicion level';
        }
      }

      print('DEBUG: Final decision - suspicious: $isSuspicious, score: $score');

      return {
        'isSuspicious': isSuspicious,
        'score': score,
        'matchedPatterns': matchedPatterns,
        'explanation': explanation,
      };
    } catch (e) {
      print('Error in content analysis: $e');
      return {
        'isSuspicious': false,
        'score': 0.0,
        'matchedPatterns': [],
        'explanation': 'Analysis failed: $e',
      };
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            labelStyle: TextStyle(color: Colors.grey.shade600),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
      ),
      validator: (v) => v == null || v.isEmpty ? validator : null,
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
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
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
                      colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                    ),
                  ),
                  child: Center(
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

                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: 'Please enter your name',
                              ),
                              const SizedBox(height: 16),

                              _buildLocationPickerSection(),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _landmarkController,
                                label: 'Landmark',
                                icon: Icons.place_outlined,
                                validator: 'Please enter a nearby landmark',
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _cellphoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Contact Number',
                                  prefixIcon: Icon(Icons.phone_outlined, color: _primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                ),
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 16),

                              DropdownButtonFormField<String>(
                                value: _incidentType,
                                decoration: InputDecoration(
                                  labelText: 'Incident Type',
                                  prefixIcon: Icon(Icons.warning_amber_outlined, color: _primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 2)),
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

                              if (_incidentType == 'Other') ...[
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _otherIncidentTypeController,
                                  label: 'Specify Incident Type',
                                  icon: Icons.edit_outlined,
                                  validator: 'Please specify the incident type',
                                ),
                              ],
                              const SizedBox(height: 16),

                              _buildConcernField(),
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
                                    shadowColor: _primaryColor.withOpacity(0.3),
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : Text(
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