import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project RADAR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainNavigation(), // 👈 This shows the nav bar + screens
    );
  }
}
