import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'package:project_radar_app/terms_condition/terms_and_condition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _showPasswordStep = false;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
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

  Future<void> _verifyEmail() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    // Check if the email is registered in Firestore
    try {
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (userSnapshot.docs.isEmpty) {
        // If the email is not found, show an error message and don't move to the password step
        setState(() {
          _emailError = 'No account found. Please register first.';
          _showPasswordStep = false; // Keep user in the email step
        });
        return;
      }

      // Email is found, proceed to the password step
      setState(() {
        _isLoading = false;
        _showPasswordStep = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _emailError =
            'An error occurred while checking the email. Please try again.';
      });
    }
  }

  // The error messages
  final String notFoundMsg = 'No account found. Please register first.';
  final String invalidEmailMsg = 'This email address is invalid.';
  final String notVerifiedMsg =
      'Your email isn’t verified yet. Please check your inbox.';
  final String wrongPassMsg = 'Incorrect password. Please try again.';
  final String userDisabledMsg = 'This account has been disabled.';
  final String tooManyReqMsg = 'Too many attempts. Please try again later.';

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      await _auth.currentUser!.reload();
      final user = _auth.currentUser;

      if (user == null || !user.emailVerified) {
        await user?.sendEmailVerification();
        await _auth.signOut();

        setState(() {
          _isLoading = false;
          _showPasswordStep = false;
          _passwordController.clear();
          _emailError = notVerifiedMsg;
        });
        _emailFocusNode.requestFocus();
        return;
      }

      // 4) (Optional) mark verified in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'emailVerified': true},
      );

      // 5) Go into the app
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (e) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      switch (e.code) {
        case 'invalid-email':
        case 'user-not-found':
        case 'user-disabled':
        case 'too-many-requests':
          // existing email‐field cases…
          setState(() {
            _showPasswordStep = false;
            _passwordController.clear();
            _emailError =
                {
                  'invalid-email': invalidEmailMsg,
                  'user-not-found': notFoundMsg,
                  'user-disabled': userDisabledMsg,
                  'too-many-requests': tooManyReqMsg,
                }[e.code];
          });
          _emailFocusNode.requestFocus();
          break;

        case 'wrong-password':
        case 'invalid-credential':
          setState(() {
            _passwordError = wrongPassMsg;
          });
          _passwordFocusNode.requestFocus();
          break;

        default:
          _showErrorDialog('Login error: ${e.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _handlePasswordReset() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      if (!mounted) return;
      _showDialog('Password reset instructions sent to your email');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorDialog('RADAR: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to send reset email');
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'RADAR',
              style: TextStyle(color: Color.fromARGB(255, 28, 217, 255)),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: _colorAnimation.value),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: _colorAnimation.value),
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
        Container(
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
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        SizedBox(
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
            child:
                _isLoading
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
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final isSmallScreen = MediaQuery.of(context).size.height < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  () => setState(() {
                    _showPasswordStep = false;
                    _passwordController.clear();
                    _passwordError = null;
                  }),
            ),
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enter password for ${_emailController.text}',
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
        const SizedBox(height: 12),
        Container(
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
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
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handlePasswordReset,
            style: TextButton.styleFrom(foregroundColor: _colorAnimation.value),
            child: const Text('Forgot Password?'),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 20),
        SizedBox(
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
            child:
                _isLoading
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
        ),
      ],
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
                            Flexible(
                              flex: isSmallScreen ? 4 : 6,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
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
                            ),
                            Flexible(
                              flex: isSmallScreen ? 6 : 5,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: isSmallScreen ? 16 : 20,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
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
                                      child:
                                          _showPasswordStep
                                              ? _buildPasswordStep()
                                              : _buildEmailStep(),
                                    ),
                                    if (!_showPasswordStep) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text("Don't have an account? "),
                                          TextButton(
                                            onPressed: () {
                                              TermsConditionScreen.show(
                                                context,
                                              );
                                            },
                                            child: const Text("Register"),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const Padding(
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
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
