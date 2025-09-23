import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_radar_app/notification/notification_service.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/screens/home/main_navigation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _requestAndroidNotificationPermission() async {
  // Only relevant on Android 13+; permission_handler handles OS differences.
  try {
    if (!Platform.isAndroid) return;
    final status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
    // If permanentlyDenied, you may want to show a dialog guiding user to settings.
  } catch (e) {
    debugPrint('Error requesting notification permission: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first (required if NotificationService depends on Firebase)
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Set navigator key BEFORE initialize so notification taps can navigate immediately.
    NotificationService.setNavigatorKey(navigatorKey);

    // Request Android runtime notification permission (Android 13+).
    await _requestAndroidNotificationPermission();

    // Initialize notification service only on non-web platforms to avoid web-only issues.
    if (!kIsWeb) {
      await NotificationService.initialize();
    } else {
      debugPrint('Web platform detected — skipping NotificationService.initialize()');
    }

    runApp(const MyApp());
  } catch (e, st) {
    debugPrint('Startup initialization error: $e');
    debugPrint('$st');

    // Show a simple error UI instead of a white screen so you can see the problem during testing.
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project RADAR - Init Error',
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization error')),
        body: Center(child: Text('Initialization failed: $e')),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // <<--- important for notification tap navigation
      debugShowCheckedModeBanner: false,
      title: 'Project RADAR',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      // keep your existing routes — add '/incident' if you want notification tap to open incident details
      routes: {
        '/incident': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          // Replace with your incident detail screen widget
          return Scaffold(
            appBar: AppBar(title: const Text('Incident')),
            body: Center(child: Text('Open incident: ${args?['incidentId'] ?? 'unknown'}')),
          );
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Auth error — helpful while debugging
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Auth error: ${snapshot.error}')));
        }

        // User is logged in (you used to check emailVerified; keep your original logic if needed)
        if (snapshot.hasData) {
          // tell NotificationService who is signed in so unread badge is accurate
          NotificationService.setCurrentUser(snapshot.data!.uid);
          return const MainNavigation();
        }

        // User is not logged in
        return LoginScreen(onTap: () {});
      },
    );
  }
}
