import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _currentPasswordController.addListener(() {
      if (_currentPasswordError != null &&
          _currentPasswordController.text.isEmpty) {
        setState(() => _currentPasswordError = null);
      }
    });

    _newPasswordController.addListener(() {
      if (_newPasswordError != null && _newPasswordController.text.isEmpty) {
        setState(() => _newPasswordError = null);
      }
    });

    _confirmPasswordController.addListener(() {
      if (_confirmPasswordError != null &&
          _confirmPasswordController.text.isEmpty) {
        setState(() => _confirmPasswordError = null);
      }
    });
  }

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
    VoidCallback toggle, {
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: const Color(0xFF28588B).withOpacity(0.8),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF28588B),
        fontWeight: FontWeight.w600,
      ),
      hintText: 'Enter your $label',
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF28588B), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      suffixIcon: Container(
        margin: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: Icon(
            visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: toggle,
        ),
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    setState(() {
      _isLoading = true;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not found or not logged in.');
      }

      // Verify current password by attempting to sign in
      try {
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (e) {
        throw Exception('The current password you entered is incorrect.');
      }

      // Update password
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password. Please try again.');
      }

      // Clear fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Password changed successfully!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        final errorMessage = e.toString();
        
        if (errorMessage.contains('incorrect') || 
            errorMessage.contains('Invalid login credentials')) {
          _currentPasswordError = 'The current password you entered is incorrect.';
        } else if (errorMessage.contains('weak') || 
                   errorMessage.contains('Password should be at least')) {
          _newPasswordError = 'The new password is too weak. Use at least 6 characters.';
        } else if (errorMessage.contains('network') || 
                   errorMessage.contains('Connection')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Network error. Please check your connection.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      });
      
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenHeight * 0.08;
    final sidePadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Matching ProfileScreen style
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF3F73A3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: headerHeight * 0.3,
                horizontal: sidePadding,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Security Message Container - Separated from header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3F73A3).withOpacity(0.05),
                    const Color(0xFF28588B).withOpacity(0.03)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Security icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28588B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF28588B),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Security message
                  const Text(
                    'Secure your account with a new password',
                    style: TextStyle(
                      color: Color(0xFF28588B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Password Requirements Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF28588B).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF28588B).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: const Color(0xFF28588B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Password Requirements',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF28588B),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRequirement('At least 6 characters long'),
                            _buildRequirement('One uppercase letter'),
                            _buildRequirement('One number'),
                            _buildRequirement('One special character'),
                          ],
                        ),
                      ),

                      // Current Password Field
                      const Text(
                        'Current Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: !_showCurrentPassword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          'Current Password',
                          _showCurrentPassword,
                          () => setState(
                            () => _showCurrentPassword = !_showCurrentPassword,
                          ),
                          errorText: _currentPasswordError,
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Enter your current password';
                          }
                          if (_currentPasswordError != null) {
                            return _currentPasswordError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // New Password Field
                      const Text(
                        'New Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: !_showNewPassword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          'New Password',
                          _showNewPassword,
                          () => setState(
                            () => _showNewPassword = !_showNewPassword,
                          ),
                          errorText: _newPasswordError,
                        ),
                        validator: (value) {
                          final val = value?.trim() ?? '';
                          if (val.isEmpty) return 'Enter a new password';
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
                          if (!regex.hasMatch(val)) {
                            return 'Must contain 1 uppercase letter, numbers & special characters';
                          }

                          if (_newPasswordError != null) return _newPasswordError;
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      const Text(
                        'Confirm New Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          'Confirm New Password',
                          _showConfirmPassword,
                          () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          errorText: _confirmPasswordError,
                        ),
                        validator: (value) {
                          final val = value?.trim() ?? '';
                          if (val.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (val != _newPasswordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          if (_confirmPasswordError != null) {
                            return _confirmPasswordError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 36),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28588B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xFF28588B).withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_reset_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Update Password',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF28588B).withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}