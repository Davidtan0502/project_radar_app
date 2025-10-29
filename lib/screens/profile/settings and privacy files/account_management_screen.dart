import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_radar_app/screens/profile/account%20management%20files/edit_account_info.dart';
import 'package:project_radar_app/screens/profile/account%20management%20files/change_password.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/settings&privacy_screen.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/notification/notification_service.dart';

// Replace with your actual Supabase project URL (example: https://xyz.supabase.co)
const String PROJECT_URL = 'https://zqfcmpewoernuorvxzle.supabase.co';

/// Live-updating progress dialog used during deletion.
/// Provide a ValueNotifier<String> to update the shown message during the flow.
class DeleteProgressDialog extends StatefulWidget {
  final ValueNotifier<String> message;
  final Duration dotInterval;
  const DeleteProgressDialog({
    Key? key,
    required this.message,
    this.dotInterval = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<DeleteProgressDialog> createState() => _DeleteProgressDialogState();
}

class _DeleteProgressDialogState extends State<DeleteProgressDialog> {
  int _dotCount = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    widget.message.addListener(_onMessage);
    _dotTimer = Timer.periodic(widget.dotInterval, (_) {
      setState(() => _dotCount = (_dotCount + 1) % 4);
    });
  }

  void _onMessage() => setState(() {});

  @override
  void dispose() {
    widget.message.removeListener(_onMessage);
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    final msg = widget.message.value;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  CircularProgressIndicator(strokeWidth: 3, color: Colors.red),
                  Icon(Icons.delete_outline, size: 24, color: Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$msg$dots',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

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
                      // Cancel must simply close the dialog
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
                    // DELETE button — this runs the server-side delete and only signs out on success
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // 1) close confirmation dialog first
                          Navigator.of(dialogContext).pop();

                          // 2) create and show live-updating progress dialog (use page context)
                          final progressNotifier = ValueNotifier<String>('Preparing to delete');
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => DeleteProgressDialog(message: progressNotifier),
                          );

                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;
                          final session = supabase.auth.currentSession;

                          if (user == null) {
                            // close progress dialog and inform user
                            try { Navigator.of(context).pop(); } catch (_) {}
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No user found.")));
                            }
                            return;
                          }

                          final uid = user.id;
                          final token = session?.accessToken;
                          debugPrint('Delete invoked for uid: $uid');
                          debugPrint('accessToken present: ${token != null}');
                          if (token != null && token.length > 20) {
                            debugPrint('accessToken (trunc): ${token.substring(0, 20)}...');
                          }

                          // 1) attempt normal supabase.functions.invoke
                          Map? efBody;
                          int status = 0;
                          dynamic efData;

                          // Update UI: starting storage removal step
                          progressNotifier.value = 'Removing files';

                          try {
                            final efResponse = await supabase.functions.invoke(
                              'delete-user-account',
                              body: {'userId': uid},
                            );
                            status = efResponse.status ?? 0;
                            efData = efResponse.data;
                            efBody = efData is Map ? Map<String, dynamic>.from(efData) : {'data': efData};
                            debugPrint('Supabase function response - status: $status, data: $efBody');
                          } catch (e) {
                            debugPrint('supabase.functions.invoke failed: $e');
                            // network fallback: try raw HTTP to see exact status/body (helps diagnose network issues)
                            try {
                              // Update UI: using raw HTTP fallback
                              progressNotifier.value = 'Contacting server';

                              // Use explicit PROJECT_URL instead of supabase.options
                              final uri = Uri.parse('$PROJECT_URL/functions/v1/delete-user-account');
                              final resp = await http.post(
                                uri,
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer ${token ?? ''}',
                                },
                                body: jsonEncode({'userId': uid}),
                              );
                              status = resp.statusCode;
                              efData = resp.body;
                              efBody = {'http_body': resp.body};
                              debugPrint('raw http fallback status: $status body: ${resp.body}');
                            } catch (rawErr) {
                              // close progress dialog
                              try { Navigator.of(context).pop(); } catch (_) {}
                              debugPrint('raw HTTP fallback failed: $rawErr');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Delete failed (network): $rawErr"), backgroundColor: Colors.red),
                                );
                              }
                              return;
                            }
                          }

                          // close progress dialog before showing result
                          try { Navigator.of(context).pop(); } catch (_) {}

                          // Final status messages
                          if (status >= 200 && status < 300) {
                            // success: sign out and clear notification state
                            try {
                              await supabase.auth.signOut();
                            } catch (e) {
                              debugPrint('signOut failed: $e');
                            }
                            try {
                              await NotificationService().setCurrentUser(null);
                            } catch (e) {
                              debugPrint('NotificationService cleanup failed: $e');
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Your account was deleted."), backgroundColor: Colors.green),
                              );
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => LoginScreen(onTap: () {})),
                                (route) => false,
                              );
                            }
                          } else {
                            final msg = efBody != null ? efBody.toString() : 'Unknown server error (status $status)';
                            debugPrint('Delete failed: status=$status body=$efBody');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Account deletion failed: $msg"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        } catch (e, st) {
                          // ensure any progress dialog is closed
                          try { Navigator.of(context).pop(); } catch (_) {}
                          debugPrint('Unexpected delete exception: $e\n$st');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red),
                            );
                          }
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

/// Small, animated deleting dialog used while the account deletion runs.
/// Non-dismissible by the user; stops animation when popped.
class _DeletingDialog extends StatefulWidget {
  const _DeletingDialog({Key? key}) : super(key: key);

  @override
  State<_DeletingDialog> createState() => _DeletingDialogState();
}

class _DeletingDialogState extends State<_DeletingDialog> {
  final List<String> _messages = [
    'Removing files…',
    'Cleaning records…',
    'Finalizing deletion…',
  ];

  int _msgIndex = 0;
  int _dotCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Animate message + dot count every 600ms
    _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
        if (_dotCount == 0) {
          _msgIndex = (_msgIndex + 1) % _messages.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              '${_messages[_msgIndex]}$dots',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
