import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    final radarBlue = const Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: Colors.white)),
        backgroundColor: radarBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Welcome to Project RADAR – your emergency preparedness app!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: radarBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What is Project RADAR?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: radarBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Project RADAR is an innovative mobile application designed to help individuals by providing emergency contact information. We aim to give users a sense of security, with features that allow them to report incidents, view Agencies Department Contact, and connect to help when they need it most.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Text(
              'Our Team',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: radarBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Project RADAR was created by a dedicated team of students at STI Sta Mesa who are passionate about improving public safety. Our goal is to continue enhancing the app with more features and support to ensure everyone’s safety, no matter where they are.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Add your action for contact or more info
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: radarBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Get in Touch', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
