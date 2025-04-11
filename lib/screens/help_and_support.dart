import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFFB71C1C); // Project RADAR deep red
    const Color backgroundColor = Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 24),
            _sectionTitle("📞 Contact Us"),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _contactItem(Icons.email_outlined, "support@projectradar.com"),
                  const Divider(height: 1),
                  _contactItem(Icons.phone_outlined, "+1 800 123 4567"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle("🛠️ Support Tools"),
            const SizedBox(height: 12),
            _buildButton(
              icon: Icons.feedback_outlined,
              label: "Send Feedback",
              backgroundColor: themeColor,
              textColor: Colors.white,
              onPressed: () {
                // Navigate to feedback
              },
            ),
            const SizedBox(height: 12),
            _buildButton(
              icon: Icons.bug_report_outlined,
              label: "Report an Issue",
              backgroundColor: Colors.white,
              textColor: themeColor,
              border: BorderSide(color: themeColor),
              onPressed: () {
                // Navigate to report
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedIconColor: Colors.grey[700],
      iconColor: Colors.redAccent,
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _contactItem(IconData icon, String info) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFD32F2F)),
      title: Text(
        info,
        style: const TextStyle(fontSize: 15),
      ),
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
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: border,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
