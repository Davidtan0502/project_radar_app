import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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

  String? _incidentType;
  final List<String> _incidentTypes = ['Fire', 'Flood', 'Accident', 'Other'];
  final Color _primaryColor = const Color(0xFF3F73A3);
  final Color _backgroundColor = const Color(0xFFF0F4F8);
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isSubmitting = false;
  Timer? _addressTypingTimer;

  final CollectionReference _incidentsCollection = 
      FirebaseFirestore.instance.collection('incidents');

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
    _animationController.forward();
    _loadUserInfo();
    _getCurrentLocation();

    // Add listener to detect manual address entry
    _addressController.addListener(() {
      _addressTypingTimer?.cancel();
      _addressTypingTimer = Timer(const Duration(milliseconds: 1000), () {
        _updateLatLongFromAddress(_addressController.text);
      });
    });
  }

  // Enhanced client-side content checking
  Map<String, dynamic> _analyzeText(String text) {
    if (text.isEmpty) {
      return {
        'isSuspicious': false,
        'score': 0.0,
        'matchedPatterns': [],
      };
    }

    final lowerText = text.toLowerCase();
    final suspiciousPatterns = [
      'fake', 'test', 'joke', 'prank', 'not real', 'false', 'drill',
      'biro', 'practice', 'sinubukan', 'walang totoo', 'peke', 'gago',
      'bobo', 'tang ina', 'putang ina', 'leche', 'punyeta', 'sira ulo',
      'bullshit', 'nonsense', 'just kidding', 'not serious', 'practice report',
      'test lang', 'no emergency', 'just a drill', 'this is only a test',
      'walang', 'tunay', 'totoo', 'exercise', 'simulation', 'mock'
    ];
    
    int matchCount = 0;
    List<String> matchedPatterns = [];
    
    for (final pattern in suspiciousPatterns) {
      if (lowerText.contains(pattern)) {
        matchCount++;
        matchedPatterns.add(pattern);
        // Early exit if we find strong evidence
        if (matchCount >= 3) break;
      }
    }
    
    return {
      'isSuspicious': matchCount >= 2, // Require at least 2 matches
      'score': matchCount / 10, // Convert to 0-1 scale
      'matchedPatterns': matchedPatterns,
    };
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
        });
      }
    } catch (e) {
      // silently fail
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
            content: const Text(
              'Location services are disabled. Please enable them.',
            ),
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
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addr = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        
        setState(() {
          _addressController.text = addr;
          _latitudeController.text = pos.latitude.toStringAsFixed(6);
          _longitudeController.text = pos.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching location: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
    setState(() {
      _incidentType = null;
      _isSubmitting = false;
    });
  }

Future<void> _submitForm() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() => _isSubmitting = true);

  try {
    final description = _concernController.text.trim();

    // Analyze content using enhanced client-side checking
    final analysis = _analyzeText(description);
    final isSuspicious = analysis['isSuspicious'] ?? false;
    final suspicionScore = analysis['score'] ?? 0.0;
    final matchedPatterns = analysis['matchedPatterns'] ?? [];

    if (isSuspicious) {
      String message =
          'Your report contains content that appears to be inappropriate or spam-like '
          '(suspicion score: ${(suspicionScore * 100).toStringAsFixed(1)}%).';

      if (matchedPatterns.isNotEmpty) {
        message += '\n\nDetected patterns: ${matchedPatterns.join(', ')}';
      }

      message +=
          '\n\nAre you sure you want to submit this report? False reports may have consequences.';

      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suspicious Content Detected'),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SUBMIT ANYWAY'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) {
        setState(() => _isSubmitting = false);
        return;
      }
    }

    final incidentData = {
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
      'suspicionScore': suspicionScore,
      'requiresReview': isSuspicious,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      if (matchedPatterns.isNotEmpty) 'matchedPatterns': matchedPatterns,
      // 👇 add initial timeline for tracker screen
      'statusUpdates': [
        {
          'status': isSuspicious ? 'Under Review' : 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
          'note': 'Report submitted',
        }
      ],
    };

    // Add incident first (without statusUpdates)
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
        'suspicionScore': suspicionScore,
        'requiresReview': isSuspicious,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        if (matchedPatterns.isNotEmpty) 'matchedPatterns': matchedPatterns,
      });

      // Safely update statusUpdates as an array
      await docRef.update({
        'statusUpdates': FieldValue.arrayUnion([
          {
            'status': isSuspicious ? 'Under Review' : 'Pending',
            'timestamp': Timestamp.now(), // ✅ Use Firestore Timestamp, not serverTimestamp()
            'note': 'Report submitted',
          }
        ])
      });


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

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your contact number';
    final cleaned = v.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^09\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 11-digit phone starting with 09';
    }
    return null;
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
                      colors: [
                        _primaryColor,
                        _primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.report_problem,
                        size: 100,
                        color: Colors.white,
                      ),
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
                                    Icon(
                                      Icons.report_problem_outlined,
                                      size: 48,
                                      color: _primaryColor,
                                    ),
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
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
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
                              _buildTextField(
                                controller: _addressController,
                                label: 'Address',
                                icon: Icons.location_on_outlined,
                                validator: 'Please enter your address',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNonEditableField(
                                      controller: _latitudeController,
                                      label: 'Latitude',
                                      icon: Icons.my_location,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildNonEditableField(
                                      controller: _longitudeController,
                                      label: 'Longitude',
                                      icon: Icons.my_location,
                                    ),
                                  ),
                                ],
                              ),
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
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: _primaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                ),
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _incidentType,
                                decoration: InputDecoration(
                                  labelText: 'Incident Type',
                                  prefixIcon: Icon(
                                    Icons.warning_amber_outlined,
                                    color: _primaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 16,
                                  ),
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                ),
                                dropdownColor: Colors.white,
                                items: _incidentTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _incidentType = v),
                                validator: (v) => v == null
                                    ? 'Please select an incident type'
                                    : null,
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
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
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSubmitting
                                        ? Colors.grey.shade400
                                        : _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: _primaryColor.withOpacity(0.3),
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'SUBMIT REPORT',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
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

  Widget _buildNonEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        fillColor: Colors.grey.shade100,
        filled: true,
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
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
      validator: (v) => v == null || v.isEmpty
          ? 'Please describe the incident in detail'
          : null,
    );
  }
}