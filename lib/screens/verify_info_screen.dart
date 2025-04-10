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
      appBar: AppBar(title: const Text('Verify Information')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please verify your information below:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            _buildInfoTile('Name', '$lastName, $firstName ${middleInitial.isNotEmpty ? middleInitial[0] + '.' : ''}'),
            _buildInfoTile('Email', email),
            _buildInfoTile('Phone', '+63 $phone'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add Firebase save logic or navigate to main app screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verified and Registered!')),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst); // or go to MainNavigation()
                },
                child: const Text('Confirm and Continue'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back to Edit'),
            )
          ],
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
