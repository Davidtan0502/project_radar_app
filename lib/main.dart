import 'package:project_radar_app/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:project_radar_app/notification/incident_details_screen.dart';
import 'package:project_radar_app/notification/notification_service.dart';
import 'package:project_radar_app/screens/alerts/report_tracker_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Config {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase instead of Firebase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize deep linking for email verification
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
  // Set up deep link handling for email verification
  try {
    // Supabase Flutter handles deep link initialization automatically.
    // Check if we have a session from a deep link
    final initialSession = Supabase.instance.client.auth.currentSession;
    if (initialSession != null) {
      debugPrint('Initial session found from deep link');
    }
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
      
      if (user != null && user.emailConfirmedAt != null) {
        // User just verified email via deep link - show verification success
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushReplacementNamed('/verify-redirect');
        });
        return;
      }
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
    if (_checkingInitialAuth) {
      return _buildLoadingScreen();
    }

    return StreamBuilder<AuthState?>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // User is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final AuthState? authState = snapshot.data;
        final User? user = authState?.session?.user;

        // Check if this is a new verification via deep link
        if (authState?.event == AuthChangeEvent.signedIn) {
          final currentUser = supabase.auth.currentUser;
          if (currentUser != null && currentUser.emailConfirmedAt != null) {
            // This might be a fresh verification - could navigate to verification success
            // But let's handle this in the stream to avoid loops
          }
        }

        // If we have a signed-in user with verified email
        if (user != null && user.emailConfirmedAt != null) {
          _setCurrentUser(user.id);
          return const MainNavigation();
        }

        // If we have a user but email is not verified
        if (user != null && user.emailConfirmedAt == null) {
          // Show login screen with message about email verification
          return LoginScreen(
            onTap: () {},
            showVerificationMessage: true,
          );
        }

        // Not logged in -> show login
        if (user == null) {
          _clearCurrentUser();
        }

        return LoginScreen(onTap: () {});
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
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