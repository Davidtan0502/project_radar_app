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
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:project_radar_app/screens/incidents/config_loader.dart';
import 'package:project_radar_app/screens/incidents/suspicious_content_screen.dart';
import '../../services/config.dart';
import 'location_picker_screen.dart';


class IncidentReportPage extends StatefulWidget {
  const IncidentReportPage({super.key});
  static const String _apiKey = Config.googleAIApiKey;

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
    
    _loadUserInfo().then((_) {
      _getCurrentLocation().then((_) {
        _animationController.forward();
        setState(() => _isLoadingLocation = false);
      });
    });

    _addressController.addListener(() {
      _addressTypingTimer?.cancel();
      _addressTypingTimer = Timer(const Duration(milliseconds: 1000), () {
        _updateLatLongFromAddress(_addressController.text);
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
        setState(() {
          _latitudeController.text = loc.latitude.toStringAsFixed(6);
          _longitudeController.text = loc.longitude.toStringAsFixed(6);
          _currentLocation = LatLng(loc.latitude, loc.longitude);
          _updateMarker(_currentLocation!);
          _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
        });
        _updateAddressDetailsFromLatLng(_currentLocation!);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled. Please enable them.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission permanently denied'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      setState(() => _isLoadingLocation = true);

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _latitudeController.text = pos.latitude.toStringAsFixed(6);
        _longitudeController.text = pos.longitude.toStringAsFixed(6);
        _updateMarker(_currentLocation!);
      });

      if (_isMapInitialized) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation!, zoom: 18),
          ),
        );
      }

      await _updateAddressDetailsFromLatLng(_currentLocation!);
    } catch (e) {
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
    } finally {
      setState(() => _isLoadingLocation = false);
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
        
        setState(() {
          _addressController.text = addr;
          _barangayController.text = place.locality ?? '';
          _streetController.text = place.street ?? '';
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
    _mapController?.dispose();
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

      final aiAnalysis = await _analyzeContentWithAI(description);
      final isSuspicious = aiAnalysis['isSuspicious'] ?? false;
      final suspicionScore = aiAnalysis['score'] ?? 0.0;
      final matchedPatterns = aiAnalysis['matchedPatterns'] ?? [];
      final aiExplanation = aiAnalysis['explanation'] ?? '';

      if (isSuspicious) {
        final shouldProceed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuspiciousContentScreen(
              description: description,
              suspicionScore: suspicionScore,
              matchedPatterns: matchedPatterns,
              explanation: aiExplanation,
              onConfirm: () => Navigator.pop(context, true),
              onCancel: () => Navigator.pop(context, false),
            ),
          ),
        );

        if (shouldProceed != true) {
          setState(() => _isSubmitting = false);
          return;
        }
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSuspicious
              ? 'Report submitted and flagged for review'
              : 'Incident report submitted successfully!'),
          backgroundColor: isSuspicious ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      _resetForm();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<Map<String, dynamic>> _analyzeContentWithAI(String text) async {
    if (text.isEmpty) {
      return {
        'isSuspicious': false,
        'score': 0.0,
        'matchedPatterns': [],
        'explanation': 'No content to analyze',
      };
    }

    try {
      final config = await ConfigLoader.loadConfig();
      final patterns = ConfigLoader.getAllSuspiciousPatterns();
      
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: IncidentReportPage._apiKey,
      );

      final prompt = '''
Analyze this incident report for potential false or malicious content using these suspicious patterns: ${patterns.join(', ')}.

Text to analyze: "$text"

Provide a JSON response with:
- isSuspicious: boolean
- score: number between 0 and 1 (0 = not suspicious, 1 = highly suspicious)
- explanation: brief explanation of why it might be suspicious
- matchedPatterns: array of suspicious patterns found

Focus on identifying:
1. Explicit statements about being fake, test, joke, prank, etc.
2. Inappropriate or offensive language
3. Contradictory or implausible information
4. Lack of specific details when expected
5. Any other indicators of false reporting

Response must be valid JSON only, no additional text.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0);
          final parsed = json.decode(jsonString!);
          
          return {
            'isSuspicious': parsed['isSuspicious'] ?? false,
            'score': (parsed['score'] ?? 0.0).toDouble(),
            'matchedPatterns': List<String>.from(parsed['matchedPatterns'] ?? []),
            'explanation': parsed['explanation'] ?? 'No explanation provided',
          };
        }
      } catch (e) {
        print('Error parsing AI response: $e');
      }

      return _analyzeText(text);
    } catch (e) {
      print('AI analysis error: $e');
      return _analyzeText(text);
    }
  }

  Future<Map<String, dynamic>> _analyzeText(String text) async {
    if (text.isEmpty) {
      return {
        'isSuspicious': false,
        'score': 0.0,
        'matchedPatterns': [],
        'explanation': 'No content to analyze',
      };
    }

    final patterns = await ConfigLoader.getAllSuspiciousPatterns();
    final lowerText = text.toLowerCase();
    int matchCount = 0;
    List<String> matchedPatterns = [];
    
    for (final pattern in patterns) {
      if (lowerText.contains(pattern.toLowerCase())) {
        matchCount++;
        matchedPatterns.add(pattern);
        if (matchCount >= 3) break;
      }
    }
    
    final score = matchCount / 10 > 1.0 ? 1.0 : matchCount / 10;
    
    return {
      'isSuspicious': matchCount >= 1,
      'score': score,
      'matchedPatterns': matchedPatterns,
      'explanation': matchCount > 0 
          ? 'Found ${matchCount} suspicious pattern(s): ${matchedPatterns.join(', ')}'
          : 'No suspicious patterns detected',
    };
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
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      setState(() => _isMapInitialized = true);
                    },
                    onTap: (LatLng position) {
                      setState(() {
                        _currentLocation = position;
                        _latitudeController.text = position.latitude.toStringAsFixed(6);
                        _longitudeController.text = position.longitude.toStringAsFixed(6);
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                    setState(() {
                      _latitudeController.text = result["lat"].toStringAsFixed(6);
                      _longitudeController.text = result["lng"].toStringAsFixed(6);
                      _addressController.text = result["address"] ?? '';
                      _barangayController.text = result["barangay"] ?? '';
                      _streetController.text = result["street"] ?? '';
                      _currentLocation = LatLng(result["lat"], result["lng"]);
                      _updateMarker(_currentLocation!);
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _currentLocation!, zoom: 18),
                        ),
                      );
                    });
                  }
                },
                icon: const Icon(Icons.location_pin, size: 18),
                label: const Text('Change Pin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            labelStyle: TextStyle(color: Colors.grey.shade600),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
        ),
        SizedBox(height: 0, width: 0, child: TextFormField(controller: _barangayController, enabled: false)),
        SizedBox(height: 0, width: 0, child: TextFormField(controller: _streetController, enabled: false)),
        SizedBox(height: 0, width: 0, child: TextFormField(controller: _latitudeController, enabled: false)),
        SizedBox(height: 0, width: 0, child: TextFormField(controller: _longitudeController, enabled: false)),
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