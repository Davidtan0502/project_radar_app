import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:project_radar_app/notification/incident_details_screen.dart';
import 'package:project_radar_app/notification/notification_service.dart';
import 'package:project_radar_app/screens/alerts/report_tracker_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final User? user = snapshot.data;

        // If we have a signed-in & verified user
        if (user != null && user.emailVerified) {
          _setCurrentUser(user.uid);
          return const MainNavigation();
        }

        // Not logged in or not verified -> show login
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