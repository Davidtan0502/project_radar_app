import 'package:flutter/material.dart';

/// A confirmation screen that displays the user's input
class VerifyInfoScreen extends StatefulWidget {
  final String lastName;
  final String firstName;
  final String middleName;
  final String email;
  final String phone;
  final String password;

  const VerifyInfoScreen({
    super.key,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.email,
    required this.phone,
    required this.password,
    required Null Function() onConfirm,
    required Null Function() onEdit,
  });

  @override
  State<VerifyInfoScreen> createState() => _VerifyInfoScreenState();
}

class _VerifyInfoScreenState extends State<VerifyInfoScreen> {
  bool _isLoading = false;

  /// Pops with `false` to signal "edit".
  void _handleEdit() {
    Navigator.pop(context, false);
  }

  /// Pops with `true` to signal "confirm".
  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Details'),
        backgroundColor: const Color(0xFF336699),
        automaticallyImplyLeading: false,
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
                const SizedBox(height: 16),
                _buildInfoTile('Last Name', widget.lastName),
                _buildInfoTile('First Name', widget.firstName),
                _buildInfoTile('Middle Name', widget.middleName),
                _buildInfoTile('Email', widget.email),
                _buildInfoTile('Phone', '+63${widget.phone}'),
                _buildInfoTile('Password', '*' * widget.password.length),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF336699)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF336699),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF336699),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
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
            child: Text(
              value,
              style: const TextStyle(color: Color.fromARGB(221, 11, 11, 11)),
            ),
          ),
        ],
      ),
    );
  }
}
