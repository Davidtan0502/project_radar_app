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

  // Resident address
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _residentTownController = TextEditingController();
  String? _selectedTown;
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _cityController =
      TextEditingController(text: "Manila City");
  final TextEditingController _countryController =
      TextEditingController(text: "Philippines");

  // Work address (Employee)
  final TextEditingController _workStreetController =
      TextEditingController();
  final TextEditingController _workBarangayController =
      TextEditingController();
  final TextEditingController _workTownController =
      TextEditingController();
  String? _selectedWorkTown;
  final TextEditingController _workZipController = TextEditingController();
  final TextEditingController _workCityController =
      TextEditingController(text: "Manila City");
  final TextEditingController _workCountryController =
      TextEditingController(text: "Philippines");

  // Home address (for Employee and Student)
  final TextEditingController _homeHouseController = TextEditingController();
  final TextEditingController _homeStreetController = TextEditingController();
  final TextEditingController _homeBarangayController =
      TextEditingController();
  final TextEditingController _homeTownController =
      TextEditingController();
  String? _selectedHomeTown;
  final TextEditingController _homeZipController = TextEditingController();
  final TextEditingController _homeCityController =
      TextEditingController();
  final TextEditingController _homeCountryController =
      TextEditingController(text: "Philippines");

  // Student school address
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolStreetController =
      TextEditingController();
  final TextEditingController _schoolBarangayController =
      TextEditingController();
  final TextEditingController _schoolTownController =
      TextEditingController();
  String? _selectedSchoolTown;
  final TextEditingController _schoolZipController = TextEditingController();
  final TextEditingController _schoolCityController =
      TextEditingController(text: "Manila City");
  final TextEditingController _schoolCountryController =
      TextEditingController(text: "Philippines");

  bool _hasMiddleName = false;
  String _selectedCategory = "RESIDENT";

  final List<String> _towns = [
    "Tondo",
    "Binondo",
    "Quiapo",
    "Intramuros",
    "Ermita",
    "Malate",
    "Paco",
    "Pandacan",
    "Port Area",
    "San Nicolas",
    "Santa Ana",
    "Santa Cruz",
    "Santa Mesa",
    "San Miguel",
    "San Andres Bukid",
    "Sampaloc",
  ];

  bool _showWorkTownManual = false;
  bool _showSchoolTownManual = false;

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
    addTitleListener(_residentTownController);
    addTitleListener(_cityController);
    addTitleListener(_workStreetController);
    addTitleListener(_workBarangayController);
    addTitleListener(_workTownController);
    addTitleListener(_workCityController);
    addTitleListener(_homeHouseController);
    addTitleListener(_homeStreetController);
    addTitleListener(_homeBarangayController);
    addTitleListener(_homeTownController);
    addTitleListener(_homeCityController);
    addTitleListener(_schoolNameController);
    addTitleListener(_schoolStreetController);
    addTitleListener(_schoolBarangayController);
    addTitleListener(_schoolTownController);
    addTitleListener(_schoolCityController);
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
    _residentTownController.dispose();
    _workStreetController.dispose();
    _workBarangayController.dispose();
    _workTownController.dispose();
    _workZipController.dispose();
    _workCityController.dispose();
    _workCountryController.dispose();
    _homeHouseController.dispose();
    _homeStreetController.dispose();
    _homeBarangayController.dispose();
    _homeTownController.dispose();
    _homeZipController.dispose();
    _homeCityController.dispose();
    _homeCountryController.dispose();
    _schoolNameController.dispose();
    _schoolStreetController.dispose();
    _schoolBarangayController.dispose();
    _schoolTownController.dispose();
    _schoolZipController.dispose();
    _schoolCityController.dispose();
    _schoolCountryController.dispose();
    super.dispose();
  }

  String _toTitleCase(String input) {
    if (input.trim().isEmpty) return input;

    // Split on whitespace to preserve words
    final parts = input.split(RegExp(r'\s+'));

    final transformed = parts.map((word) {
      if (word.isEmpty) return '';

      // Handle hyphenated subwords (e.g. "jay-anne" -> "Jay-Anne")
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

  void _submitRegistration() {
    if (!_formKey.currentState!.validate()) return;

    final residentAddress = _buildResidentAddress();
    final workAddress = _buildWorkAddress();
    final homeAddress = _buildHomeAddress();
    final schoolAddress = _buildSchoolAddress();

    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyInfoScreen(
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _hasMiddleName ? _middleNameController.text.trim() : "",
          email: _emailController.text.trim().toLowerCase(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          userCategory: _selectedCategory,
          residentAddress: _selectedCategory == "RESIDENT" ? residentAddress : null,
          workAddress: _selectedCategory == "EMPLOYEE" ? workAddress : null,
          homeAddress: (_selectedCategory == "EMPLOYEE" || _selectedCategory == "STUDENT")
              ? homeAddress
              : null,
          schoolAddress: _selectedCategory == "STUDENT" ? schoolAddress : null,
          onConfirm: () {
            // This will be called when user confirms in VerifyInfoScreen
            _createAccount(
              residentAddress: residentAddress,
              workAddress: workAddress,
              homeAddress: homeAddress,
              schoolAddress: schoolAddress,
            );
          },
          onEdit: () {
            // User wants to edit - just go back
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _createAccount({
    required Map<String, dynamic>? residentAddress,
    required Map<String, dynamic>? workAddress,
    required Map<String, dynamic>? homeAddress,
    required Map<String, dynamic>? schoolAddress,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      
      debugPrint('Starting registration for: $email');

      // ✅ FIXED: Sign up with ALL metadata that the trigger needs
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'type': 'app', // This tells the trigger to create app_users record
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'middle_name': _hasMiddleName ? _middleNameController.text.trim() : null,
          'phone': _phoneController.text.trim().isNotEmpty 
              ? '+63${_phoneController.text.trim()}' 
              : null,
          'user_category': _selectedCategory,
          'resident_address': _selectedCategory == "RESIDENT" ? residentAddress : null,
          'work_address': _selectedCategory == "EMPLOYEE" ? workAddress : null,
          'home_address': (_selectedCategory == "EMPLOYEE" || _selectedCategory == "STUDENT")
              ? homeAddress
              : null,
          'school_address': _selectedCategory == "STUDENT" ? schoolAddress : null,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account in Auth');
      }

      debugPrint('Auth user created: ${authResponse.user!.id}');
      debugPrint('Session exists: ${authResponse.session != null}');
      debugPrint('User email: ${authResponse.user!.email}');

      // The trigger should now automatically create the app_users record
      // Let's wait a moment and verify the record was created
      await Future.delayed(const Duration(seconds: 2));

      // Verify the app_users record was created by the trigger
      try {
        final userRecord = await supabase
            .from('app_users')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        debugPrint('app_users record created by trigger: ${userRecord['id']}');
      } catch (e) {
        debugPrint('Trigger may not have created app_users record yet: $e');
      }

      if (!mounted) return;
      
      // Show success message
      _showSuccessDialog();

    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      final errorMsg = _getAuthErrorMessage(e);
      setState(() => _errorMessage = errorMsg);
      _showErrorDialog(errorMsg);
    } catch (e, stackTrace) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Show generic error
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
            const Text(
              'You will be automatically redirected back to the app after verification.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.blue,
                height: 1.4,
              ),
            ),
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

  Map<String, dynamic> _buildResidentAddress() {
    return {
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'barangay': _barangayController.text.trim(),
      'town': _residentTownController.text.trim(),
      'zip': _zipController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildWorkAddress() {
    return {
      'street': _workStreetController.text.trim(),
      'barangay': _workBarangayController.text.trim(),
      'town': (_selectedWorkTown != null && _selectedWorkTown != 'Other')
          ? _selectedWorkTown
          : _workTownController.text.trim(),
      'zip': _workZipController.text.trim(),
      'city': _workCityController.text.trim(),
      'country': _workCountryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildHomeAddress() {
    return {
      'house': _homeHouseController.text.trim(),
      'street': _homeStreetController.text.trim(),
      'barangay': _homeBarangayController.text.trim(),
      'town': _selectedHomeTown ?? _homeTownController.text.trim(),
      'zip': _homeZipController.text.trim(),
      'city': _homeCityController.text.trim(),
      'country': _homeCountryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildSchoolAddress() {
    return {
      'school_name': _schoolNameController.text.trim(),
      'street': _schoolStreetController.text.trim(),
      'barangay': _schoolBarangayController.text.trim(),
      'town': (_selectedSchoolTown != null && _selectedSchoolTown != 'Other')
          ? _selectedSchoolTown
          : _schoolTownController.text.trim(),
      'zip': _schoolZipController.text.trim(),
      'city': _schoolCityController.text.trim(),
      'country': _schoolCountryController.text.trim(),
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
        labelText: label,
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
        labelText: 'Phone Number',
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
        labelText: label,
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

  //Dropdown Field
  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Icon(
            Icons.category,
            color: Color(0xFF336699),
            size: 20,
          ),
        ),
      ),
      validator: validator,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Color(0xFF336699),
      ),
    );
  }

  //Town Dropdown Field
  Widget _buildTownDropdownField({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required String? Function(String?)? validator,
    bool showOtherOption = false,
  }) {
    final dropdownItems = showOtherOption 
        ? [...items, 'Other']
        : items;

    return DropdownButtonFormField<String>(
      value: value,
      items: dropdownItems.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Icon(
            Icons.location_city,
            color: Color(0xFF336699),
            size: 20,
          ),
        ),
      ),
      validator: validator,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Color(0xFF336699),
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

                                      // CATEGORY dropdown
                                      _buildDropdownField(
                                        value: _selectedCategory,
                                        items: const ["RESIDENT", "EMPLOYEE", "STUDENT"],
                                        onChanged: (val) => setState(() { _selectedCategory = val ?? "RESIDENT"; }),
                                        label: "Category",
                                        validator: (val) => val == null ? 'Please select a category' : null,
                                      ),

                                      const SizedBox(height: 16),

                                      _buildTextField(
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
                                      const SizedBox(height: 12),
                                      _buildTextField(
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
                                            if (val == null || val.trim().isEmpty) {
                                              return 'Enter middle name';
                                            }
                                            final pattern = RegExp(r"^[A-Za-z\s\.'-]+$");
                                            if (!pattern.hasMatch(val.trim())) {
                                              return 'Enter a valid middle name';
                                            }
                                            return null;
                                          },
                                        ),
                                      if (_hasMiddleName) const SizedBox(height: 12),

                                      _buildTextField(
                                        _emailController,
                                        'Email',
                                        Icons.email,
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

                                      // RESIDENT Address
                                      if (_selectedCategory == "RESIDENT") ...[
                                        const Text(
                                          "Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),

                                        _buildTextField(_houseController, "House/Unit/Building No.", Icons.home,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_streetController, "Street Name", Icons.location_on,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter street name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_barangayController, "Barangay/Subdivision", Icons.location_city,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // Resident Town dropdown
                                        _buildTownDropdownField(
                                          value: _selectedTown ?? (_residentTownController.text.isNotEmpty ? _residentTownController.text : null),
                                          items: _towns,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedTown = val;
                                              if (val != null) _residentTownController.text = val;
                                            });
                                          },
                                          label: "Town",
                                          validator: (val) {
                                            final townVal = _selectedTown ?? _residentTownController.text;
                                            if (townVal == null || townVal.trim().isEmpty) return 'Select town';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_zipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_cityController, "City/Municipality", Icons.location_city, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_countryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                      ],

                                      // EMPLOYEE Address
                                      if (_selectedCategory == "EMPLOYEE") ...[
                                        const Text(
                                          "Work Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workStreetController, "Street/Building No.", Icons.business, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter work street/building';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workBarangayController, "Barangay/Subdivision", Icons.map, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter work barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // Work town dropdown
                                        _buildTownDropdownField(
                                          value: _selectedWorkTown ?? (_workTownController.text.isNotEmpty ? _workTownController.text : null),
                                          items: _towns,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedWorkTown = val;
                                              _showWorkTownManual = val == 'Other';
                                              if (val != null && val != 'Other') _workTownController.text = val;
                                            });
                                          },
                                          label: "Town",
                                          validator: null,
                                          showOtherOption: true,
                                        ),
                                        const SizedBox(height: 12),

                                        if (_showWorkTownManual || (_selectedWorkTown == null && _workTownController.text.isNotEmpty))
                                          Column(
                                            children: [
                                              _buildTextField(_workTownController, "Type Town", Icons.edit, validator: (_) => null),
                                              const SizedBox(height: 12),
                                            ],
                                          ),

                                        _buildTextField(_workZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workCityController, "City/Municipality", Icons.location_city, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 20),

                                        const Text(
                                          "Home Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeHouseController, "House/Unit/Building No.", Icons.home, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeStreetController, "Street Name", Icons.location_on, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter street name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeBarangayController, "Barangay/Subdivision", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          _homeTownController,
                                          "Town (Optional)",
                                          Icons.location_city,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCityController, "City/Municipality", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter city/municipality';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                      ],

                                      // STUDENT Address
                                      if (_selectedCategory == "STUDENT") ...[
                                        const Text(
                                          "School Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolNameController, "Full School Name", Icons.school, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter full school name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolStreetController, "Street Name", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter school street/building';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolBarangayController, "Barangay/Subdivision", Icons.map, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter school barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // School town dropdown
                                        _buildTownDropdownField(
                                          value: _selectedSchoolTown ?? (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null),
                                          items: _towns,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedSchoolTown = val;
                                              _showSchoolTownManual = val == 'Other';
                                              if (val != null && val != 'Other') _schoolTownController.text = val;
                                            });
                                          },
                                          label: "Town",
                                          validator: null,
                                          showOtherOption: true,
                                        ),
                                        const SizedBox(height: 12),

                                        if (_showSchoolTownManual || (_selectedSchoolTown == null && _schoolTownController.text.isNotEmpty))
                                          Column(
                                            children: [
                                              _buildTextField(_schoolTownController, "Type Town", Icons.edit, validator: (_) => null),
                                              const SizedBox(height: 12),
                                            ],
                                          ),

                                        _buildTextField(_schoolZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolCityController, "City/Municipality", Icons.location_city, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 20),

                                        const Text(
                                          "Home Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeHouseController, "House/Unit/Building No.", Icons.home, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeStreetController, "Street Name", Icons.location_on, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter street name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeBarangayController, "Barangay/Subdivision", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          _homeTownController,
                                          "Town (Optional)",
                                          Icons.location_city,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCityController, "City/Municipality", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter city/municipality';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                      ],

                                      const SizedBox(height: 24),
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
