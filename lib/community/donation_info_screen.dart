import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // for Clipboard

class DonationInfoScreen extends StatelessWidget {
  const DonationInfoScreen({super.key});

  static const String _dlswAddress =
      'Department of Social Welfare and Development, Legarda St, 389 San Rafael St, Quiapo, Manila, 1001 Metro Manila';
  static const String _dlswPhone = '0917-110-5686';

  // DSWD contact email
  static const String _dlswEmail = 'foncr@dswd.gov.ph';

  // Destination query / name for maps
  static const String _dlswMapsQuery = 'DSWD Field Office NCR Manila';

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri.parse('tel:$_dlswPhone');
    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone dialer')),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone not available on this device')),
        );
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  /// TRY GMAIL APP FIRST -> FALLBACK TO mailto: -> FINAL: copy email to clipboard + snackbar
  Future<void> _launchEmail(BuildContext context) async {
    // 1) Try Gmail app compose URI (best-effort)
    try {
      // Use encoded email inside the URI
      final Uri gmailUri = Uri.parse('googlegmail://co?to=${Uri.encodeComponent(_dlswEmail)}');
      debugPrint('Attempting to open Gmail app: $gmailUri');

      if (await canLaunchUrl(gmailUri)) {
        final launched = await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('Gmail app launch returned false; falling back to mailto.');
      } else {
        debugPrint('Gmail URI not available on this device.');
      }
    } catch (e) {
      debugPrint('Error trying Gmail URI: $e');
      // fall through to mailto fallback
    }

    // 2) Fallback: open default mail client using mailto:
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: _dlswEmail,
      // optionally add queryParameters: {'subject': 'Donation Inquiry', 'body': 'Hello...'}
    );

    debugPrint('Falling back to mailto: $mailtoUri');

    try {
      if (await canLaunchUrl(mailtoUri)) {
        final launched = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('launchUrl(mailto) returned false.');
      } else {
        debugPrint('No mail client available to handle mailto:');
      }
    } catch (e) {
      debugPrint('Error launching mailto: $e');
    }

    // 3) Final fallback: copy email to clipboard and inform the user
    try {
      await Clipboard.setData(const ClipboardData(text: _dlswEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No email app found. Email address copied to clipboard: $_dlswEmail\n'
              'Please paste it into your email app.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying email to clipboard: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email client available')),
        );
      }
    }
  }

  /// Try to get the current position. Returns null on failure.
  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, can't fetch position.
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied.
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever.
        return null;
      }

      // All set — get position.
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      // If anything fails, return null to fall back to default behavior.
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Launch Google Maps. Prefer a scheme that starts navigation; fall back to app scheme, then web.
  Future<void> _launchMaps(BuildContext context) async {
    try {
      final Position? pos = await _getCurrentPosition();

      // origin if available
      String? originLatLng;
      if (pos != null) {
        originLatLng = '${pos.latitude},${pos.longitude}';
      }

      // Destination encoding
      final String encodedDestinationForSchemes = _dlswMapsQuery.replaceAll(' ', '+'); // good for comgooglemaps / google.navigation
      final String encodedDestinationForUri = Uri.encodeComponent(_dlswMapsQuery);

      // Platform-aware ordering:
      // Android: try google.navigation:  -> comgooglemaps:// -> web
      // iOS: try comgooglemaps:// -> web
      // Fallback -> web search

      // 1) Android native navigation intent (google.navigation:) — best for Android navigation
      final Uri androidNavigationUri = Uri.parse('google.navigation:q=$encodedDestinationForSchemes&mode=d');

      // 2) comgooglemaps scheme (if Google Maps app installed)
      final Uri comGoogleMapsUri = originLatLng != null
          ? Uri.parse('comgooglemaps://?saddr=$originLatLng&daddr=$encodedDestinationForSchemes&directionsmode=driving')
          : Uri.parse('comgooglemaps://?daddr=$encodedDestinationForSchemes&directionsmode=driving');

      // 3) Web fallback using https with proper query parameters
      final Map<String, String> webParams = originLatLng != null
          ? {
              'api': '1',
              'origin': originLatLng,
              'destination': _dlswMapsQuery,
              'travelmode': 'driving',
            }
          : {
              'api': '1',
              'destination': _dlswMapsQuery,
              'travelmode': 'driving',
            };
      final Uri googleMapsWebUri = Uri.https('www.google.com', '/maps/dir/', webParams);

      debugPrint('Computed URIs for maps:');
      debugPrint('androidNavigationUri: $androidNavigationUri');
      debugPrint('comGoogleMapsUri: $comGoogleMapsUri');
      debugPrint('googleMapsWebUri: $googleMapsWebUri');

      // Helper to attempt a URI and return true when it launched
      Future<bool> tryLaunch(Uri uri) async {
        try {
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint('launchUrl($uri) returned $launched');
            return launched;
          } else {
            debugPrint('canLaunchUrl returned false for $uri');
            return false;
          }
        } catch (e) {
          debugPrint('Error launching $uri : $e');
          return false;
        }
      }

      bool launched = false;

      if (Platform.isAndroid) {
        // Try google.navigation first on Android
        launched = await tryLaunch(androidNavigationUri);
        if (launched) return;

        // Then try comgooglemaps scheme
        launched = await tryLaunch(comGoogleMapsUri);
        if (launched) return;
      } else if (Platform.isIOS) {
        // Prefer comgooglemaps on iOS if present
        launched = await tryLaunch(comGoogleMapsUri);
        if (launched) return;
      } else {
        // Other platforms: try comgooglemaps then web
        launched = await tryLaunch(comGoogleMapsUri);
        if (launched) return;
      }

      // Web fallback
      launched = await tryLaunch(googleMapsWebUri);
      if (launched) return;

      // Final fallback: search
      final Uri fallbackSearch =
          Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': _dlswMapsQuery});
      debugPrint('Trying fallback search URI: $fallbackSearch');
      launched = await tryLaunch(fallbackSearch);
      if (launched) return;

      // Nothing worked
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps')));
      }
    } catch (e) {
      debugPrint('Unexpected error in _launchMaps: $e');
      // Try a final web search fallback
      final Uri fallbackSearch =
          Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': _dlswMapsQuery});
      try {
        if (await canLaunchUrl(fallbackSearch)) {
          await launchUrl(fallbackSearch, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps')));
      }
    }
  }

  Widget _stepCard(int number, String title, String body) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF3F73A3),
              child: Text(
                number.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              backgroundColor: const Color(0xFFE8F1FF),
              child: Icon(icon, color: const Color(0xFF3F73A3))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        const SizedBox(height: 8),
        ...children,
      ]), 
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3F73A3);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'How to Donate?',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top banner/header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F73A3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Donate safely & effectively',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Use the Kaagapay Donations Portal or contact DSWD Field Office NCR for in-kind or cash donations. Below are details and tips to ensure your donation gets processed correctly.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contact card (address, phone, email, map) - Updated to white background
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.place, color: primaryColor),
                              const SizedBox(width: 8),
                              Text('DSWD Field Office NCR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_dlswAddress, style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(_dlswPhone, style: const TextStyle(fontSize: 14)),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _launchPhone(context),
                                child: const Text('Call'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_dlswEmail, style: const TextStyle(fontSize: 14))),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await Clipboard.setData(const ClipboardData(text: _dlswEmail));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Email address copied to clipboard')),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Error copying email to clipboard: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not copy email')),
                                      );
                                    }
                                  }
                                },
                                child: const Icon(Icons.copy, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: primaryColor),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('DSWD Field Office NCR — Manila', style: TextStyle(fontSize: 14))),
                              TextButton(
                                onPressed: () => _launchMaps(context),
                                child: const Text('Open map'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _infoCard(
                      Icons.language,
                      "Using the Kaagapay Donations Portal",
                      [
                        const Text(
                            "• Visit the Portal: Go to DSWD's Kaagapay Donations Portal to access information on accredited charitable groups and direct donation options."),
                        const SizedBox(height: 8),
                        const Text("Choose Your Donation Type:", style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text("• Cash: You can process cash donations via platforms."),
                        const SizedBox(height: 4),
                        const Text(
                            "• In-Kind: The portal can link you with partner courier services like Grab and Lalamove for direct delivery to DSWD-run Community Rehabilitation and Correctional Facilities (CRCFs) or Social Welfare and Development Agencies (SWDAs)."),
                        const SizedBox(height: 8),
                        const Text("• Follow Instructions: The portal guides you through the logistics and payment process, ensuring your donation reaches an accredited and licensed foundation."),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _infoCard(
                      Icons.local_shipping,
                      "For In-Kind Donations via Courier",
                      [
                        const Text("• Contact DSWD Field Office NCR: Reach out to the DSWD Field Office NCR to coordinate the donation of food, non-food items, or other goods."),
                        const SizedBox(height: 8),
                        const Text("• Arrange Delivery: Use courier services like Grab, Lalamove, or J&T Express to deliver your items."),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _infoCard(
                      Icons.description,
                      "Ensure Proper Documentation",
                      [
                        const Text("• The recipient will need a notarized deed of acceptance."),
                        const SizedBox(height: 6),
                        const Text("• A packing list/inventory of the donated items is required."),
                        const SizedBox(height: 6),
                        const Text("• A plan of distribution endorsed by the relevant DSWD Field Office is necessary."),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _infoCard(
                      Icons.info,
                      "Important Considerations",
                      [
                        const Text(
                            "• Accreditation: The Kaagapay Portal features only DSWD-accredited and licensed SWDAs, assuring donors of legitimate transactions."),
                        const SizedBox(height: 8),
                        const Text("• Logistics: Donors are responsible for the cost of delivery for in-kind donations."),
                        const SizedBox(height: 8),
                        const Text(
                            "• Documentation: Proper documentation is crucial, especially for large or international donations, to facilitate duty-free processing."),
                        const SizedBox(height: 8),
                        const Text(
                            "• Direct Assistance: The DSWD also provides assistance to LGUs in disaster-affected areas, covering the process from the receipt of requests to the delivery of relief items."),
                      ],
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}