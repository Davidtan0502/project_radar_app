import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'verify_info_screen.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:math'; // <-- added for selection clamping

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  final TextEditingController _houseController = TextEditingController(); // House/Unit
  final TextEditingController _streetController = TextEditingController(); // Street
  final TextEditingController _barangayController = TextEditingController(); // Barangay
  final TextEditingController _residentTownController = TextEditingController(); // Resident town manual storage
  String? _selectedTown; // used for resident dropdown
  final TextEditingController _zipController = TextEditingController(); // Resident ZIP
  final TextEditingController _cityController =
      TextEditingController(text: "Manila City"); // read-only for resident
  final TextEditingController _countryController =
      TextEditingController(text: "Philippines"); // read-only

  // Work address (Employee)
  final TextEditingController _workStreetController =
      TextEditingController(); // Street/Building for work
  final TextEditingController _workBarangayController =
      TextEditingController();
  final TextEditingController _workTownController =
      TextEditingController(); // manual town fallback if user types
  String? _selectedWorkTown; // dropdown selection for work
  final TextEditingController _workZipController = TextEditingController();
  final TextEditingController _workCityController =
      TextEditingController(); // now editable (manual)
  final TextEditingController _workCountryController =
      TextEditingController(text: "Philippines"); // read-only

  // Home address (for Employee and Student)
  final TextEditingController _homeHouseController = TextEditingController();
  final TextEditingController _homeStreetController = TextEditingController();
  final TextEditingController _homeBarangayController =
      TextEditingController();
  final TextEditingController _homeTownController =
      TextEditingController(); // manual town for home (optional)
  String? _selectedHomeTown; // kept for compatibility but UI uses manual controller
  final TextEditingController _homeZipController = TextEditingController();
  final TextEditingController _homeCityController =
      TextEditingController(); // manual and required for Employee/Student
  final TextEditingController _homeCountryController =
      TextEditingController(text: "Philippines"); // read-only

  // Student school address
  final TextEditingController _schoolNameController = TextEditingController(); // School name
  final TextEditingController _schoolStreetController =
      TextEditingController(); // Street/building
  final TextEditingController _schoolBarangayController =
      TextEditingController();
  final TextEditingController _schoolTownController =
      TextEditingController(); // manual town fallback if user types
  String? _selectedSchoolTown; // dropdown selection for school
  final TextEditingController _schoolZipController = TextEditingController();
  final TextEditingController _schoolCityController =
      TextEditingController(); // now editable (manual)
  final TextEditingController _schoolCountryController =
      TextEditingController(text: "Philippines"); // read-only

  bool _hasMiddleName = false; // NEW: middle name optional checkbox

  // NEW: use short tokens for categories
  // valid values: 'RESIDENT', 'EMPLOYEE', 'STUDENT'
  String _selectedCategory = "RESIDENT"; // default

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

  // control flags for showing manual town input for employee/student
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

    // Initialize work/school city defaults (keeps previous default but editable)
    _workCityController.text = "Manila City";
    _schoolCityController.text = "Manila City";

    // -------------------------------
    // New: listeners to auto Title-Case many manual text fields (EXCEPT email/phone/password/zip)
    // Apply Title Case to: names, address text fields, town and city manual fields, school name, etc.
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

    // Name fields
    addTitleListener(_lastNameController);
    addTitleListener(_firstNameController);
    addTitleListener(_middleNameController);

    // Resident address textual fields (not ZIP)
    addTitleListener(_houseController);
    addTitleListener(_streetController);
    addTitleListener(_barangayController);
    addTitleListener(_residentTownController);
    addTitleListener(_cityController); // city readOnly by default but safe to have

    // Work address textual fields
    addTitleListener(_workStreetController);
    addTitleListener(_workBarangayController);
    addTitleListener(_workTownController);
    addTitleListener(_workCityController);

    // Home address textual fields
    addTitleListener(_homeHouseController);
    addTitleListener(_homeStreetController);
    addTitleListener(_homeBarangayController);
    addTitleListener(_homeTownController);
    addTitleListener(_homeCityController);

    // School address textual fields
    addTitleListener(_schoolNameController);
    addTitleListener(_schoolStreetController);
    addTitleListener(_schoolBarangayController);
    addTitleListener(_schoolTownController);
    addTitleListener(_schoolCityController);
    // -------------------------------
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

    // NEW: dispose all new controllers
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

  // Helper: convert input to Title Case (each word first letter uppercase, rest lowercase)
  String _toTitleCase(String input) {
    if (input.trim().isEmpty) return input;
    final parts = input.split(RegExp(r'\s+'));
    final transformed = parts.map((word) {
      if (word.isEmpty) return '';
      final first = word.substring(0, 1).toUpperCase();
      final rest = word.length > 1 ? word.substring(1).toLowerCase() : '';
      return first + rest;
    }).join(' ');
    return transformed;
  }

  // NEW: improved email validation (accepts subdomains like stamesa.sti.edu.ph)
  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[\w\.-]+@[A-Za-z0-9.-]+\.(edu\.ph|org\.ph|edu|com|net|org|gov|ph)$',
      caseSensitive: false,
    );
    return regex.hasMatch(email);
  }

  // Validate and defer registration until confirmation
  void _submitRegistration() {
    if (!_formKey.currentState!.validate()) return;

    // build the address maps here (same as in _createAccount)
    final residentAddress = {
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'barangay': _barangayController.text.trim(),
      'town': _residentTownController.text.trim(),
      'zip': _zipController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
    };

    final workAddress = {
      'street': _workStreetController.text.trim(),
      'barangay': _workBarangayController.text.trim(),
      // prefer dropdown unless 'Other' selected or dropdown null then fallback to manual controller
      'town': (_selectedWorkTown != null && _selectedWorkTown != 'Other')
          ? _selectedWorkTown
          : _workTownController.text.trim(),
      'zip': _workZipController.text.trim(),
      'city': _workCityController.text.trim(),
      'country': _workCountryController.text.trim(),
    };

    final homeAddress = {
      'house': _homeHouseController.text.trim(),
      'street': _homeStreetController.text.trim(),
      'barangay': _homeBarangayController.text.trim(),
      'town': _selectedHomeTown ?? _homeTownController.text.trim(),
      'zip': _homeZipController.text.trim(),
      'city': _homeCityController.text.trim(),
      'country': _homeCountryController.text.trim(),
    };

    final schoolAddress = {
      'schoolName': _schoolNameController.text.trim(),
      'street': _schoolStreetController.text.trim(),
      'barangay': _schoolBarangayController.text.trim(),
      'town': (_selectedSchoolTown != null && _selectedSchoolTown != 'Other')
          ? _selectedSchoolTown
          : _schoolTownController.text.trim(),
      'zip': _schoolZipController.text.trim(),
      'city': _schoolCityController.text.trim(),
      'country': _schoolCountryController.text.trim(),
    };

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
          // PASS only the maps relevant to the chosen category; others are null
          residentAddress: _selectedCategory == "RESIDENT" ? residentAddress : null,
          workAddress: _selectedCategory == "EMPLOYEE" ? workAddress : null,
          homeAddress: (_selectedCategory == "EMPLOYEE" || _selectedCategory == "STUDENT")
              ? homeAddress
              : null,
          schoolAddress: _selectedCategory == "STUDENT" ? schoolAddress : null,
          onConfirm: () {},
          onEdit: () {},
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _createAccount();
      }
    });
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already registered',
        );
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      // Send verification email, but don't let a failure stop the flow entirely.
      try {
        await userCredential.user!.sendEmailVerification();
        debugPrint('Verification email sent to $email');
      } catch (e) {
        debugPrint('Error sending verification email: $e');
        // still continue to create the Firestore record below
      }

      // NEW: Build address maps to store in Firestore
      final residentAddress = {
        'house': _houseController.text.trim(),
        'street': _streetController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'town': _residentTownController.text.trim(), // uses controller (synced from dropdown)
        'zip': _zipController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
      };

      final workAddress = {
        'street': _workStreetController.text.trim(),
        'barangay': _workBarangayController.text.trim(), // <-- FIXED: was using street controller before
        // prefer dropdown selection (unless 'Other'), fallback to text controller
        'town': (_selectedWorkTown != null && _selectedWorkTown != 'Other')
            ? _selectedWorkTown
            : _workTownController.text.trim(),
        'zip': _workZipController.text.trim(),
        'city': _workCityController.text.trim(),
        'country': _workCountryController.text.trim(),
      };

      final homeAddress = {
        'house': _homeHouseController.text.trim(),
        'street': _homeStreetController.text.trim(),
        'barangay': _homeBarangayController.text.trim(),
        'town': _selectedHomeTown ?? _homeTownController.text.trim(),
        'zip': _homeZipController.text.trim(),
        'city': _homeCityController.text.trim(),
        'country': _homeCountryController.text.trim(),
      };

      final schoolAddress = {
        'schoolName': _schoolNameController.text.trim(),
        'street': _schoolStreetController.text.trim(),
        'barangay': _schoolBarangayController.text.trim(),
        'town': (_selectedSchoolTown != null && _selectedSchoolTown != 'Other')
            ? _selectedSchoolTown
            : _schoolTownController.text.trim(),
        'zip': _schoolZipController.text.trim(),
        'city': _schoolCityController.text.trim(),
        'country': _schoolCountryController.text.trim(),
      };

      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'middleName': _hasMiddleName ? _middleNameController.text.trim() : "",
        'email': email,
        'phone': '+63${_phoneController.text.trim()}',
        'password': _passwordController.text.trim(), // <-- NOTE: storing plaintext password is insecure
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'userCategory': _selectedCategory,
        // store conditional addresses
        if (_selectedCategory == "RESIDENT") 'residentAddress': residentAddress,
        if (_selectedCategory == "EMPLOYEE") 'workAddress': workAddress,
        if (_selectedCategory == "EMPLOYEE" || _selectedCategory == "STUDENT")
          'homeAddress': homeAddress,
        if (_selectedCategory == "STUDENT") 'schoolAddress': schoolAddress,
      };

      // store user record
      final uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set(userData);

      // IMPORTANT: sign out the newly-created user so auth-state listeners
      // won't navigate to Home while the email is unverified.
      try {
        await _auth.signOut();
        debugPrint('Signed out newly created user to prevent auto-navigation to Home.');
      } catch (e) {
        debugPrint('Error signing out after registration: $e');
      }

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      Flushbar(
        message:
            'Verification email sent. Please check your inbox and verify your email to login.',
        duration: const Duration(seconds: 8),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: const Color.fromARGB(255, 25, 167, 0),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return 'Registration failed. Please try again.';
    }
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
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                      // CATEGORY dropdown (replaced ChoiceChips)
                                      DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        items: const [
                                          DropdownMenuItem(value: "RESIDENT", child: Text("RESIDENT")),
                                          DropdownMenuItem(value: "EMPLOYEE", child: Text("EMPLOYEE")),
                                          DropdownMenuItem(value: "STUDENT", child: Text("STUDENT")),
                                        ],
                                        onChanged: (val) => setState(() { _selectedCategory = val ?? "RESIDENT"; }),
                                        decoration: InputDecoration(
                                          labelText: "Category",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      _buildTextField(
                                        _lastNameController,
                                        'Last Name',
                                        Icons.person,
                                        validator: (val) {
                                          if (val == null ||
                                              val.trim().isEmpty) {
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
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return 'Enter first name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // NEW: Optional middle name checkbox (keeps layout)
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _hasMiddleName,
                                            onChanged: (val) =>
                                                setState(() => _hasMiddleName = val!),
                                          ),
                                          const Text("I have a middle name"),
                                        ],
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
                                            // simple name pattern — adjust if needed
                                            final pattern = RegExp(r"^[A-Za-z\s\.'-]+$");
                                            if (!pattern.hasMatch(val.trim())) {
                                              return 'Enter a valid middle name';
                                            }
                                            return null;
                                          },
                                        ),
                                      const SizedBox(height: 12),

                                      _buildTextField(
                                        _emailController,
                                        'Email',
                                        Icons.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (val) {
                                          if (val == null ||
                                              val.isEmpty ||
                                              !_isValidEmail(val)) {
                                            return 'Enter valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Please enter your contact number';
                                          }
                                          // Must be exactly 10 digits, all numeric, and start with 9
                                          final digitsOnly = val.trim();
                                          if (!RegExp(
                                            r'^[9]\d{9}$',
                                          ).hasMatch(digitsOnly)) {
                                            return 'Enter a valid 10-digit number starting with 9';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                                horizontal: 16,
                                              ),
                                          prefixIcon: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Image(
                                                  image: AssetImage(
                                                    'assets/ph_flag.png',
                                                  ),
                                                  width: 24,
                                                  height: 24,
                                                ),
                                                SizedBox(width: 8),
                                                Text('+63'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Password is required';
                                          }
                                          if (val.length < 6) {
                                            return 'At least 6 characters';
                                          }
                                          // Must contain letters, numbers, and special characters
                                          final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
                                          if (!regex.hasMatch(val)) {
                                            return 'Include letters, numbers, and special characters';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            ),
                                            onPressed: () => setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            }),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: !_isConfirmPasswordVisible,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Confirm Password is required';
                                          }
                                          if (val != _passwordController.text) {
                                            return 'Passwords don\'t match';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isConfirmPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isConfirmPasswordVisible =
                                                    !_isConfirmPasswordVisible;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                                horizontal: 16,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // RESIDENT only: Address header + resident address (shown only for RESIDENT)
                                      if (_selectedCategory == "RESIDENT") ...[
                                        const Text("Address", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),

                                        _buildTextField(_houseController, "House/Unit/Building No.", Icons.home,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_streetController, "Street Name", Icons.aod,
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

                                        // Resident Town as dropdown (required)
                                        DropdownButtonFormField<String>(
                                          value: _selectedTown ?? (_residentTownController.text.isNotEmpty ? _residentTownController.text : null),
                                          items: _towns.map((town) => DropdownMenuItem(value: town, child: Text(town))).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedTown = val;
                                              if (val != null) _residentTownController.text = val; // keep existing storage logic unchanged
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Town",
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          ),
                                          validator: (val) {
                                            final townVal = _selectedTown ?? _residentTownController.text;
                                            if (townVal == null || townVal.trim().isEmpty) return 'Select town';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        // Resident ZIP (4 digits)
                                        _buildTextField(_zipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // City & Country as non-editable textboxes (read-only)
                                        _buildTextField(_cityController, "City/Municipality", Icons.location_city, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_countryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                      ] else
                                        const SizedBox.shrink(),

                                      // Employee: Work Address block (street/building, barangay, town dropdown+optional manual, zip, city editable, country)
                                      if (_selectedCategory == "EMPLOYEE") ...[
                                        const Text("Work Address", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
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

                                        // Work town dropdown (optional). Includes "Other" to allow manual input.
                                        DropdownButtonFormField<String>(
                                          value: _selectedWorkTown ?? (_workTownController.text.isNotEmpty ? _workTownController.text : null),
                                          items: [
                                            ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
                                            const DropdownMenuItem(value: 'Other', child: Text('Other (type manually)')),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedWorkTown = val;
                                              // when Other chosen, show manual input; otherwise sync manual controller for convenience
                                              _showWorkTownManual = val == 'Other';
                                              if (val != null && val != 'Other') _workTownController.text = val;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Town",
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          ),
                                          // optional: don't force selection
                                          validator: (val) {
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Manual town input shown only when user selects 'Other' or types directly
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

                                        // Work city: now editable (manual)
                                        _buildTextField(_workCityController, "City/Municipality", Icons.location_city, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 16),

                                        // Employee: Home Address block
                                        const Text("Home Address", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
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
                                        // Home town is manual text input (optional)
                                        _buildTextField(
                                          _homeTownController,
                                          "Town (Optional)",
                                          Icons.location_city,
                                          validator: (val) {
                                            // Town optional
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        // Home city remains MANUAL and REQUIRED
                                        _buildTextField(_homeCityController, "City/Municipality", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter city/municipality';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                      ],

                                      // Student: School Address + Home Address
                                      if (_selectedCategory == "STUDENT") ...[
                                        const Text("School Address", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        // School name
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

                                        // School town dropdown (optional + "Other")
                                        DropdownButtonFormField<String>(
                                          value: _selectedSchoolTown ?? (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null),
                                          items: [
                                            ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
                                            const DropdownMenuItem(value: 'Other', child: Text('Other (type manually)')),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedSchoolTown = val;
                                              _showSchoolTownManual = val == 'Other';
                                              if (val != null && val != 'Other') _schoolTownController.text = val;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: "Town",
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          ),
                                          validator: (val) {
                                            // optional
                                            return null;
                                          },
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
                                        // School city now editable (manual)
                                        _buildTextField(_schoolCityController, "City/Municipality", Icons.location_city, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 16),

                                        const Text("Home Address", style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
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
                                        // Home town manual input for students as well — optional
                                        _buildTextField(
                                          _homeTownController,
                                          "Town (Optional)",
                                          Icons.location_city,
                                          validator: (val) {
                                            // Town is optional
                                            return null;
                                          },
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
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  // keep your original helper but add readOnly parameter (NEW)
  // Replace your current _buildTextField with this safer version:
  Widget _buildTextField(
    TextEditingController? controller, // allow nullable now
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    // If controller is null that's fine — TextFormField accepts null and will manage its own internal controller.
    // We keep behavior identical otherwise.
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }
}
