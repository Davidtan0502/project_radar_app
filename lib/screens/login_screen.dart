import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/main_navigation.dart';
import 'package:project_radar_app/screens/registration_screen.dart'; // NEW import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required Null Function() onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isLoading = false;

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
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter your email');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Flexible(
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
                                          fontSize: 40,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      if (!isSmallScreen) ...[
                                        const SizedBox(height: 4),
                                        const Text(
                                          '(Rapid Action for Disaster Aid Resource)',
                                          style: TextStyle(fontSize: 12, color: Colors.white70),
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
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: isSmallScreen ? 16 : 20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, offset: Offset(0, -3), blurRadius: 6),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome!',
                                      style: TextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold),
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
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
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
                                            ),
                                          ),
                                        ],
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : Text(
                                                'Login',
                                                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text("Don't have an account? "),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                            );
                                          },
                                          child: const Text("Register"),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Center(
                                        child: Text(
                                          'Road Safety: A Small Effort, Big Difference',
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
