import 'package:flutter/material.dart';

class VerifyInfoScreen extends StatefulWidget {
  final String lastName;
  final String firstName;
  final String middleName;
  final String email;
  final String phone;
  final String password;
  final String? userCategory;
  final Map<String, dynamic>? residentAddress;
  final Map<String, dynamic>? workAddress;
  final Map<String, dynamic>? homeAddress;
  final Map<String, dynamic>? schoolAddress;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const VerifyInfoScreen({
    super.key,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.email,
    required this.phone,
    required this.password,
    this.userCategory,
    this.residentAddress,
    this.workAddress,
    this.homeAddress,
    this.schoolAddress,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  State<VerifyInfoScreen> createState() => _VerifyInfoScreenState();
}

class _VerifyInfoScreenState extends State<VerifyInfoScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final Color _primaryColor = const Color(0xFF336699);
  final Color _backgroundColor = const Color(0xFFF0F4F8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _colorAnimation = ColorTween(
      begin: const Color(0xFF336699),
      end: const Color(0xFF5588CC),
    ).animate(_animationController);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleEdit() {
    widget.onEdit();
    Navigator.pushReplacementNamed(context, '/register');
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    try {
      // Call the onConfirm callback which will trigger _createAccount
      widget.onConfirm();

      // Wait a bit to show loading state
      await Future.delayed(const Duration(milliseconds: 500));

      // Don't pop - let the success dialog handle navigation
    } catch (e) {
      setState(() => _isLoading = false);
      // Error will be handled in _createAccount
    }
  }

  /// Improved capitalization (kept in file for other uses)
  String _capitalizeEachWord(String value) {
    if (value.trim().isEmpty) return value;

    final words = value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

    List<String> processedWords = [];

    final delimRegex = RegExp(r"([-'\u2019])"); // hyphen, ascii apostrophe, unicode right single quote

    for (final w in words) {
      final parts = w.split(delimRegex);
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isEmpty) continue;
        if (part.length == 1 && delimRegex.hasMatch(part)) {
          processedWords.add(part);
        } else {
          final first = part[0].toUpperCase();
          final rest = part.length > 1 ? part.substring(1).toLowerCase() : '';
          processedWords.add('$first$rest');
        }
      }

      final nonEmptyPartsCount = parts.where((p) => p.isNotEmpty).length;
      final lastTokens = processedWords.sublist(processedWords.length - nonEmptyPartsCount);
      final rebuilt = lastTokens.join();
      processedWords.removeRange(processedWords.length - nonEmptyPartsCount, processedWords.length);
      processedWords.add(rebuilt);
    }

    return processedWords.join(' ');
  }

  String _friendlyCategory(String? token) {
    if (token == null) return '';
    final t = token.trim().toUpperCase();
    switch (t) {
      case 'RESIDENT':
        return 'Resident';
      case 'EMPLOYEE':
        return 'Employee';
      case 'STUDENT':
        return 'Student';
      default:
        return _capitalizeEachWord(token.trim());
    }
  }

  String _addr(Map<String, dynamic>? m, String key) {
    if (m == null) return '';
    final val = m[key];
    if (val == null) return '';
    return val.toString();
  }

