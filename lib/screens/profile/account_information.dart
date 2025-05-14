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
    if (user == null) {
      return {};
    }

    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      return {};
    }

    final data = userDoc.data() as Map<String, dynamic>;
    return {
      'firstName': data['firstName'] ?? '',
      'middleName': data['middleName'] ?? '',
      'lastName': data['lastName'] ?? '',
      'email': user.email ?? '',
      'phone': data['phone'] ?? 'Not provided',
      'createdAt': data['createdAt'] ?? Timestamp.now(),
      'photoURL': user.photoURL ?? '',
      'dob': data['dob'] ?? '',
      'address': data['address'] ?? '',
      'bloodType': data['bloodType'] ?? '',
      'height': data['height'] ?? '',
      'weight': data['weight'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Account Information',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF28588B),
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
                child: Text('Error loading data: ${snapshot.error}'),
              );
            }

            final userData = snapshot.data!;
            final parts = [
              userData['firstName'],
              userData['middleName'],
              userData['lastName'],
            ];
            final fullName = parts
                .where((part) => part != null && part.trim().isNotEmpty)
                .join(' ');

            final joinedDate = DateFormat(
              'MMMM d, y',
            ).format((userData['createdAt'] as Timestamp).toDate());

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(context, userData),
                  const SizedBox(height: 32),
                  _buildAccountInfoCard(
                    context,
                    capitalizeName(fullName),
                    userData['email'],
                    userData['phone'],
                    userData['dob'],
                    userData['address'],
                    userData['bloodType'],
                    userData['height'],
                    userData['weight'],
                    joinedDate,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    const primaryColor = Color(0xFF28588B);

    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage:
                      userData['photoURL'] != null &&
                              userData['photoURL'].isNotEmpty
                          ? NetworkImage(userData['photoURL']) as ImageProvider
                          : const AssetImage(
                            'assets/images/profile_placeholder.png',
                          ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigation.pushReplacement(
                        context,
                        const EditAccountinfo(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            capitalizeName('${userData['firstName']} ${userData['lastName']}'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
    String address,
    String bloodType,
    String height,
    String weight,
    String joinedDate,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildInfoTile(
              context,
              icon: Icons.person_outline,
              label: 'Full Name',
              value: fullName,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phone,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: dob.isNotEmpty ? dob : 'Not provided',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.home_outlined,
              label: 'Address',
              value: address.isNotEmpty ? address : 'Not provided',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.water_drop_outlined,
              label: 'Blood Type',
              value: bloodType.isNotEmpty ? bloodType : 'Not provided',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.height,
              label: 'Height',
              value: height.isNotEmpty ? height : 'Not provided',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.monitor_weight,
              label: 'Weight',
              value: weight.isNotEmpty ? weight : 'Not provided',
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoTile(
              context,
              icon: Icons.calendar_today,
              label: 'Joined Date',
              value: joinedDate,
            ),
          ],
        ),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F0FA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryColor, size: 24),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
