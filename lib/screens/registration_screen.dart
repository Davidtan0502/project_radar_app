import 'package:flutter/material.dart';
import 'verify_info_screen.dart'; // Make sure this is correctly imported

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleInitialController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: const Color(0xFF336699),
      end: const Color(0xFF5588CC),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2)); // Simulate network call

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful!')),
    );

    Navigator.pop(context); // Go back to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            color: _colorAnimation.value,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              "Create an Account",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, offset: Offset(0, -3), blurRadius: 6),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                _lastNameController,
                                                'Last Name',
                                                Icons.person,
                                                validator: (val) {
                                                  if (val == null || val.trim().isEmpty) {
                                                    return 'Enter last name';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildTextField(
                                                _firstNameController,
                                                'First Name',
                                                Icons.person_outline,
                                                validator: (val) {
                                                  if (val == null || val.trim().isEmpty) {
                                                    return 'Enter first name';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Make the M.I. field a little larger and ensure it fits properly
                                            SizedBox(
                                              width: 80, // Increase width if necessary
                                              child: _buildTextField(
                                                _middleInitialController,
                                                'M.I.',
                                                Icons.text_fields,
                                                validator: (val) {
                                                  if (val == null || val.isEmpty || val.length > 1) {
                                                    return '1 letter';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _emailController,
                                        'Email',
                                        Icons.email,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (val) {
                                          if (val == null || !val.contains('@')) {
                                            return 'Enter valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _phoneController,
                                        'Phone Number',
                                        Icons.phone,
                                        keyboardType: TextInputType.phone,
                                        validator: (val) {
                                          if (val == null || val.length != 10) {
                                            return 'Enter 10-digit number';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _passwordController,
                                        'Password',
                                        Icons.lock,
                                        obscureText: true,
                                        validator: (val) {
                                          if (val == null || val.length < 6) {
                                            return 'At least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _confirmPasswordController,
                                        'Confirm Password',
                                        Icons.lock_outline,
                                        obscureText: true,
                                        validator: (val) {
                                          if (val != _passwordController.text) {
                                            return 'Passwords don’t match';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                if (_formKey.currentState!.validate()) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => VerifyInfoScreen(
                                                        lastName: _lastNameController.text,
                                                        firstName: _firstNameController.text,
                                                        middleInitial: _middleInitialController.text,
                                                        email: _emailController.text,
                                                        phone: _phoneController.text,
                                                        password: _passwordController.text,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                        child: _isLoading
                                            ? const CircularProgressIndicator()
                                            : const Text('Register'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}
