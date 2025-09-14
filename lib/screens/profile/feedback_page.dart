import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:another_flushbar/flushbar.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final String _appEmail = "radarconnects2025@gmail.com"; // Receiver email

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userEmailController.text = user?.email ?? "";
  }

  Future<void> _sendFeedback() async {
  final feedback = _feedbackController.text.trim();
  final userEmail = _userEmailController.text.trim();

  if (feedback.isEmpty || userEmail.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields.')),
    );
    return;
  }

  final subject = 'User Feedback - Project RADAR';
  final body = 'From: $userEmail\n\n$feedback';

  // special chars are handled properly
  final emailUri = Uri.parse(
    'mailto:$_appEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );

  try {
    final success = await launchUrl(
      emailUri,
      mode: LaunchMode.externalApplication,
    );

 if (success) {
  _feedbackController.clear();

  Flushbar(
    message: "Feedback sent successfully!",
    duration: const Duration(seconds: 8),
    backgroundColor: Colors.green,
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    flushbarPosition: FlushbarPosition.TOP, // appear at top
    icon: const Icon(Icons.check_circle, color: Colors.white),
    messageText: const Text(
      'Feedback sent successfully!',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  ).show(context);
}

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No email app available.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share your Feedback"),
        backgroundColor: const Color(0xFF336699),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "We value your feedback!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please share your thoughts or issues with us below.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // User Email (editable)
            TextField(
              controller: _userEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Your Email",
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // App Email (readonly)
            TextField(
              enabled: false,
              controller: TextEditingController(text: _appEmail),
              decoration: InputDecoration(
                labelText: "App Email",
                prefixIcon: const Icon(Icons.business_outlined),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Feedback box
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: "Your Feedback",
                hintText: "Enter your feedback here...",
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.feedback_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Send button
            Center(
              child: ElevatedButton.icon(
                onPressed: _sendFeedback,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "Send Feedback",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF336699),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
