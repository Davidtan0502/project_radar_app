import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_radar_app/screens/profile/account_management_screen.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditAccountinfo extends StatefulWidget {
  const EditAccountinfo({super.key});

  @override
  State<EditAccountinfo> createState() => _EditAccountinfoState();
}

class _EditAccountinfoState extends State<EditAccountinfo> {
  File? _profileImage;
  File? _idImage;
  bool _removeProfileImage = false;
  double? _profileUploadProgress;
  double? _idUploadProgress;
  final _formKey = GlobalKey<FormState>();
  bool _isFormDirty = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFormListeners();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
      _firstNameController.text = data['firstName'] ?? '';
      _middleNameController.text = data['middleName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _addressController.text = data['address'] ?? '';
      _bloodTypeController.text = data['bloodType'] ?? '';
      _heightController.text = data['height'] ?? '';
      _weightController.text = data['weight'] ?? '';
    });
  }

  void _initializeFormListeners() {
    for (final ctrl in [
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _dobController,
      _addressController,
      _bloodTypeController,
      _heightController,
      _weightController,
    ]) {
      ctrl.addListener(_markFormDirty);
    }
  }

  void _markFormDirty() {
    if (!_isFormDirty) setState(() => _isFormDirty = true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToStorage(File imageFile, String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child(path)
        .child('${user.uid}.jpg');
    final uploadTask = ref.putFile(imageFile);
    uploadTask.snapshotEvents.listen((event) {
      double progress = event.bytesTransferred / event.totalBytes;
      setState(() {
        if (path.contains('profile_images'))
          _profileUploadProgress = progress;
        else
          _idUploadProgress = progress;
      });
    });
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;
    setState(() {
      if (isProfile) {
        _profileImage = File(picked.path);
        _removeProfileImage = false;
      } else {
        _idImage = File(picked.path);
      }
      _markFormDirty();
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? profileUrl;
    if (_removeProfileImage) {
      try {
        await FirebaseStorage.instance
            .ref('profile_images/${user.uid}.jpg')
            .delete();
      } catch (_) {}
    } else if (_profileImage != null) {
      profileUrl = await _uploadImageToStorage(
        _profileImage!,
        'profile_images',
      );
    }

    String? idUrl;
    if (_idImage != null) {
      idUrl = await _uploadImageToStorage(_idImage!, 'id_uploads');
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await docRef.set({
      'firstName': _firstNameController.text.trim(),
      'middleName': _middleNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
      'address': _addressController.text.trim(),
      'bloodType': _bloodTypeController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      if (profileUrl != null) 'photoURL': profileUrl,
      if (idUrl != null) 'idURL': idUrl,
      'isVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() => _isFormDirty = false);
    Navigator.pop(context);
  }

  Future<bool> _confirmUnsavedChanges() async {
    if (!_isFormDirty) return true;
    final discard =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                title: const Text('Unsaved Changes'),
                content: const Text(
                  'You have unsaved changes. Discard them and go back?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Discard',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    return discard;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radarBlue = const Color(0xFF1565C0);

    return WillPopScope(
      onWillPop: _confirmUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: radarBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmUnsavedChanges()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.grey[100],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildProfileImageSection(),
                const SizedBox(height: 20),
                _buildPersonalInfoSection(),
                const SizedBox(height: 20),
                _buildIdUploadSection(),
                const SizedBox(height: 20),
                _buildHealthInfoSection(), // <--- optional fields
                const SizedBox(height: 30),
                _buildSaveButton(radarBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery, true),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _profileImage != null
                          ? FileImage(_profileImage!)
                          : const NetworkImage(
                            'https://via.placeholder.com/150',
                          ),
                  child:
                      _profileImage == null
                          ? const Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.white70,
                          )
                          : null,
                ),
              ),
              if (_profileImage != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _pickImage(ImageSource.gallery, true),
                  ),
                ),
            ],
          ),
          if (_profileImage != null || !_removeProfileImage)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _removeProfileImage = true;
                  _profileImage = null;
                  _markFormDirty();
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information'),
        _buildEditableField('First Name', _firstNameController, hint: 'John'),
        _buildEditableField(
          'Middle Name',
          _middleNameController,
          hint: 'Felix',
        ),
        _buildEditableField('Last Name', _lastNameController, hint: 'Doe'),
        _buildEditableField(
          'Email',
          _emailController,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        _buildEditableField(
          'Phone Number',
          _phoneController,
          hint: '09123456789',
          keyboardType: TextInputType.phone,
        ),
        _buildEditableField(
          'Date of Birth',
          _dobController,
          hint: 'January 1, 1990',
        ),
        _buildEditableField('Address', _addressController, hint: '123 Main St'),
      ],
    );
  }

  Widget _buildIdUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ID Upload'),
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery, false),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child:
                _idImage != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_idImage!, fit: BoxFit.cover),
                    )
                    : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40),
                          Text('Tap to upload ID'),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Health Information'),
        // Now **optional**: no validator here
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _bloodTypeController,
            decoration: InputDecoration(
              labelText: 'Blood Type',
              hintText: 'O+',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: 'Height',
              hintText: '170 cm',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight',
              hintText: '65 kg',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color backgroundColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator:
            (value) =>
                (value == null || value.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }
}
