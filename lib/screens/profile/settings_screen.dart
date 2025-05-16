import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/profile/account_management_screen.dart';
import 'about_us.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isDarkMode = false;
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${info.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 30),
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
                    // <— single-pop back to ProfileScreen
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  _buildOptionTile(
                    icon: Icons.person,
                    title: 'Account',
                    onTap:
                        () => Navigator.push(
                          context,
                          _createRoute(const AccountManagementScreen()),
                        ),
                  ),
                  _buildOptionTile(
                    icon: Icons.lock,
                    title: 'Privacy & Security',
                    onTap: () {}, // stub
                  ),
                  _buildOptionTile(
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap:
                        () => Navigator.push(
                          context,
                          _createRoute(const AboutUs()),
                        ),
                  ),
                  // SwitchListTile(
                  //  title: const Text('Notifications'),
                  //  value: _notificationsEnabled,
                  // activeColor: const Color(0xFF28588B),
                  // onChanged: (value) {
                  //  setState(() {
                  //    _notificationsEnabled = value;
                  //  });
                  // },
                  // ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: _isDarkMode,
                    activeColor: const Color(0xFF28588B),
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                      // trigger theme change here if needed
                    },
                  ),
                  ListTile(
                    title: const Text('App Version'),
                    subtitle: Text(_appVersion),
                    leading: const Icon(Icons.system_update_alt_outlined),
                  ),
                  const SizedBox(height: 20),
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
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F0FA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF28588B), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Route _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }
}
