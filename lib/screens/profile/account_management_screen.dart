import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/profile/edit_account_info.dart';
import 'package:project_radar_app/screens/profile/change_password.dart';
import 'package:project_radar_app/screens/profile/settings_screen.dart';
import 'package:project_radar_app/services/navigation.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Account"),
            content: const Text(
              "Are you sure you want to delete your account? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deletion initiated."),
                    ),
                  );
                  // TODO: Add delete logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  // ← replace pop with a straight replacement to SettingsScreen
                  onPressed:
                      () => Navigator.pop(context, const SettingsScreen()),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Account Options Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildAccountOptionTile(
                          context,
                          icon: Icons.edit_outlined,
                          title: 'Edit Account Details',
                          onTap:
                              () => Navigation.push(
                                context,
                                const EditAccountinfo(),
                              ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildAccountOptionTile(
                          context,
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          onTap:
                              () => Navigation.push(
                                context,
                                const ChangePassword(),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delete Account Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildAccountOptionTile(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      isDestructive: true,
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDestructive ? const Color(0xFFFAE8E8) : const Color(0xFFE8F0FA),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF28588B),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      onTap: onTap,
    );
  }
}
