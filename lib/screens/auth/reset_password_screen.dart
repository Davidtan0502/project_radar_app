import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    debugPrint('[ResetPasswordScreen] initState - currentUser: ${supabase.auth.currentUser}');
    debugPrint('[ResetPasswordScreen] initState - currentSession: ${supabase.auth.currentSession}');
  }

  @override
  void dispose() {
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _submitNewPassword() async {
    final newPw = _newPwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();

    final passwordRegex =
        RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{6,}$');

    if (!passwordRegex.hasMatch(newPw)) {
      _showError(
        'Password must be at least 6 characters and include an uppercase letter, a number, and a special character.',
      );
      return;
    }

    if (confirmPw != newPw) {
      _showError('Passwords do not match. Please re-enter.');
      return;
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _showError(
        'No active password reset session found. '
        'Please open the password reset link from the email again on this device so the app can handle it.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.updateUser(
        UserAttributes(password: newPw),
      );

      if (res.user != null) {
        _showInfo('Password updated. Please log in with your new password.');
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showInfo('Password updated. Please log in with your new password.');
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      debugPrint('[updatePassword] AuthException: ${e.message}');
      _showError('Auth error: ${e.message}');
    } catch (e, st) {
      debugPrint('[updatePassword] Unexpected: $e\n$st');
      _showError('Failed to update password. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Set New Password', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF336699),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _newPwController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password (min 6 chars)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!_isLoading) _submitNewPassword();
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPwController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter new password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!_isLoading) _submitNewPassword();
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitNewPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF336699),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Save Password',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
