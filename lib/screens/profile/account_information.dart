import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_radar_app/screens/profile/edit_account_info.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:intl/intl.dart';
import 'package:project_radar_app/widgets/capitalize_names.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return {};

    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return {};

    final data = userDoc.data() as Map<String, dynamic>;

    Map<String, dynamic>? safeMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final residentMap = safeMap(data['residentAddress']);
    final workMap = safeMap(data['workAddress']);
    final homeMap = safeMap(data['homeAddress']);
    final schoolMap = safeMap(data['schoolAddress']);

    String photoUrl = '';
    if ((data['photoURL'] ?? '').toString().isNotEmpty) {
      photoUrl = data['photoURL'].toString();
    } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      photoUrl = user.photoURL!;
    }

    final createdAt = data['createdAt'];

    return {
      'firstName': data['firstName'] ?? '',
      'middleName': data['middleName'] ?? '',
      'lastName': data['lastName'] ?? '',
      'email': (data['email'] ?? user.email ?? '').toString(),
      'phone': data['phone'] ?? 'Not provided',
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'photoURL': photoUrl,
      'dob': data['dob'] ?? '',
      'address': data['address'] ?? '',
      'bloodType': data['bloodType'] ?? '',
      'height': data['height'] ?? '',
      'weight': data['weight'] ?? '',
      'userCategory': (data['userCategory'] ?? '').toString(),
      'residentAddress': residentMap,
      'workAddress': workMap,
      'homeAddress': homeMap,
      'schoolAddress': schoolMap,
      'idURL': data['idURL'] ?? '',
    };
  }

  String _composeAddressFromMap(Map<String, dynamic>? m, {bool isHomeCitySuffix = false}) {
    if (m == null || m.isEmpty) return '';

    final parts = <String>[];

    bool _containsAnyLabel(String input, List<String> variants) {
      if (input.isEmpty) return false;
      final escaped = variants.map((v) => RegExp.escape(v)).join('|');
      final pattern = RegExp(r'\b(' + escaped + r')\b', caseSensitive: false);
      return pattern.hasMatch(input);
    }

    bool _hasStreetLabel(String input) {
      return _containsAnyLabel(input, [
        'street', 'st', 'st\\.', 'str', 'str\\.', 'road', 'rd', 'rd\\.',
        'avenue', 'ave', 'ave\\.', 'av', 'av\\.', 'boulevard', 'blvd', 'blvd\\.',
        'lane', 'ln', 'ln\\.', 'drive', 'dr', 'dr\\.', 'place', 'pl', 'pl\\.',
        'way', 'highway', 'hwy', 'hwy\\.', 'court', 'ct', 'ct\\.', 'circle',
        'cir', 'cir\\.', 'terrace', 'ter', 'ter\\.'
      ]);
    }

    bool _hasBarangayLabel(String input) {
      return _containsAnyLabel(input, [
        'barangay', 'brgy', 'brgy\\.', 'brg', 'brg\\.', 'bgy', 'bgy\\.', 'pob', 'poblacion'
      ]);
    }

    bool _hasCityLabel(String input) {
      return _containsAnyLabel(input, [
        'city', 'city\\.', 'municipality', 'mun', 'mun\\.', 'municipal', 'town', 'town\\.'
      ]);
    }

    final schoolName = (m['schoolName'] ?? '').toString().trim();
    if (schoolName.isNotEmpty) parts.add(schoolName);

    final house = (m['house'] ?? '').toString().trim();
    final street = (m['street'] ?? '').toString().trim();

    String streetDisplay = '';
    if (street.isNotEmpty) {
      if (_hasStreetLabel(street)) {
        streetDisplay = street;
      } else {
        streetDisplay = '$street Street';
      }
    }

    if (house.isNotEmpty && streetDisplay.isNotEmpty) {
      parts.add('$house, $streetDisplay');
    } else if (house.isNotEmpty) {
      parts.add(house);
    } else if (streetDisplay.isNotEmpty) {
      parts.add(streetDisplay);
    }

    final barangay = (m['barangay'] ?? '').toString().trim();
    if (barangay.isNotEmpty) {
      if (_hasBarangayLabel(barangay)) {
        parts.add(barangay);
      } else {
        parts.add('Barangay $barangay');
      }
    }

    final town = (m['town'] ?? '').toString().trim();
    if (town.isNotEmpty) parts.add(town);

    final cityKeys = ['city', 'municipality', 'cityMunicipality', 'city_municipality', 'homeCity', 'workCity', 'schoolCity'];
    String foundCity = '';
    for (final k in cityKeys) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isNotEmpty) {
        foundCity = v;
        break;
      }
    }

    if (foundCity.isNotEmpty) {
      if (isHomeCitySuffix && !_hasCityLabel(foundCity)) {
        foundCity = '$foundCity City';
      }
      if (parts.isEmpty || parts.last != foundCity) {
        parts.add(foundCity);
      }
    }

    final zip = (m['zip'] ?? '').toString().trim();
    if (zip.isNotEmpty) parts.add(zip);

    final country = (m['country'] ?? '').toString().trim();
    if (country.isNotEmpty) parts.add(country);

    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }

  String _formatCreatedAt(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) dt = ts.toDate();
      else if (ts is DateTime) dt = ts;
      else dt = DateTime.now();
      return DateFormat('MMMM d, y').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Account Information',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF28588B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF28588B)),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _userData = _fetchUserData()),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!;
          final parts = [
            userData['firstName'],
            userData['middleName'],
            userData['lastName'],
          ];
          final fullName = parts
              .where((part) => part != null && part.toString().trim().isNotEmpty)
              .join(' ');

          final joinedDate = _formatCreatedAt(userData['createdAt']);
          final fallbackAddress = (userData['address'] ?? '').toString().trim();
          
          String phoneDisplay = userData['phone']?.toString() ?? 'Not provided';
          if (phoneDisplay.startsWith('+63')) phoneDisplay = '0' + phoneDisplay.substring(3);

          final bottomInset = MediaQuery.of(context).viewInsets.bottom + 
                            MediaQuery.of(context).padding.bottom + 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
            child: Column(
              children: [
                _buildProfileHeader(context, userData),
                const SizedBox(height: 24),
                _buildAccountInfoCard(
                  context,
                  capitalizeName(fullName),
                  userData['email']?.toString() ?? '',
                  phoneDisplay,
                  userData['dob']?.toString() ?? '',
                  fallbackAddress,
                  userData['bloodType']?.toString() ?? '',
                  userData['height']?.toString() ?? '',
                  userData['weight']?.toString() ?? '',
                  joinedDate,
                  userData,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    const primaryColor = Color(0xFF28588B);
    final String photoUrl = (userData['photoURL'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 3),
                ),
                child: ClipOval(
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/profile_placeholder.png',
                              width: 94,
                              height: 94,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/profile_placeholder.png',
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const EditAccountinfo()),
                    );
                    if (result == true) {
                      setState(() => _userData = _fetchUserData());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            capitalizeName('${userData['firstName']} ${userData['lastName']}'),
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w600, 
              color: Colors.black87
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userData['email']?.toString() ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(
    BuildContext context,
    String fullName,
    String email,
    String phone,
    String dob,
    String fallbackAddress,
    String bloodType,
    String height,
    String weight,
    String joinedDate,
    Map<String, dynamic> userData,
  ) {
    final category = (userData['userCategory'] ?? '').toString().toUpperCase();
    final displayCategory = category.isNotEmpty
        ? (category.length == 1
            ? category.toUpperCase()
            : category[0].toUpperCase() + category.substring(1).toLowerCase())
        : '';

    final residentMap = userData['residentAddress'] is Map
        ? Map<String, dynamic>.from(userData['residentAddress'])
        : null;
    final workMap = userData['workAddress'] is Map
        ? Map<String, dynamic>.from(userData['workAddress'])
        : null;
    final homeMap = userData['homeAddress'] is Map
        ? Map<String, dynamic>.from(userData['homeAddress'])
        : null;
    final schoolMap = userData['schoolAddress'] is Map
        ? Map<String, dynamic>.from(userData['schoolAddress'])
        : null;

    final List<Widget> addressWidgets = [];

    if (category == 'RESIDENT') {
      final addrText = (residentMap != null && residentMap.isNotEmpty)
          ? _composeAddressFromMap(residentMap)
          : (fallbackAddress.isNotEmpty ? fallbackAddress : '--');
      addressWidgets.addAll([
        _buildInfoTile(context, icon: Icons.home_outlined, label: 'Address', value: addrText),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ]);
    } else if (category == 'STUDENT') {
      if (schoolMap != null && schoolMap.isNotEmpty) {
        final schoolText = _composeAddressFromMap(schoolMap);
        addressWidgets.addAll([
          _buildInfoTile(context, icon: Icons.school_outlined, label: 'School Address', value: schoolText.isNotEmpty ? schoolText : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ]);
      }
      if (homeMap != null && homeMap.isNotEmpty) {
        final homeText = _composeAddressFromMap(homeMap, isHomeCitySuffix: true);
        addressWidgets.addAll([
          _buildInfoTile(context, icon: Icons.home_outlined, label: 'Home Address', value: homeText.isNotEmpty ? homeText : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ]);
      }
      if (addressWidgets.isEmpty) {
        addressWidgets.addAll([
          _buildInfoTile(context, icon: Icons.home_outlined, label: 'Address', value: fallbackAddress.isNotEmpty ? fallbackAddress : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ]);
      }
    } else if (category == 'EMPLOYEE') {
      if (workMap != null && workMap.isNotEmpty) {
        final workText = _composeAddressFromMap(workMap);
        addressWidgets.addAll([
          _buildInfoTile(context, icon: Icons.work_outline, label: 'Work Address', value: workText.isNotEmpty ? workText : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ]);
      }
      if (homeMap != null && homeMap.isNotEmpty) {
        final homeText = _composeAddressFromMap(homeMap, isHomeCitySuffix: true);
        addressWidgets.addAll([
          _buildInfoTile(context, icon: Icons.home_outlined, label: 'Home Address', value: homeText.isNotEmpty ? homeText : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ]);
      }
      if (addressWidgets.isEmpty) {
        addressWidgets.addAll([
          _buildInfoTile(context, icon: Icons.home_outlined, label: 'Address', value: fallbackAddress.isNotEmpty ? fallbackAddress : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ]);
      }
    } else {
      addressWidgets.addAll([
        _buildInfoTile(context, icon: Icons.home_outlined, label: 'Address', value: fallbackAddress.isNotEmpty ? fallbackAddress : '--'),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ]);
    }

    final String idUrl = (userData['idURL'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category tile
          _buildInfoTile(
            context,
            icon: Icons.category_outlined,
            label: 'Category',
            value: displayCategory.isNotEmpty ? displayCategory : '-',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          _buildInfoTile(context, icon: Icons.person_outline, label: 'Full Name', value: fullName),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(context, icon: Icons.email_outlined, label: 'Email', value: email),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(context, icon: Icons.phone_outlined, label: 'Phone', value: phone),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(context, icon: Icons.cake_outlined, label: 'Date of Birth', value: dob.isNotEmpty ? dob : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),

          if (idUrl.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        idUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) {
                          return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Uploaded ID',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap View to open full-size ID',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF28588B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          insetPadding: const EdgeInsets.all(20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 600),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: const Text('ID Photo'),
                                  backgroundColor: const Color(0xFF28588B),
                                  automaticallyImplyLeading: false,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Image.network(
                                      idUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Text('Unable to load ID image'),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],

          ...addressWidgets,

          _buildInfoTile(context, icon: Icons.water_drop_outlined, label: 'Blood Type', value: bloodType.isNotEmpty ? bloodType : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(context, icon: Icons.height, label: 'Height', value: height.isNotEmpty ? height : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(context, icon: Icons.monitor_weight, label: 'Weight', value: weight.isNotEmpty ? weight : '--'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoTile(context, icon: Icons.calendar_today, label: 'Joined Date', value: joinedDate),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    const primaryColor = Color(0xFF28588B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  showCursor: true,
                  cursorWidth: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}