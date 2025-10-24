import 'package:project_radar_app/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:project_radar_app/notification/incident_details_screen.dart';
import 'package:project_radar_app/notification/notification_service.dart';
import 'package:project_radar_app/screens/alerts/report_tracker_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/screens/auth/reset_password_screen.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase instead of Firebase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize deep linking for email verification & password recovery
  await _initializeDeepLinking();

  // Initialize notification service on non-web platforms
  if (!kIsWeb) {
    try {
      await NotificationService().initialize(navigatorKey: navigatorKey);
    } catch (e, st) {
      debugPrint('NotificationService.initialize() failed: $e');
      debugPrint('$st');
      // continue running the app even if notification init fails
    }
  } else {
    debugPrint('Web platform detected — skipping NotificationService.initialize()');
  }

  runApp(const MyApp());
}

Future<void> _initializeDeepLinking() async {
  try {
    final supabase = Supabase.instance.client;

    // Listen for Supabase auth events (handles password recovery link)
    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        final emailFromLink = session?.user?.email;

        debugPrint('[DeepLink] Password recovery detected, email: $emailFromLink');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = navigatorKey.currentState;
          if (nav != null) {
            nav.pushNamedAndRemoveUntil(
              '/reset-password',
              (route) => false,
              arguments: {
                'email': emailFromLink, // pass email to screen
              },
            );
          }
        });
      }
    });

    debugPrint('[DeepLink] Listener attached successfully.');
  } catch (e) {
    debugPrint('Error initializing deep linking: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Project RADAR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/incident': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return IncidentDetailsScreen(
            incidentId: args?['incidentId'] ?? 'unknown',
            type: args?['type'] ?? 'unknown',
            additionalData: args,
          );
        },
        '/reportTracker': (context) => const ReportTrackerScreen(),
        '/home': (context) => const MainNavigation(),

        //reset password route
        '/reset-password': (context) => const ResetPasswordScreen(),
        // add/login route that reads arguments
        '/forgot-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return LoginScreen(
            onTap: () {}, // keep your existing onTap or pass appropriate handler
            showVerificationMessage: false,
            initialEmail: args?['email'] as String?,
            initialShowPasswordStep: true, // ensure Login opens the password step
          );
        },
      },
      
      onGenerateRoute: (settings) {
        // Handle unknown routes or add additional routing logic here
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const AuthWrapper());
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Get Supabase client instance
  final SupabaseClient supabase = Supabase.instance.client;
  bool _checkingInitialAuth = true;
  bool _isCheckingSuspended = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
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

  // ENHANCED: Safe sign out method
  Future<void> _safeSignOut() async {
    try {
      await supabase.auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error during sign out: $e');
    }
  }

  // ENHANCED: Check initial auth with suspension validation
  Future<void> _checkInitialAuth() async {
    try {
      final session = supabase.auth.currentSession;
      final user = session?.user;

      if (user != null) {
        debugPrint('🔍 Found existing session for: ${user.email}');
        
        // STEP 1: Check if user is suspended
        final isSuspended = await _checkUserSuspended(user.id);
        if (isSuspended) {
          debugPrint('🚫 User is suspended - forcing sign out');
          await _safeSignOut();
          _showSuspendedSnackbar();
          return;
        }

        // STEP 2: Check email verification
        if (user.emailConfirmedAt == null) {
          debugPrint('📧 Email not verified - showing verification message');
          // User stays on login screen with verification message
        } else {
          debugPrint('✅ User authenticated and verified - proceeding to main app');
          // User will be automatically navigated to main app
        }
      } else {
        debugPrint('🔍 No existing session found');
      }
    } catch (e) {
      debugPrint('❌ Error checking initial auth: $e');
    } finally {
      setState(() {
        _checkingInitialAuth = false;
      });
    }
  }

  void _showSuspendedSnackbar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your account has been suspended. Please contact administrator.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingInitialAuth) return _buildLoadingScreen();

    return StreamBuilder<AuthState?>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final user = snapshot.data?.session?.user;
        final authEvent = snapshot.data?.event;
        
        // Skip auto-login if this is a password recovery
        final isPasswordRecovery = authEvent == AuthChangeEvent.passwordRecovery;
        if (isPasswordRecovery) {
          return const ResetPasswordScreen();
        }

        // ENHANCED: Handle suspended users in real-time
        if (user != null && authEvent == AuthChangeEvent.signedIn) {
          // Check suspension status for new sign-ins
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final isSuspended = await _checkUserSuspended(user.id);
            if (isSuspended) {
              debugPrint('🚫 Newly signed-in user is suspended - forcing sign out');
              await _safeSignOut();
              _showSuspendedSnackbar();
            }
          });
        }

        // ENHANCED: Navigation logic with suspension protection
        if (user != null && user.emailConfirmedAt != null) {
          // Final suspension check before navigation
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final isSuspended = await _checkUserSuspended(user.id);
            if (!isSuspended) {
              _setCurrentUser(user.id);
            }
          });
          
          return const MainNavigation();
        }

        if (user != null && user.emailConfirmedAt == null) {
          return LoginScreen(
            onTap: () {}, 
            showVerificationMessage: true,
            initialEmail: user.email,
          );
        }

        _clearCurrentUser();
        return LoginScreen(onTap: () {});
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'PROJECT RADAR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setCurrentUser(String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().setCurrentUser(userId);
    });
  }

  void _clearCurrentUser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().setCurrentUser(null);
    });
  }
}