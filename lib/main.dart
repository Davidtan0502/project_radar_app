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

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      // Check if we have a session from a deep link (email verification)
      final session = supabase.auth.currentSession;
      final user = session?.user;

    } catch (e) {
      debugPrint('Error checking initial auth: $e');
    } finally {
      setState(() {
        _checkingInitialAuth = false;
      });
    }
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
        
      // Skip auto-login if this is a password recovery
      final isPasswordRecovery = snapshot.data?.event == AuthChangeEvent.passwordRecovery;
      if (isPasswordRecovery) {
        return const ResetPasswordScreen();
      }

      if (user != null && user.emailConfirmedAt != null) {
        _setCurrentUser(user.id);
        return const MainNavigation();
      }

      if (user != null && user.emailConfirmedAt == null) {
        return LoginScreen(onTap: () {}, showVerificationMessage: true);
      }

      _clearCurrentUser();
      return LoginScreen(onTap: () {});
    },
  );
}

 Widget _buildLoadingScreen() {
  return const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
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
