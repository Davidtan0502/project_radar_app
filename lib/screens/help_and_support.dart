import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: themeColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("📖 Frequently Asked Questions"),
            const SizedBox(height: 12),
            _buildCard(
              child: _buildFAQItem(
                "How does Project RADAR work?",
                "Project RADAR sends real-time disaster alerts based on your location. It helps you stay safe during emergencies.",
              ),
            ),
            _buildCard(
              child: _buildFAQItem(
                "Can I report incidents?",
                "Yes, use the Alert button (⚠️) at the center of the bottom navigation bar to report an emergency quickly.",
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("📞 Contact Us"),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _contactItem(Icons.email, "support@projectradar.com"),
                  const Divider(),
                  _contactItem(Icons.phone, "+1 800 123 4567"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("🛠️ Support Tools"),
            const SizedBox(height: 12),
            _buildButton(
              icon: Icons.feedback_outlined,
              label: "Send Feedback",
              backgroundColor: themeColor,
              textColor: Colors.white,
              onPressed: () {
                // navigate to feedback form
              },
            ),
            const SizedBox(height: 10),
            _buildButton(
              icon: Icons.bug_report_outlined,
              label: "Report an Issue",
              backgroundColor: Colors.white,
              textColor: themeColor,
              border: BorderSide(color: themeColor),
              onPressed: () {
                // navigate to issue report
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            answer,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _contactItem(IconData icon, String info) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(info),
      dense: true,
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    BorderSide? border,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
