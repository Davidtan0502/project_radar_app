import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/profile/edit_account_info.dart';
import 'package:project_radar_app/screens/profile/change_password.dart';
import 'package:project_radar_app/screens/profile/settings&privacy_screen.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:project_radar_app/notification/notification_service.dart'; // <-- added

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // close dialog
            },
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color.fromARGB(255, 4, 4, 4)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.of(dialogContext).pop(); // close dialog

                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  final uid = user.uid;
                  final firestore = FirebaseFirestore.instance;

                  // ---------- 0) Read user doc (we'll use it for storage paths / urls) ----------
                  Map<String, dynamic>? userDocData;
                  try {
                    final docSnap = await firestore.collection('users').doc(uid).get();
                    userDocData = (docSnap.exists && docSnap.data() != null)
                        ? Map<String, dynamic>.from(docSnap.data()!)
                        : null;
                  } catch (e) {
                    debugPrint('Failed to read users/$uid doc before deletion: $e');
                    userDocData = null;
                  }

                  // ---------- Optional helper: delete storage object from either URL or path ----------
                  Future<void> _tryDeleteStorageObject(String? value) async {
                    if (value == null) return;
                    final v = value.toString().trim();
                    if (v.isEmpty) return;

                    try {
                      if (v.startsWith('http://') || v.startsWith('https://')) {
                        // If it's a download URL, try to get ref from URL
                        try {
                          final ref = FirebaseStorage.instance.refFromURL(v);
                          await ref.delete();
                          debugPrint('Deleted storage object from URL: $v');
                          return;
                        } catch (e) {
                          debugPrint('refFromURL delete failed for $v: $e');
                          // fallthrough to attempt treat as path
                        }
                      }

                      // treat as a path (e.g. "profile_images/uid.jpg")
                      try {
                        final ref = FirebaseStorage.instance.ref().child(v);
                        await ref.delete();
                        debugPrint('Deleted storage object from path: $v');
                      } catch (e) {
                        debugPrint('ref.child delete failed for $v: $e');
                        // final fallback: nothing else to try
                      }
                    } catch (e) {
                      debugPrint('Unexpected storage delete error for "$v": $e');
                    }
                  }

                  // ---------- 1) Delete emergency contacts subcollection ----------
                  try {
                    final subcolRef = firestore
                        .collection('users')
                        .doc(uid)
                        .collection('emergency_contacts');

                    final subSnap = await subcolRef.get();
                    if (subSnap.docs.isNotEmpty) {
                      WriteBatch batch = firestore.batch();
                      int opCount = 0;
                      for (final doc in subSnap.docs) {
                        batch.delete(doc.reference);
                        opCount++;
                        if (opCount >= 400) {
                          await batch.commit();
                          batch = firestore.batch();
                          opCount = 0;
                        }
                      }
                      if (opCount > 0) await batch.commit();
                    }
                  } catch (e) {
                    debugPrint('Failed to delete emergency_contacts subcollection: $e');
                  }

                  // ---------- 2) Try to delete photo & id files from Firebase Storage ----------
                  try {
                    final photoUrl = userDocData != null ? (userDocData['photoURL'] ?? '').toString() : '';
                    final idUrl = userDocData != null ? (userDocData['idURL'] ?? '').toString() : '';

                    await _tryDeleteStorageObject(photoUrl);
                    await _tryDeleteStorageObject(idUrl);
                  } catch (e) {
                    debugPrint('Storage deletion encountered an error: $e');
                  }

                  // ---------- 3) Clear photoURL/idURL fields in Firestore (best-effort) ----------
                  try {
                    final userRef = firestore.collection('users').doc(uid);
                    await userRef.update({'photoURL': '', 'idURL': ''});
                  } catch (e) {
                    debugPrint('Failed to clear photoURL/idURL fields: $e');
                  }

                  // ---------- 4) Delete main user document ----------
                  try {
                    await firestore.collection('users').doc(uid).delete();
                  } catch (e) {
                    debugPrint('Failed to delete users/$uid doc: $e');
                  }

                  // ---------- 4.5) Clean up notification tokens & local prefs (best-effort) ----------
                  try {
                    // This method should be implemented in your NotificationService.
                    // It will remove tokens from Firestore (users/{uid}.fcmTokens and fcm_tokens/{token}),
                    // stop listeners, clear unread prefs, etc.
                    await NotificationService().cleanupOnAccountDelete(userId: uid);
                  } catch (e) {
                    debugPrint('Notification cleanup failed (best-effort): $e');
                  }

                  // ---------- 5) Delete Auth account ----------
                  try {
                    await user.delete();
                  } catch (e) {
                    // If deletion fails due to requires-recent-login, rethrow so outer catch handles it.
                    rethrow;
                  }

                  // --- Ensure auth state is refreshed and sign out is completed before navigation ---
                  try {
                    // Force reload (best-effort)
                    try {
                      await FirebaseAuth.instance.currentUser?.reload();
                    } catch (e) {
                      debugPrint('Auth reload failed after delete: $e');
                    }

                    // Sign out to ensure auth state is cleared locally
                    await FirebaseAuth.instance.signOut();
                  } catch (e) {
                    debugPrint('SignOut after delete failed: $e');
                    // continue to navigation anyway
                  }

                  // --- Clear NotificationService internal state (best-effort) ---
                  try {
                    await NotificationService().setCurrentUser(null);
                  } catch (e) {
                    debugPrint('Failed to clear NotificationService current user: $e');
                  }

                  // Final navigation: clear entire navigator stack and show LoginScreen
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Your account was deleted.")),
                    );

                    // IMPORTANT: remove everything from navigation stack so no previous routes (e.g. main navigation) remain
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
                if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
                  //  Session is too old → force logout + redirect
                  await FirebaseAuth.instance.signOut();

                  // Clear NotificationService state as well (best-effort)
                  try {
                    await NotificationService().setCurrentUser(null);
                  } catch (err) {
                    debugPrint('Failed to clear NotificationService current user after signOut: $err');
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Session expired. Please log in again to delete your account.",
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
                    SnackBar(content: Text("Error deleting account: $e")),
                  );
                }
              }
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
                  'Settings',
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
