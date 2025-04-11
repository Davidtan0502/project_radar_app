import 'package:flutter/material.dart';

class VerifyInfoScreen extends StatelessWidget {
  final String lastName;
  final String firstName;
  final String middleInitial;
  final String email;
  final String phone;
  final String password;

  const VerifyInfoScreen({
    super.key,
    required this.lastName,
    required this.firstName,
    required this.middleInitial,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Information'),
        backgroundColor: const Color(0xFF336699),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInfoTile("Last Name", lastName),
                _buildInfoTile("First Name", firstName),
                _buildInfoTile("M.I ", middleInitial),
                _buildInfoTile("Email", email),
                _buildInfoTile("Phone", "+63$phone"),
                _buildInfoTile("Password", '*' * password.length),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registered!')),
                      );
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF336699),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Confirm and Continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(221, 238, 236, 236),
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
            width: 100,
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
