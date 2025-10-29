import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_info_screen.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  // Single address for all users
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: "Philippines");

  bool _hasMiddleName = false;
  bool _showAddressFields = false; // New checkbox state

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: const Color(0xFF336699),
      end: const Color(0xFF5588CC),
    ).animate(_controller);

    // Initialize title case listeners
    void addTitleListener(TextEditingController c) {
      c.addListener(() {
        final text = c.text;
        final transformed = _toTitleCase(text);
        if (text != transformed) {
          final sel = c.selection;
          c.value = TextEditingValue(
            text: transformed,
            selection: TextSelection(
              baseOffset: min(max(sel.baseOffset, 0), transformed.length),
              extentOffset: min(max(sel.extentOffset, 0), transformed.length),
            ),
          );
        }
      });
    }

    addTitleListener(_lastNameController);
    addTitleListener(_firstNameController);
    addTitleListener(_middleNameController);
    addTitleListener(_houseController);
    addTitleListener(_streetController);
    addTitleListener(_barangayController);
    addTitleListener(_townController);
    addTitleListener(_cityController);
    addTitleListener(_countryController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _townController.dispose();
    super.dispose();
  }

  String _toTitleCase(String input) {
    if (input.trim().isEmpty) return input;

    // Split on whitespace to preserve words
    final parts = input.split(RegExp(r'\s+'));

    final transformed = parts.map((word) {
      if (word.isEmpty) return '';

      // Handle hyphenated subwords
      final hyphenParts = word.split('-');
      final hyphenTransformed = hyphenParts.map((sub) {
        if (sub.isEmpty) return '';
        final first = sub.substring(0, 1).toUpperCase();
        final rest = sub.length > 1 ? sub.substring(1).toLowerCase() : '';
        return first + rest;
      }).join('-');

      return hyphenTransformed;
    }).join(' ');

    return transformed;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[\w\.-]+@[A-Za-z0-9.-]+\.(edu\.ph|org\.ph|edu|com|net|org|gov|ph)$',
      caseSensitive: false,
    );
    return regex.hasMatch(email);
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final phoneInput = _phoneController.text.trim();

    // Normalize phone number to match Supabase RPC logic
    String normalizePhone(String input) {
      String digits = input.replaceAll(RegExp(r'\D'), '');

      if (digits.startsWith('09')) {
        digits = '63${digits.substring(1)}';
      } else if (digits.startsWith('9')) {
        digits = '63$digits';
      } else if (digits.startsWith('0')) {
        digits = '63${digits.substring(1)}';
      } else if (digits.startsWith('63')) {
        // already normalized
      }

      return digits; // returns "639XXXXXXXXX"
    }

    final normalizedPhone = normalizePhone(phoneInput);

    bool duplicateEmail = false;
    bool duplicatePhone = false;

    try {
      // Check duplicates via Supabase RPC
      final rpcResult = await supabase.rpc(
        'check_user_exists',
        params: {'p_email': email, 'p_phone': normalizedPhone},
      );

      if (rpcResult != null && rpcResult is Map<String, dynamic>) {
        duplicateEmail =
            (rpcResult['auth_email'] == true) || (rpcResult['app_email'] == true);
        duplicatePhone = (rpcResult['app_phone'] == true);
      }
    } catch (e) {
      debugPrint('RPC duplicate check failed: $e');
    }

    // Stop registration if duplicate found
    if (duplicateEmail || duplicatePhone) {
      String message = '';
      if (duplicateEmail && duplicatePhone) {
        message =
            'This email and phone number are already registered. Please use different credentials.';
      } else if (duplicateEmail) {
        message = 'This email is already registered. Please use a different one.';
      } else if (duplicatePhone) {
        message =
            'This phone number is already registered. Please use a different one.';
      }

      _showErrorDialog(message);
      return; // Prevent navigation
    }

    // Continue only if no duplicates
    final address = _buildAddress();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyInfoScreen(
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _hasMiddleName ? _middleNameController.text.trim() : "",
          email: email,
          phone: phoneInput,
          password: _passwordController.text,
          address: address,
          onConfirm: () {
            _createAccount(address: address);
          },
          onEdit: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _createAccount({
    required Map<String, dynamic> address,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final phoneInput = _phoneController.text.trim();

      // Normalize phone number for duplicate checking
      String normalizePhone(String input) {
        String digits = input.replaceAll(RegExp(r'\D'), '');

        if (digits.startsWith('09')) {
          digits = '63${digits.substring(1)}';
        } else if (digits.startsWith('9')) {
          digits = '63$digits';
        } else if (digits.startsWith('0')) {
          digits = '63${digits.substring(1)}';
        } else if (digits.startsWith('63')) {
          // already normalized
        }

        return digits;
      }

      final normalizedPhone = normalizePhone(phoneInput);
      bool duplicateEmail = false;
      bool duplicatePhone = false;

      try {
        // Use the same RPC
        final rpcResult = await supabase.rpc(
          'check_user_exists',
          params: {'p_email': email, 'p_phone': normalizedPhone},
        );

        if (rpcResult != null && rpcResult is Map<String, dynamic>) {
          duplicateEmail =
              (rpcResult['auth_email'] == true) || (rpcResult['app_email'] == true);
          duplicatePhone = (rpcResult['app_phone'] == true);
        }
      } catch (rpcError) {
        debugPrint('check_user_exists RPC failed: $rpcError');
      }

      // Stop if duplicates exist
      if (duplicateEmail || duplicatePhone) {
        String message = '';
        if (duplicateEmail && duplicatePhone) {
          message =
              'This email and phone number are already registered. Please use different credentials.';
        } else if (duplicateEmail) {
          message = 'This email is already registered. Please use a different one.';
        } else if (duplicatePhone) {
          message =
              'This phone number is already registered. Please use a different one.';
        }

        setState(() => _errorMessage = message);
        _showErrorDialog(message);
        return;
      }

      // Proceed with account creation
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'type': 'app',
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'middle_name': _hasMiddleName ? _middleNameController.text.trim() : null,
          'phone': '+$normalizedPhone',
          'user_category': 'RESIDENT', // Set default category
          'address': address,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account in Auth');
      }

      debugPrint('Auth user created: ${authResponse.user!.id}');
      _showSuccessDialog();
    } on AuthException catch (e) {
      final errorMsg = _getAuthErrorMessage(e);
      setState(() => _errorMessage = errorMsg);
      _showErrorDialog(errorMsg);
    } catch (e, stack) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stack');
      _showErrorDialog('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Check Your Email',
          style: TextStyle(
            color: Color(0xFF336699),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration successful!',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a verification email to:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your inbox and click the verification link to activate your account.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF336699),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _removeNullValues(Map<String, dynamic> map) {
    return Map.from(map)..removeWhere((key, value) => value == null);
  }

  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('already registered') || message.contains('user exists')) {
      return 'This email is already registered. Please try logging in or use a different email.';
    } else if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters with letters, numbers, and special characters.';
    } else if (message.contains('rate limit') || message.contains('too many requests')) {
      return 'Too many attempts. Please try again in a few minutes.';
    } else {
      return 'Registration failed: ${e.message}';
    }
  }

  Map<String, dynamic> _buildAddress() {
     if (!_showAddressFields) {
    return {};
  }
    return {
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'barangay': _barangayController.text.trim(),
      'town': _townController.text.trim(),
      'zip': _zipController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
    };
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Registration Error',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF336699),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Text Field
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            icon,
            color: const Color(0xFF336699),
            size: 20,
          ),
        ),
        labelText: label + (isRequired ? ' *' : ''),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  //Phone Field
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please enter your contact number';
        }
        final digitsOnly = val.trim();
        if (!RegExp(r'^[9]\d{9}$').hasMatch(digitsOnly)) {
          return 'Enter a valid 10-digit number starting with 9';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Phone Number *',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/ph_flag.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.flag,
                    color: Color(0xFF336699),
                    size: 20,
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                '+63',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF336699),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Password Field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.lock,
            color: const Color(0xFF336699),
            size: 20,
          ),
        ),
        labelText: label + ' *',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
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
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
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
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, -3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_errorMessage != null)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red.shade600,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 16),

                                      _buildTextField(
                                        _lastNameController,
                                        'Last Name',
                                        Icons.person,
                                        isRequired: true,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Enter last name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _firstNameController,
                                        'First Name',
                                        Icons.person_outline,
                                        isRequired: true,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Enter first name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // Optional middle name checkbox
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _hasMiddleName,
                                              onChanged: (val) =>
                                                  setState(() => _hasMiddleName = val!),
                                              activeColor: const Color(0xFF336699),
                                            ),
                                            const Text(
                                              "I have a middle name",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_hasMiddleName)
                                        _buildTextField(
                                          _middleNameController,
                                          'Middle Name',
                                          Icons.person_outline,
                                          validator: (val) {
                                            if (_hasMiddleName && (val == null || val.trim().isEmpty)) {
                                              return 'Enter middle name';
                                            }
                                            if (val != null && val.trim().isNotEmpty) {
                                              final pattern = RegExp(r"^[A-Za-z\s\.'-]+$");
                                              if (!pattern.hasMatch(val.trim())) {
                                                return 'Enter a valid middle name';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      if (_hasMiddleName) const SizedBox(height: 12),

                                      _buildTextField(
                                        _emailController,
                                        'Email',
                                        Icons.email,
                                        isRequired: true,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (val) {
                                          if (val == null || val.isEmpty || !_isValidEmail(val)) {
                                            return 'Enter valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      _buildPhoneField(),
                                      const SizedBox(height: 12),

                                      _buildPasswordField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        isVisible: _isPasswordVisible,
                                        onToggleVisibility: () => setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        }),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Password is required';
                                          }
                                          if (val.length < 6) {
                                            return 'At least 6 characters';
                                          }
                                          final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
                                          if (!regex.hasMatch(val)) {
                                            return 'Must Contains 1 Uppercase letters, numbers, and special characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildPasswordField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm Password',
                                        isVisible: _isConfirmPasswordVisible,
                                        onToggleVisibility: () => setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        }),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Confirm Password is required';
                                          }
                                          if (val != _passwordController.text) {
                                            return 'Passwords don\'t match';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),

                                      // Address Section with Checkbox
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _showAddressFields,
                                              onChanged: (val) =>
                                                  setState(() => _showAddressFields = val!),
                                              activeColor: const Color(0xFF336699),
                                            ),
                                            const Text(
                                              "Add Address Information",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Address Fields (conditionally displayed)
                                      if (_showAddressFields) ...[
                                        _buildTextField(_houseController, "House/Unit/Building No.", Icons.home,
                                            validator: (val) {
                                          if (_showAddressFields && (val == null || val.trim().isEmpty)) {
                                            return 'House/Unit/Building No. is required';
                                          }
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_streetController, "Street Name", Icons.location_on,
                                            validator: (val) {
                                          if (_showAddressFields && (val == null || val.trim().isEmpty)) {
                                            return 'Street Name is required';
                                          }
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // Town input field (Optional)
                                        _buildTextField(_townController, "Town (Optional)", Icons.location_city,
                                            validator: (val) {
                                          // Town remains optional even when address is required
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // Barangay input field
                                        _buildTextField(_barangayController, "Barangay/Subdivision", Icons.location_city,
                                            validator: (val) {
                                          if (_showAddressFields && (val == null || val.trim().isEmpty)) {
                                            return 'Barangay/Subdivision is required';
                                          }
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // ZIP Code input field
                                        _buildTextField(_zipController, "ZIP Code", Icons.local_post_office,
                                            keyboardType: TextInputType.number,
                                            validator: (val) {
                                          if (_showAddressFields) {
                                            if (val == null || val.trim().isEmpty) {
                                              return 'ZIP Code is required';
                                            }
                                            if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) {
                                              return 'ZIP must be 4 digits';
                                            }
                                          }
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // City input field (now user input)
                                        _buildTextField(_cityController, "City/Municipality", Icons.location_city,
                                            validator: (val) {
                                          if (_showAddressFields && (val == null || val.trim().isEmpty)) {
                                            return 'City/Municipality is required';
                                          }
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        
                                        // Country input field
                                        _buildTextField(_countryController, "Country", Icons.flag, readOnly: true,
                                            validator: (val) {
                                          if (_showAddressFields && (val == null || val.trim().isEmpty)) {
                                            return 'Country is required';
                                          }
                                          return null;
                                        }),
                                        const SizedBox(height: 24),
                                      ],

                                      ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _submitRegistration,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _colorAnimation.value,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24, 
                                                height: 24, 
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2, 
                                                  color: Colors.white
                                                )
                                              )
                                            : const Text(
                                                'Register', 
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                )
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
}