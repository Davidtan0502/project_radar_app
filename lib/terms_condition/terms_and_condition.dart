import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/auth/registration_screen.dart';

class TermsConditionScreen {
  static void show(BuildContext context) {
    // Scroll controller and state-tracking variables for the dialog
    final ScrollController _scrollController = ScrollController();
    bool _listenerAttached = false;
    VoidCallback? _listener;
    bool _canAccept = false;
    double _scrollProgress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Read media query here to size dialog
        final media = MediaQuery.of(dialogContext);
        final double dialogWidth = media.size.width * 0.92; // max width
        final double dialogMaxHeight = media.size.height * 0.78; // max height to avoid overflow

        return Dialog(
          backgroundColor: Colors.white, // ONLY CHANGE: Added white background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: dialogMaxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  // Attach listener once (on first build)
                  if (!_listenerAttached) {
                    _listenerAttached = true;
                    _listener = () {
                      try {
                        if (!_scrollController.hasClients) return;
                        final maxScroll = _scrollController.position.maxScrollExtent;
                        final offset = _scrollController.offset;

                        // Update progress safely
                        final progress = (maxScroll <= 0) ? 1.0 : (offset / maxScroll).clamp(0.0, 1.0);
                        if ((progress - _scrollProgress).abs() > 0.01) {
                          setState(() => _scrollProgress = progress);
                        }

                        // Consider some tolerance in case of floating point rounding
                        if (offset >= maxScroll - 2.0) {
                          if (!_canAccept) {
                            setState(() => _canAccept = true);
                          }
                        }
                      } catch (_) {
                        // If position isn't available yet, ignore.
                      }
                    };
                    _scrollController.addListener(_listener!);
                  }

                  // helper to cleanup scroll controller & listener when dialog closes
                  void _cleanupAndPop([bool navigateToRegister = false]) {
                    try {
                      if (_listener != null) {
                        _scrollController.removeListener(_listener!);
                        _listener = null;
                      }
                    } catch (_) {}
                    try {
                      _scrollController.dispose();
                    } catch (_) {}
                    Navigator.of(dialogContext).pop();
                    if (navigateToRegister) {
                      Navigator.push(
                        dialogContext,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    }
                  }

                  return Column(
                    // Use max so Expanded can work inside the ConstrainedBox
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(
                        Icons.assignment, // terms icon
                        size: 48,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Terms and Conditions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Scroll progress indicator (thin) — non-blocking and informative
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: LinearProgressIndicator(
                          value: _scrollProgress,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3F73A3)), // Project RADAR blue
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Expanded scroll area that respects maxHeight from the parent ConstrainedBox
                      Expanded(
                        child: Stack(
                          children: [
                            // The main scrollable content
                            Scrollbar(
                              thumbVisibility: true,
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0), // Added padding inside scrollable area
                                child: SelectableText.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: '1. Acceptance of Terms\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'By registering for and using this mobile application, you acknowledge that you have read, understood, and agree to be legally bound by these Terms and Conditions. If you do not agree to these terms, you must not proceed with registration or use the RADAR Mobile App.\n\n',
                                      ),

                                      const TextSpan(
                                        text: '2. Governing Laws\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'This App operates in compliance with Republic Act No. 10173 (Data Privacy Act of 2012) and is aligned with the principles of Republic Act No. 10121 (Philippine Disaster Risk Reduction and Management Act of 2010).\n\n',
                                      ),

                                      const TextSpan(
                                        text: '3. Data We Collect\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'For the purposes of account creation, verification, and providing emergency response services, we collect and process the following personal information:\n\n',
                                      ),
                                      const TextSpan(text: '• Full Name\n'),
                                      const TextSpan(text: '• Age and Date of Birth\n'),
                                      const TextSpan(text: '• Home Address\n'),
                                      const TextSpan(text: '• Email Address\n'),
                                      const TextSpan(text: '• Current Location\n'),
                                      const TextSpan(text: '• Cellphone Number\n'),
                                      const TextSpan(text: '• Profile Image\n\n'),

                                      const TextSpan(
                                        text: '4. Use of Your Information\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'Your personal data will be used strictly for the following purposes:\n\n',
                                      ),
                                      const TextSpan(text: '• To create and verify your user account.\n'),
                                      const TextSpan(text: '• To provide and facilitate emergency services and disaster response.\n'),
                                      const TextSpan(text: '• To maintain the security and functionality of the system.\n\n'),
                                      const TextSpan(
                                        text:
                                            'Your data will be kept confidential and secure, accessed only by authorized personnel. It will not be shared with any third party without your express consent, except as required by law or for essential emergency response purposes.\n\n',
                                      ),

                                      const TextSpan(
                                        text: '5. Your Data Privacy Rights\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'In accordance with the Data Privacy Act, you have the right to access, correct, and request the deletion of your personal information held by us. You may contact us to exercise these rights.\n\n',
                                      ),

                                      const TextSpan(
                                        text: '6. User Responsibility and Prohibited Acts\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'You agree to use this App responsibly and solely for its intended purpose of reporting legitimate incidents.\n\n',
                                      ),

                                      const TextSpan(
                                        text: '6.1. Disclaimer on Emergency Response\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'You understand and acknowledge that this App is a support tool and does not replace professional emergency responders. The service facilitates reporting but does not guarantee a specific response time or outcome.\n\n',
                                      ),

                                      const TextSpan(
                                        text: '6.2. Prohibition on False Reporting\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'Pursuant to PRESIDENTIAL DECREE NO. 1727-A, it is unlawful to willfully communicate or maliciously disseminate false information regarding an attempt to damage or destroy property using explosives or similar means.\n\n',
                                      ),

                                      const TextSpan(
                                        text: '7. Penalties for Violation\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'Any user found to be in violation of these Terms, particularly the provision on false reporting under P.D. 1727-A, may be subject to legal prosecution. Penalties for violation can include:\n\n',
                                      ),
                                      const TextSpan(text: '• Imprisonment of up to five (5) years;\n'),
                                      const TextSpan(text: '• A fine of up to Forty Thousand Pesos (₱40,000.00); or\n'),
                                      const TextSpan(text: '• Both, at the discretion of the court.\n\n'),

                                      const TextSpan(
                                        text: '8. Consent\n',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text:
                                            'By proceeding with the registration and clicking "I Agree," you provide your explicit consent to the collection, use, and processing of your personal data as described herein, and you agree to abide by all the terms and conditions set forth in this document.\n',
                                      ),
                                    ],
                                  ),
                                  showCursor: false,
                                ),
                              ),
                            ),

                            // Non-blocking top/bottom gradient to subtly indicate scrollability
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height: 18,
                              child: IgnorePointer(
                                ignoring: true,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.white, Colors.white.withOpacity(0.0)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 18,
                              child: IgnorePointer(
                                ignoring: true,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Colors.white, Colors.white.withOpacity(0.0)],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Small floating 'Jump to bottom' button — does not block reading because it's small and tucked
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _canAccept ? 0.0 : 1.0, // hide when already reached bottom
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3F73A3), // Project RADAR blue
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: FloatingActionButton.small(
                                    heroTag: 'jump_to_bottom',
                                    backgroundColor: const Color(0xFF3F73A3), // Project RADAR blue
                                    onPressed: () {
                                      // animate to bottom
                                      if (_scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    },
                                    child: const Icon(
                                      Icons.arrow_downward,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // small hint (optional) — only visible while Accept still disabled
                      if (!_canAccept)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(
                            'Please scroll to the bottom to enable "Accept".',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Sticky action row — will always be visible and does not overlap the content
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.red.shade100,
                                  width: 1,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: () {
                                  // cleanup then close
                                  _cleanupAndPop(false);
                                },
                                child: const Text(
                                  'Decline',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.blue.shade100,
                                  width: 1,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canAccept ? const Color(0xFF3F73A3) : Colors.grey.shade300,
                                  foregroundColor: _canAccept ? Colors.white : Colors.grey.shade600,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: _canAccept
                                    ? () {
                                        // cleanup, close dialog and navigate to registration
                                        _cleanupAndPop(true);
                                      }
                                    : null,
                                child: const Text(
                                  'Accept',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}