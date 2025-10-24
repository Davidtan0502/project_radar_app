import 'dart:async';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'package:project_radar_app/terms_condition/terms_and_condition.dart';
import 'package:project_radar_app/screens/auth/reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key, 
    required this.onTap,
    this.showVerificationMessage = false,
    this.initialEmail,
    this.initialShowPasswordStep = false,
  });
  
  final VoidCallback onTap;
  final bool showVerificationMessage;
  final String? initialEmail;
  final bool initialShowPasswordStep;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  
  // Text controllers and focus nodes
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  // State variables
  bool _isLoading = false;
  bool _showPasswordStep = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _showSuspendedPopup = false;

  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Apply optional initial arguments (prefill email / open password step)
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialShowPasswordStep) {
      // Give a short delay so widget is mounted before changing focus/UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showPasswordStep = true;
        });
        _focusPasswordField();
      });
    }
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: const Color(0xFF336699),
      end: const Color(0xFF5588CC),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // ENHANCED: Check if mobile app user is suspended
  Future<bool> _checkUserSuspended(String userId) async {
    try {
      debugPrint('🔍 Checking mobile user suspension status for: $userId');
      
      final userData = await supabase
          .from('app_users')
          .select('status, suspended_at, suspended_by, email')
          .eq('id', userId)
          .single();

      final status = userData['status'] as String?;
      final isSuspended = status == 'suspended';
      
      debugPrint('📊 Mobile user suspension status: $status');
      
      if (isSuspended) {
        final suspendedAt = userData['suspended_at'];
        final suspendedBy = userData['suspended_by'];
        final userEmail = userData['email'];
        
        debugPrint('🚫 Mobile user is suspended:');
        debugPrint('   - User: $userEmail');
        debugPrint('   - Suspended at: $suspendedAt');
        debugPrint('   - Suspended by: $suspendedBy');
        
        return true; // User is suspended
      }
      
      return false; // User is active
    } catch (e) {
      debugPrint('⚠️ Error checking mobile user suspension status: $e');
      // If we can't check suspension status, allow login (fail-safe)
      return false;
    }
  }

  // ENHANCED: Email verification step with suspension check
  Future<void> _verifyEmail() async {
    if (!mounted) return;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final rawEmail = _emailController.text.trim();
    if (!_validateEmail(rawEmail)) {
      return;
    }

    final email = rawEmail.toLowerCase();

    try {
      debugPrint('[verifyEmail] checking email and suspension status for: $email');

      // ENHANCED: Check both email existence AND suspension status
      dynamic userData;
      
      // Try to get user data including status
      try {
        userData = await supabase
            .from('app_users')
            .select('id, email, status')
            .ilike('email', email)
            .maybeSingle();

        if (userData == null) {
          // Try exact match if ilike fails
          userData = await supabase
              .from('app_users')
              .select('id, email, status')
              .eq('email', email)
              .maybeSingle();
        }
      } catch (e) {
        debugPrint('[verifyEmail] Error querying user data: $e');
        userData = null;
      }

      if (!mounted) return;

      // Check if user exists
      if (userData == null) {
        setState(() {
          _isLoading = false;
          _showPasswordStep = false;
          _passwordController.clear();
          _emailError = 'No account found with this email. Please register first.';
        });
        _emailFocusNode.requestFocus();
        return;
      }

      // ENHANCED: Check if user is suspended
      final userId = userData['id'] as String?;
      final status = userData['status'] as String?;
      
      if (userId != null && status == 'suspended') {
        debugPrint('🚫 User is suspended - preventing password step');
        setState(() {
          _isLoading = false;
          _showPasswordStep = false;
          _passwordController.clear();
          _showSuspendedPopup = true; // Show popup instead of inline error
        });
        return;
      }

      // User exists and is not suspended - proceed to password step
      setState(() {
        _isLoading = false;
        _showPasswordStep = true;
      });
      _focusPasswordField();
      
    } catch (e, st) {
      debugPrint('[verifyEmail] Exception: $e\n$st');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('Failed to verify email. Please check your network and database policies.');
    }
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
        _emailError = 'Please enter your email';
      });
      return false;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _isLoading = false;
        _emailError = 'Please enter a valid email address';
      });
      return false;
    }
    
    return true;
  }

  void _focusPasswordField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  // ENHANCED: Login logic with final suspension check
  Future<void> _handleLogin() async {
    if (!mounted) return;
    
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    debugPrint('Login attempt for $email');

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _processLoginResponse(response, email);
    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _handleUnexpectedError(e);
    }
  }

  Future<void> _processLoginResponse(AuthResponse response, String email) async {
    debugPrint('Login successful: ${response.user?.id}');
    debugPrint('Email confirmed: ${response.user?.emailConfirmedAt}');

    final user = response.user;

    if (user == null) {
      _handleAuthenticationFailure();
      return;
    }

    // ENHANCED: Final suspension check before allowing access
    final isSuspended = await _checkUserSuspended(user.id);
    if (isSuspended) {
      debugPrint('🚫 User is suspended - forcing sign out');
      await _safeSignOut();
      setState(() {
        _showSuspendedPopup = true; // Show popup for suspended account
      });
      return;
    }

    if (user.emailConfirmedAt == null) {
      _handleUnverifiedEmail(email);
      return;
    }

    await _handleSuccessfulLogin(user);
  }

  void _handleAuthenticationFailure() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _passwordError = 'Authentication failed. Please try again.';
    });
  }

  void _handleUnverifiedEmail(String email) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showPasswordStep = false;
      _passwordController.clear();
      _emailError = 'Please verify your email before logging in. Check your inbox for the verification link.';
    });
    
    _showDialog('Please verify your email before logging in. Check your inbox for the verification link.');
    _emailFocusNode.requestFocus();
    
    _resendVerificationEmail(email);
  }

  void _resendVerificationEmail(String email) {
    try {
      supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      debugPrint('Verification email resent to $email');
    } catch (e) {
      debugPrint('Failed to resend verification email: $e');
    }
  }

  Future<void> _handleSuccessfulLogin(User user) async {
    if (!mounted) return;
    setState(() => _isLoading = false);

    await _updateUserLastActive(user.id);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (ctx) => const MainNavigation()),
    );
  }

  Future<void> _updateUserLastActive(String userId) async {
    try {
      await supabase
          .from('app_users')
          .update({
            'last_active': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating last active: $e');
    }
  }

  // ENHANCED: Safe sign out method
  Future<void> _safeSignOut() async {
    try {
      await supabase.auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error during sign out: $e');
    }
  }

  void _handleAuthException(AuthException e) {
    debugPrint('AuthException during login: ${e.message}');
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (e.message) {
      case 'Invalid login credentials':
        _handleInvalidCredentials();
        break;
      case 'Email not confirmed':
        _handleEmailNotConfirmed();
        break;
      case 'User not found':
        _handleUserNotFound();
        break;
      case 'Too many requests':
        _handleTooManyRequests();
        break;
      default:
        _handleGenericAuthError(e);
    }
  }

  void _handleInvalidCredentials() {
    setState(() {
      _passwordError = 'Incorrect password. Please try again.';
    });
    _passwordFocusNode.requestFocus();
  }

  void _handleEmailNotConfirmed() {
    setState(() {
      _showPasswordStep = false;
      _passwordController.clear();
      _emailError = 'Please verify your email before logging in. Check your inbox for the verification link.';
    });
    _showDialog('Please verify your email before logging in. Check your inbox for the verification link.');
    _emailFocusNode.requestFocus();
  }

  void _handleUserNotFound() {
    setState(() {
      _showPasswordStep = false;
      _passwordController.clear();
      _emailError = 'No account found with this email.';
    });
    _emailFocusNode.requestFocus();
  }

  void _handleTooManyRequests() {
    setState(() {
      _showPasswordStep = false;
      _passwordController.clear();
      _emailError = 'Too many attempts. Please try again later.';
    });
    _emailFocusNode.requestFocus();
  }

  void _handleGenericAuthError(AuthException e) {
    if (e.message.toLowerCase().contains('password') || 
        e.message.toLowerCase().contains('credentials')) {
      setState(() {
        _passwordError = 'Incorrect password. Please try again.';
      });
      _passwordFocusNode.requestFocus();
    } else {
      _showErrorDialog('Login error: ${e.message}');
    }
  }

  void _handleUnexpectedError(dynamic e) {
    debugPrint('Unexpected error during login: $e');
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showErrorDialog('An unexpected error occurred. Please try again.');
  }

  // Password reset
  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    
    if (!_validateEmailForPasswordReset(email)) return;

    setState(() => _isLoading = true);
    
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.projectradar://reset-password',
      );

      if (!mounted) return;
      _showDialog('Password reset instructions have been sent to $email');
    } on AuthException catch (e, st) {
      debugPrint('[resetPassword] AuthException: ${e.message}\n$st');
      if (!mounted) return;
      _showErrorDialog('Error sending reset email: ${e.message}');
    } catch (e, st) {
      debugPrint('[resetPassword] Unexpected error: $e\n$st');
      if (!mounted) return;
      _showErrorDialog('Failed to send reset email. Please check SMTP settings in Supabase Auth.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateEmailForPasswordReset(String email) {
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorDialog('Please enter a valid email address to reset password.');
      return false;
    }
    return true;
  }

 Widget _buildSuspendedPopup() {
  return AnimatedOpacity(
    opacity: _showSuspendedPopup ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 200),
    child: Visibility(
      visible: _showSuspendedPopup,
      child: Stack(
        children: [
          // Translucent black background
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          // Dialog content
          Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        color: Colors.red.shade600,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      'Account Suspended',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      'Your account has been temporarily suspended by an administrator. '
                      'This may be due to policy violations or security concerns.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Contact Information - Fixed overflow
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Support Header with Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.support_agent_rounded,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible( // FIX: Added Flexible to prevent overflow
                                child: Text(
                                  'Need Help? Contact Support',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Email Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade100,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Email Support Team',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Email with copy functionality - FIXED OVERFLOW
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(const ClipboardData(
                                        text: 'radarconnects2025@gmail.com'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Email copied to clipboard'),
                                        backgroundColor: Colors.green.shade50,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: double.infinity,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min, // FIX: Use min size
                                      children: [
                                        Icon(
                                          Icons.email_rounded,
                                          color: Colors.blue.shade600,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible( // FIX: Critical - Added Flexible here
                                          child: Text(
                                            'radarconnects2025@gmail.com',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis, // FIX: Handle overflow
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.content_copy_rounded,
                                          color: Colors.blue.shade600,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to copy email address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Instructions
                          Text(
                            'Please include your account email and details for faster assistance',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          setState(() {
                            _showSuspendedPopup = false;
                            _emailController.clear();
                            _passwordController.clear();
                            _showPasswordStep = false;
                            _emailError = null;
                            _passwordError = null;
                          });
                        },
                        child: const Text(
                          'OK, I Understand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // Dialog helpers
  void _showDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'RADAR',
          style: TextStyle(color: Color(0xFF336699)),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _colorAnimation.value)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _colorAnimation.value)),
          ),
        ],
      ),
    );
  }

  // UI Components
  Widget _buildVerificationMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Please verify your email before logging in. Check your inbox for the verification link.',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showVerificationMessage) _buildVerificationMessage(),
        Text(
          'Welcome!',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your email address',
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        const SizedBox(height: 12),
        _buildEmailField(),
        SizedBox(height: isSmallScreen ? 12 : 20),
        _buildContinueButton(isSmallScreen),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emailError != null ? Colors.red : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.email, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) => setState(() => _emailError = null),
                  onSubmitted: (_) => _verifyEmail(),
                ),
              ),
            ],
          ),
          if (_emailError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _emailError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey : _colorAnimation.value,
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
                  color: Colors.white,
                ),
              )
            : Text(
                'Continue',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPasswordStep() {
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordHeader(),
        const SizedBox(height: 6),
        Text(
          'Enter password for ${_emailController.text}',
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        const SizedBox(height: 12),
        _buildPasswordField(),
        const SizedBox(height: 8),
        _buildForgotPasswordButton(),
        SizedBox(height: isSmallScreen ? 12 : 20),
        _buildLoginButton(isSmallScreen),
      ],
    );
  }

  Widget _buildPasswordHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => setState(() {
            _showPasswordStep = false;
            _passwordController.clear();
            _passwordError = null;
          }),
        ),
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.height < 600 ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _passwordError != null ? Colors.red : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lock, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() => _passwordError = null),
                  onSubmitted: (_) => _handleLogin(),
                ),
              ),
            ],
          ),
          if (_passwordError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _passwordError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _handlePasswordReset,
        style: TextButton.styleFrom(foregroundColor: _colorAnimation.value),
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorAnimation.value,
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
                  color: Colors.white,
                ),
              )
            : Text(
                'Login',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLogoSection(bool isSmallScreen) {
    return Flexible(
      flex: isSmallScreen ? 4 : 6,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: isSmallScreen ? 90 : 130,
              ),
              const SizedBox(height: 12),
              const Text(
                'R.A.D.A.R',
                style: TextStyle(
                  fontSize: 56,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (!isSmallScreen) ...[
                const SizedBox(height: 4),
                const Text(
                  '(Rapid Action for Disaster Aid Resource)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(bool isSmallScreen) {
    return Flexible(
      flex: isSmallScreen ? 6 : 5,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isSmallScreen ? 16 : 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: _showPasswordStep ? _buildPasswordStep() : _buildEmailStep(),
            ),
            if (!_showPasswordStep) _buildRegistrationSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? "),
            TextButton(
              onPressed: () {
                TermsConditionScreen.show(context);
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          'project RADAR: A Small Effort, Big Difference',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return Container(
                color: _colorAnimation.value,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                _buildLogoSection(isSmallScreen),
                                _buildFormSection(isSmallScreen),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Suspended Account Popup
          if (_showSuspendedPopup) _buildSuspendedPopup(),
        ],
      ),
    );
  }
}