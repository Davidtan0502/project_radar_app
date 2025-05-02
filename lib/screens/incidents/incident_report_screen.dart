import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isSubmitting = false;

  final CollectionReference _incidentsCollection = FirebaseFirestore.instance
      .collection('incidents');

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
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      // Name
      final first = data['firstName'] as String? ?? '';
      final last = data['lastName'] as String? ?? '';
      _nameController.text = [first, last].where((s) => s.isNotEmpty).join(' ');

      // Phone: convert +63XXXXXXXXXX to 09XXXXXXXXX
      String phone = data['phone'] as String? ?? '';
      if (phone.startsWith('+63') && phone.length == 13) {
        phone = '0${phone.substring(3)}';
      }
      _cellphoneController.text = phone;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
            backgroundColor: Colors.red,
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
        final addr =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
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
    // Keep name & phone since loaded
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final incidentData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'contactNumber': _cellphoneController.text.trim(),
        'incidentType':
            _incidentType == 'Other'
                ? _otherIncidentTypeController.text.trim()
                : _incidentType,
        'description': _concernController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'latitude': double.tryParse(_latitudeController.text),
        'longitude': double.tryParse(_longitudeController.text),
      };
      await _incidentsCollection.add(incidentData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident report submitted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _resetForm();
      await Future.delayed(Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: _primaryColor,
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: 1,
                  child: Text(
                    'Incident Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                background: Container(
                  color: _primaryColor,
                  child: Center(
                    child: Opacity(
                      opacity: 0.2,
                      child: Icon(
                        Icons.report_problem,
                        size: 80,
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
                builder:
                    (_, __) => Padding(
                      padding: EdgeInsets.all(24),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report an Incident',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please fill out all fields to submit your report',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                SizedBox(height: 24),
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  validator: 'Please enter your name',
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _addressController,
                                  label: 'Address',
                                  icon: Icons.location_on_outlined,
                                  validator: 'Please enter your address',
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildNonEditableField(
                                        controller: _latitudeController,
                                        label: 'Latitude',
                                        icon: Icons.my_location,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _buildNonEditableField(
                                        controller: _longitudeController,
                                        label: 'Longitude',
                                        icon: Icons.my_location,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _landmarkController,
                                  label: 'Landmark',
                                  icon: Icons.place_outlined,
                                  validator: 'Please enter a nearby landmark',
                                ),
                                SizedBox(height: 16),
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
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: _primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                  ),
                                  validator: _validatePhone,
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _incidentType,
                                  decoration: InputDecoration(
                                    labelText: 'Incident Type',
                                    prefixIcon: Icon(
                                      Icons.warning_amber_outlined,
                                      color: _primaryColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: _primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 16,
                                    ),
                                  ),
                                  items:
                                      _incidentTypes
                                          .map(
                                            (type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (v) => setState(() => _incidentType = v),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Please select an incident type'
                                              : null,
                                ),
                                if (_incidentType == 'Other') ...[
                                  SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _otherIncidentTypeController,
                                    label: 'Specify Incident Type',
                                    icon: Icons.edit_outlined,
                                    validator:
                                        'Please specify the incident type',
                                  ),
                                ],
                                SizedBox(height: 16),
                                _buildConcernField(),
                                SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _isSubmitting
                                              ? Colors.grey
                                              : _primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        _isSubmitting
                                            ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                              ),
                                            )
                                            : Text(
                                              'SUBMIT REPORT',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
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
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    validator: (v) => v == null || v.isEmpty ? validator : null,
  );

  Widget _buildNonEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) => TextFormField(
    controller: controller,
    enabled: false,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      fillColor: Colors.grey.shade100,
      filled: true,
    ),
  );

  Widget _buildConcernField() => TextFormField(
    controller: _concernController,
    maxLines: 5,
    decoration: InputDecoration(
      labelText: 'Detailed Description',
      alignLabelWithHint: true,
      prefixIcon: Icon(Icons.description_outlined, color: _primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
    validator:
        (v) =>
            v == null || v.isEmpty
                ? 'Please describe the incident in detail'
                : null,
  );
}
