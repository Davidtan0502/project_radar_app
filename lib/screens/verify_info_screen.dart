import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/registration_screen.dart';

class VerifyInfoScreen extends StatelessWidget {
  final String lastName;
  final String firstName;
  final String middleInitial;
  final String email;
  final String phone;
  final String password;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const VerifyInfoScreen({
    super.key,
    required this.lastName,
    required this.firstName,
    required this.middleInitial,
    required this.email,
    required this.phone,
    required this.password,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Information'),
        backgroundColor: const Color(0xFF336699),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
            tooltip: 'Edit Information',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Please confirm your details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Admin will review your information and contact you shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                _buildInfoTile("Last Name", lastName),
                _buildInfoTile("First Name", firstName),
                _buildInfoTile("Middle Initial", middleInitial),
                _buildInfoTile("Email", email),
                _buildInfoTile("Phone", "+63$phone"),
                _buildInfoTile("Password", '*' * password.length),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF336699),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit for Approval',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}