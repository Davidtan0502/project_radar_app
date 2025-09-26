import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/auth/registration_screen.dart';

class TermsConditionScreen {
  static void show(BuildContext context) {
    // Scroll controller and state-tracking variables for the dialog
    final ScrollController _scrollController = ScrollController();
    bool _listenerAttached = false;
    VoidCallback? _listener;
    bool _canAccept = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                      final maxScroll = _scrollController.position.maxScrollExtent;
                      final offset = _scrollController.offset;
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
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Text(
                            'By registering, you agree to our Terms and Conditions and acknowledge our compliance with the Data Privacy Act of 2012 (RA 10173).\n\n'
                            'We collect and process the following personal data: full name, age, date of birth, home address, email address, current location, cellphone Number, and profile image. These will be used only for:\n\n'
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
                    ),
                    const SizedBox(height: 12),
                    // small hint (optional) — only visible while Accept still disabled
                    if (!_canAccept)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          'Please scroll to the bottom to enable "Accept".',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
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
                              // cleanup then close
                              _cleanupAndPop(false);
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
                            onPressed: _canAccept
                                ? () {
                                    // cleanup, close dialog and navigate to registration
                                    _cleanupAndPop(true);
                                  }
                                : null, // disabled until scrolled
                            child: const Text(
                              'Accept',
                              style: TextStyle(color: Colors.black87),
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
        );
      },
    );
  }
}
