import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'package:project_radar_app/screens/profile/edit_profile_screen.dart';
import 'package:project_radar_app/screens/profile/emergency_contacts_screen.dart';
import 'package:project_radar_app/screens/profile/help_and_support.dart';
import 'package:project_radar_app/screens/profile/settings_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/widgets/capitalize_names.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _firstName = '';
  String _lastName = '';
  String _photoURL = '';
  bool _isVerified = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _firstName = capitalizeName(doc.data()?['firstName'] ?? '');
            _lastName = capitalizeName(doc.data()?['lastName'] ?? '');
            _isVerified = doc.data()?['isVerified'] ?? false;
            _photoURL = user.photoURL ?? '';
            _email = user.email ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            final displayName = user.displayName ?? '';
            _firstName = displayName.split(' ').isNotEmpty
                ? capitalize(displayName.split(' ').first)
                : 'User';
            _lastName = displayName.split(' ').length > 1
                ? capitalize(displayName.split(' ').last)
                : '';
            _isVerified = user.emailVerified;
            _photoURL = user.photoURL ?? '';
            _email = user.email ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading user data: $e');
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen(onTap: () {})),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '$_firstName $_lastName'.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F73A3), Color(0xFF28588B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 15),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Profile Section (Messenger-style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: const Icon(Icons.account_circle, size: 120),
                        )
                      : _photoURL.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                _photoURL,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_circle,
                                  size: 120,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(Icons.account_circle, size: 120, color: Colors.grey),
                ),

                const SizedBox(height: 16),

                // Name with verification badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 180,
                          height: 28,
                          color: Colors.white,
                        ),
                      )
                    else
                      Text(
                        fullName.isNotEmpty ? fullName : 'Guest User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                    if (!_isLoading && _isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Email
                if (_isLoading)
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 200,
                      height: 16,
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 4),
                    ),
                  )
                else
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Options List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  _buildOptionTile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => _navigateWithAnimation(
                      context,
                      const SettingsScreen(),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => _navigateWithAnimation(
                      context,
                      const HelpSupportScreen(),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.contact_phone,
                    title: 'Emergency Contacts',
                    onTap: () => _navigateWithAnimation(
                      context,
                      const EmergencyContactsScreen(),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: _logout,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: 1.0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F0FA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : const Color(0xFF28588B),
            size: 24,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _navigateWithAnimation(BuildContext context, Widget screen) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation, // Uses the default fade-in effect
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}