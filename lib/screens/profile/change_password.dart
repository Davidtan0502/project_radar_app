import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_radar_app/screens/profile/account_management_screen.dart';
import 'package:project_radar_app/services/navigation.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(
    String label,
    bool visible,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF28588B)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF28588B), width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
        ),
        onPressed: toggle,
      ),
    );
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;

      if (user == null || user.email == null) {
        throw FirebaseAuthException(
            code: 'no-user', message: 'User not found or not logged in.');
      }

      // Re-authenticate the user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(newPassword);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to AccountManagementScreen
      if (context.mounted) {
        Navigation.pushReplacement(context, const AccountManagementScreen());
      }
    } on FirebaseAuthException catch (e) {
      String error = 'Failed to change password.';
      if (e.code == 'wrong-password') {
        error = 'Current password is incorrect.';
      } else if (e.code == 'weak-password') {
        error = 'New password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 30, left: 20, right: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F73A3), Color(0xFF28588B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigation.pushReplacement(context, const AccountManagementScreen());
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update your password below:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: !_showCurrentPassword,
                      decoration: _buildInputDecoration(
                        'Current Password',
                        _showCurrentPassword,
                        () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your current password' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      decoration: _buildInputDecoration(
                        'New Password',
                        _showNewPassword,
                        () => setState(() => _showNewPassword = !_showNewPassword),
                      ),
                      validator: (value) =>
                          value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: _buildInputDecoration(
                        'Confirm New Password',
                        _showConfirmPassword,
                        () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28588B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}