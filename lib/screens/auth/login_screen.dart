import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'package:project_radar_app/terms_condition/terms_and_condition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key, 
    required this.onTap,
    this.showVerificationMessage = false,
  });
  
  final VoidCallback onTap;
  final bool showVerificationMessage;

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
  
  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  // Email verification step
  Future<void> _verifyEmail() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim().toLowerCase();
    
    if (!_validateEmail(email)) return;

    setState(() {
      _isLoading = false;
      _showPasswordStep = true;
    });
    
    _focusPasswordField();
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

  // Login logic
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
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showDialog('Password reset instructions have been sent to $email');
    } on AuthException catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to send reset email. Please try again.');
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

  // Dialog helpers
  void _showDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      body: AnimatedBuilder(
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
    );
  }
}