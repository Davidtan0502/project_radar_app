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

  final TextEditingController _firstNameController = TextEditingController(text: 'John');
  final TextEditingController _middleNameController = TextEditingController(text: 'Felix');
  final TextEditingController _lastNameController = TextEditingController(text: 'Doe');
  final TextEditingController _emailController = TextEditingController(text: 'john.doe@example.com');
  final TextEditingController _phoneController = TextEditingController(text: '+1234567890');
  final TextEditingController _dobController = TextEditingController(text: 'January 1, 1990');
  final TextEditingController _addressController = TextEditingController(text: '123 Main St, Manila City, Philippines');
  final TextEditingController _bloodTypeController = TextEditingController(text: 'O+');
  final TextEditingController _heightController = TextEditingController(text: '170 cm');
  final TextEditingController _weightController = TextEditingController(text: '65 kg');

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Information', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
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
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Personal Information'),
              _buildEditableField('First Name', _firstNameController),
              _buildEditableField('Middle Name', _middleNameController),
              _buildEditableField('Last Name', _lastNameController),
              _buildEditableField('Email', _emailController, keyboardType: TextInputType.emailAddress),
              _buildEditableField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
              _buildEditableField('Date of Birth', _dobController),
              _buildEditableField('Address', _addressController),
              const SizedBox(height: 10),
              _buildSectionTitle('ID Upload'),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery, false),
                child: _idImage != null
                    ? Image.file(_idImage!, height: 150)
                    : Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(child: Text('Tap to upload ID')),
                      ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Health Information'),
              _buildEditableField('Blood Type', _bloodTypeController),
              _buildEditableField('Height', _heightController),
              _buildEditableField('Weight', _weightController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
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

  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
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
