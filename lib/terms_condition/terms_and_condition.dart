import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/auth/registration_screen.dart';

class TermsConditionScreen {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.assignment,
                  size: 50,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Terms and Conditions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 250,
                  child: SingleChildScrollView(
                    child: Text(
                      'By registering, you agree to our Terms and Conditions and acknowledge our compliance with the Data Privacy Act of 2012 (RA 10173).\n\n'
                      'We collect and process the following personal data: name, age, home address, current location, and profile image. These will be used only for:\n\n'
                      '• Account creation and verification\n'
                      '• Providing emergency services for response\n'
                      '• Maintaining system security and functionality\n\n'
                      'Your data will be kept secure, accessed only by authorized personnel, and will not be shared with third parties without your consent, except when required by law or for emergency purposes.\n\n'
                      'You have the right to access of deletion of your personal information.\n\n'
                      'By proceeding, you agree to use this application responsibly and understand that it supports emergency response but does not replace professional responders.\n\n',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Decline',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Accept',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
