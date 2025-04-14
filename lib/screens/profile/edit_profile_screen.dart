import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/profile/account_management_screen.dart';
import 'package:project_radar_app/services/navigation.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radarBlue = const Color(0xFF1565C0);

    return WillPopScope(
      onWillPop: () async {
        Navigation.pushReplacement(context, const AccountManagementScreen());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigation.pushReplacement(context, const AccountManagementScreen());
            },
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.grey[100],
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField('Name', _nameController, hint: 'John Doe'),
                const SizedBox(height: 16),
                _buildTextField(
                  'Email', 
                  _emailController, 
                  hint: 'email@example.com', 
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Phone', 
                  _phoneController, 
                  hint: '09123456789', 
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: radarBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Changes', 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigation.pushReplacement(context, const AccountManagementScreen());
    }
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, {
    String? hint, 
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }
}