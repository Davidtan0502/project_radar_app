import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'package:project_radar_app/notification/notification_service.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); //RENZ

  // Give NotificationService the navigator key so notification taps can navigate.
  NotificationService.setNavigatorKey(navigatorKey);

  // Initialize notification service on non-web platforms.
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      routes: {
        '/incident': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return Scaffold(
            appBar: AppBar(title: const Text('Incident')),
            body: Center(child: Text('Open incident: ${args?['incidentId'] ?? 'unknown'}')),
          );
        },
      },
    );
  }
}

/// AuthWrapper:
/// - If no signed-in user -> LoginScreen.
/// - If signed-in user -> show MainNavigation only when verified.
/// IMPORTANT: Do NOT auto sign-out unverified users here; let LoginScreen handle validation/dialog.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If we have a signed-in & verified user, ensure NotificationService knows the current user
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          // schedule setting current user after this frame to avoid side-effects during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              NotificationService.setCurrentUser(snapshot.data!.uid);
            } catch (e) {
              debugPrint('Failed to set current user in NotificationService: $e');
            }
          });

          return const MainNavigation();
        }

        // Not logged in or not verified -> show login
        return LoginScreen(onTap: () {});
      },
    );
  }
}
