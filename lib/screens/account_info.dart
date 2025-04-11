import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountInfo extends StatefulWidget {
  const AccountInfo({super.key});

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  File? _profileImage;
  File? _idImage;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedImage.path);
        } else {
          _idImage = File(pickedImage.path);
        }
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radarBlue = const Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Information',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: radarBlue,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                              )
                              as ImageProvider,
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
              const SizedBox(height: 20),
              _buildSectionTitle('Personal Information'),
              _buildEditableField(
                'First Name',
                _firstNameController,
                hint: 'John',
              ),
              _buildEditableField(
                'Middle Name',
                _middleNameController,
                hint: 'Felix',
              ),
              _buildEditableField(
                'Last Name',
                _lastNameController,
                hint: 'Doe',
              ),
              _buildEditableField(
                'Email',
                _emailController,
                keyboardType: TextInputType.emailAddress,
                hint: 'yourname@example.com',
              ),
              _buildEditableField(
                'Phone Number',
                _phoneController,
                keyboardType: TextInputType.phone,
                hint: '+63 xxxxxxxxxx',
              ),
              _buildEditableField(
                'Date of Birth',
                _dobController,
                hint: 'January 1, 1990',
              ),
              _buildEditableField(
                'Address',
                _addressController,
                hint: '123 Main St, Manila City, Philippines',
              ),
              const SizedBox(height: 10),
              _buildSectionTitle('ID Upload'),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery, false),
                child:
                    _idImage != null
                        ? Image.file(_idImage!, height: 150)
                        : Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(child: Text('Tap to upload ID')),
                        ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Health Information'),
              _buildEditableField(
                'Blood Type',
                _bloodTypeController,
                hint: 'O+',
              ),
              _buildEditableField('Height', _heightController, hint: '170 cm'),
              _buildEditableField('Weight', _weightController, hint: '65 kg'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: radarBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