 Widget _buildAddressBlock(String title, Map<String, dynamic> map) {
  final parts = <String>[];

  // School name (for student)
  final schoolName = _addr(map, 'school_name');
  if (schoolName.isNotEmpty) parts.add(_capitalizeEachWord(schoolName));

  // House and street
  final house = _addr(map, 'house');
  final street = _addr(map, 'street');
  if (house.isNotEmpty && street.isNotEmpty) {
    final streetText = _capitalizeEachWord(street);
    // Check if "Street" is already in the street field
    if (streetText.toLowerCase().contains('street')) {
      parts.add('${_capitalizeEachWord(house)}, $streetText');
    } else {
      parts.add('${_capitalizeEachWord(house)}, ${streetText} Street');
    }
  } else if (house.isNotEmpty) {
    parts.add(_capitalizeEachWord(house));
  } else if (street.isNotEmpty) {
    final streetText = _capitalizeEachWord(street);
    // Check if "Street" is already in the street field
    if (streetText.toLowerCase().contains('street')) {
      parts.add(streetText);
    } else {
      parts.add('${streetText} Street');
    }
  }

  // Barangay
  final barangay = _addr(map, 'barangay');
  if (barangay.isNotEmpty) {
    final barangayText = _capitalizeEachWord(barangay);
    // Check if "Barangay" is already in the barangay field
    if (barangayText.toLowerCase().contains('barangay')) {
      parts.add(barangayText);
    } else {
      parts.add('Barangay $barangayText');
    }
  }

  // Town
  final town = _addr(map, 'town');
  if (town.isNotEmpty) parts.add(_capitalizeEachWord(town));

  // ZIP
  final zip = _addr(map, 'zip');
  if (zip.isNotEmpty) parts.add('$zip');

  // City
  final city = _addr(map, 'city');
  if (city.isNotEmpty) {
    final cityText = _capitalizeEachWord(city);
    // Check if "City" is already in the city field
    if (cityText.toLowerCase().contains('city')) {
      parts.add(cityText);
    } else {
      parts.add('${cityText} City');
    }
  }

  // Country
  final country = _addr(map, 'country');
  if (country.isNotEmpty) parts.add(_capitalizeEachWord(country));

  final inline = parts.isNotEmpty ? parts.join(', ') : '-';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          inline,
          style: const TextStyle(
            color: Color.fromARGB(221, 11, 11, 11),
            fontSize: 14,
          ),
          softWrap: true,
        ),
      ],
    ),
  );
}

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(221, 11, 11, 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            color: _colorAnimation.value,
            child: SafeArea(
              child: Column(
                children: [
                  // Header with back button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Verify Your Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Icon and Title
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.verified_user_outlined,
                                            size: 48,
                                            color: _primaryColor,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Confirm Your Information',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: _primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    Text(
                                      'Please review all details before submitting',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 24),

                                    // Personal Information Section
                                    Text(
                                      'Personal Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // >>> CHANGED: display Last Name exactly as entered at registration
                                    _buildInfoTile('Last Name', widget.lastName),
                                    const SizedBox(height: 8),

                                    // First Name (kept as-is or you can change to widget.firstName if needed)
                                    _buildInfoTile('First Name', widget.firstName),

                                    if (widget.middleName.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoTile('Middle Name', _capitalizeEachWord(widget.middleName)),
                                    ],
                                    const SizedBox(height: 8),
                                    _buildInfoTile('Email', widget.email),
                                    const SizedBox(height: 8),
                                    _buildInfoTile('Phone', '+63${widget.phone}'),
                                    const SizedBox(height: 8),
                                    _buildInfoTile('Password', '*' * widget.password.length),

                                    if (widget.userCategory != null && widget.userCategory!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildInfoTile('Category', _friendlyCategory(widget.userCategory)),
                                    ],

                                    const SizedBox(height: 24),

                                    // Address Sections
                                    if (widget.residentAddress != null && widget.residentAddress!.isNotEmpty) ...[
                                      Text(
                                        'Resident Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildAddressBlock('Resident Address', widget.residentAddress!),
                                      const SizedBox(height: 16),
                                    ],

                                    if (widget.workAddress != null && widget.workAddress!.isNotEmpty) ...[
                                      Text(
                                        'Work Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildAddressBlock('Work Address', widget.workAddress!),
                                      const SizedBox(height: 16),
                                    ],

                                    if (widget.homeAddress != null && widget.homeAddress!.isNotEmpty) ...[
                                      Text(
                                        'Home Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildAddressBlock('Home Address', widget.homeAddress!),
                                      const SizedBox(height: 16),
                                    ],

                                    if (widget.schoolAddress != null && widget.schoolAddress!.isNotEmpty) ...[
                                      Text(
                                        'School Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildAddressBlock('School Address', widget.schoolAddress!),
                                      const SizedBox(height: 16),
                                    ],

                                    const SizedBox(height: 32),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: _handleEdit,
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              side: BorderSide(color: _primaryColor),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Edit Details',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _handleConfirm,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
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
                                                : Text(
                                                    'Confirm & Submit',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
