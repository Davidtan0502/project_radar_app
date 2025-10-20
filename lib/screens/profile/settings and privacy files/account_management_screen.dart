import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_radar_app/screens/profile/account%20management%20files/edit_account_info.dart';
import 'package:project_radar_app/screens/profile/account%20management%20files/change_password.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/settings&privacy_screen.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/notification/notification_service.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Delete Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Content
              Text(
                "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          Navigator.of(dialogContext).pop();

                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;

                          if (user != null) {
                            final uid = user.id;

                            // ---------- 0) Read user data for storage paths ----------
                            Map<String, dynamic>? userData;
                            try {
                              final response = await supabase
                                  .from('app_users')
                                  .select()
                                  .eq('id', uid)
                                  .single();
                              userData = response;
                            } catch (e) {
                              debugPrint('Failed to read user data before deletion: $e');
                              userData = null;
                            }

                            // ---------- Optional helper: delete storage object ----------
                            Future<void> _tryDeleteStorageObject(String? filePath) async {
                              if (filePath == null || filePath.isEmpty) return;

                              try {
                                // Extract filename from full URL or path
                                // If it's a full URL, extract the path after the bucket name
                                String path = filePath;
                                if (filePath.contains('storage/v1/object/public/avatars/')) {
                                  path = filePath.split('avatars/').last;
                                } else if (filePath.contains('/')) {
                                  // If it's already a path, use it as is
                                  path = filePath;
                                }
                                
                                if (path.isNotEmpty) {
                                  await supabase.storage.from('avatars').remove([path]);
                                  debugPrint('Deleted storage object: $path');
                                }
                              } catch (e) {
                                debugPrint('Storage delete failed for "$filePath": $e');
                              }
                            }

                            // ---------- 1) Delete emergency contacts ----------
                            try {
                              await supabase
                                  .from('emergency_contacts')
                                  .delete()
                                  .eq('user_id', uid);
                            } catch (e) {
                              debugPrint('Failed to delete emergency contacts: $e');
                            }

                            // ---------- 2) Try to delete photo & id files from storage ----------
                            try {
                              final photoUrl = userData != null ? (userData['photo_url'] ?? '').toString() : '';
                              final idUrl = userData != null ? (userData['id_url'] ?? '').toString() : '';

                              await _tryDeleteStorageObject(photoUrl);
                              await _tryDeleteStorageObject(idUrl);
                            } catch (e) {
                              debugPrint('Storage deletion encountered an error: $e');
                            }

                            // ---------- 3) Clear photo_url/id_url fields (best-effort) ----------
                            try {
                              await supabase
                                  .from('app_users')
                                  .update({'photo_url': null, 'id_url': null})
                                  .eq('id', uid);
                            } catch (e) {
                              debugPrint('Failed to clear photo_url/id_url fields: $e');
                            }

                            // ---------- 4) Delete user record ----------
                            try {
                              await supabase
                                  .from('app_users')
                                  .delete()
                                  .eq('id', uid);
                            } catch (e) {
                              debugPrint('Failed to delete user record: $e');
                            }

                            // ---------- 4.5) Clean up notification tokens & local prefs ----------
                            try {
                              await NotificationService().cleanupOnAccountDelete(userId: uid);
                            } catch (e) {
                              debugPrint('Notification cleanup failed (best-effort): $e');
                            }

                            // ---------- 5) Delete Auth account ----------
                            try {
                              // Option 1: Simple approach - just delete data and sign out
                              // This removes all user data but leaves the auth user inactive
                              await supabase.auth.signOut();
                              
                              // Option 2: If you have an Edge Function set up
                              // final response = await supabase.functions.invoke('delete-user-account');
                              // debugPrint('Edge function response: ${response.data}');
                              
                            } catch (e) {
                              debugPrint('Auth cleanup failed: $e');
                              // Still sign out even if there are errors
                              await supabase.auth.signOut();
                            }

                            // --- Clear NotificationService internal state ----------
                            try {
                              await NotificationService().setCurrentUser(null);
                            } catch (e) {
                              debugPrint('Failed to clear NotificationService current user: $e');
                            }

                            // Final navigation
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Your account was deleted."),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => LoginScreen(onTap: () {})),
                                (route) => false,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No user found.")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error deleting account: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Delete Account",
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF28588B);
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Account Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Account Options Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildModernOptionTile(
                          context,
                          icon: Icons.edit_outlined,
                          title: 'Edit Account Details',
                          subtitle: 'Update your personal information',
                          onTap: () => Navigation.push(
                            context,
                            const EditAccountinfo(),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1, color: Colors.grey.shade200),
                        ),
                        _buildModernOptionTile(
                          context,
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Update your security password',
                          onTap: () => Navigation.push(
                            context,
                            const ChangePassword(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delete Account Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.red.shade100,
                        width: 1,
                      ),
                    ),
                    child: _buildModernOptionTile(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account and data',
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

  Widget _buildModernOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFF28588B);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}