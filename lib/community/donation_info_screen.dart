import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class DonationInfoScreen extends StatelessWidget {
  const DonationInfoScreen({super.key});

  static const String _dlswAddress =
      'Department of Social Welfare and Development, Legarda St, 389 San Rafael St, Quiapo, Manila, 1001 Metro Manila';
  static const String _dlswPhone = '0917-110-5686';

  // DSWD contact email
  static const String _dlswEmail = 'foncr@dswd.gov.ph';

  // Destination query / name for maps
  static const String _dlswMapsQuery = 'DSWD Field Office NCR Manila';

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:$_dlswPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _dlswEmail,
    );
    final url = Uri.parse(uri.toString());
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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
      return null;
    }
  }

  /// Launch Google Maps. Prefer opening the Google Maps app with directions.
  /// Falls back to web if app is not installed or unavailable.
  Future<void> _launchMaps() async {
    try {
      final Position? pos = await _getCurrentPosition();

      final encodedDestination = Uri.encodeComponent(_dlswMapsQuery);

      // If we have a position, include it as the origin.
      String? originLatLng;
      if (pos != null) {
        originLatLng = '${pos.latitude},${pos.longitude}';
      }

      // 1) Try to open Google Maps app (comgooglemaps://). Use saddr/daddr for directions.
      // If origin is available, pass saddr=lat,lng; otherwise omit saddr and just use daddr.
      final Uri googleMapsAppUri = originLatLng != null
          ? Uri.parse('comgooglemaps://?saddr=$originLatLng&daddr=$encodedDestination&directionsmode=driving')
          : Uri.parse('comgooglemaps://?daddr=$encodedDestination&directionsmode=driving');

      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(googleMapsAppUri, mode: LaunchMode.externalApplication);
        return;
      }

      // 2) If app not available, use web directions URL. If origin present include it.
      final Uri googleMapsWebUri = originLatLng != null
          ? Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$originLatLng&destination=$encodedDestination&travelmode=driving')
          : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedDestination&travelmode=driving');

      if (await canLaunchUrl(googleMapsWebUri)) {
        await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
        return;
      }

      // 3) Final fallback: open a simple search for the destination.
      final fallbackQuery = Uri.encodeComponent(_dlswMapsQuery);
      final fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$fallbackQuery');
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // On any unexpected error, try the simple search fallback.
      final fallbackQuery = Uri.encodeComponent(_dlswMapsQuery);
      final fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$fallbackQuery');
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the improved scroll layout — SafeArea + LayoutBuilder + ConstrainedBox + IntrinsicHeight
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Donate?'),
        backgroundColor: const Color(0xFF3F73A3),
        elevation: 0,
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
                    // Top banner/header — removed Call/Open map buttons here per your request
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

                    // Contact card (address, phone, email, map) - this is the only place that has Call/Map now
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.place, color: Color(0xFF3F73A3)),
                                SizedBox(width: 8),
                                Text('DSWD Field Office NCR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_dlswAddress, style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(_dlswPhone, style: const TextStyle(fontSize: 14)),
                                const Spacer(),
                                TextButton(
                                  onPressed: _launchPhone,
                                  child: const Text('Call'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_dlswEmail, style: const TextStyle(fontSize: 14))),
                                TextButton(
                                  onPressed: _launchEmail,
                                  child: const Text('Email'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('DSWD Field Office NCR — Manila', style: TextStyle(fontSize: 14))),
                                TextButton(
                                  onPressed: _launchMaps,
                                  child: const Text('Open map'),
                                ),
                              ],
                            ),
                          ],
                        ),
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

                    _infoCard(
                      Icons.local_shipping,
                      "For In-Kind Donations via Courier",
                      [
                        const Text("• Contact DSWD Field Office NCR: Reach out to the DSWD Field Office NCR to coordinate the donation of food, non-food items, or other goods."),
                        const SizedBox(height: 8),
                        const Text("• Arrange Delivery: Use courier services like Grab, Lalamove, or J&T Express to deliver your items."),
                      ],
                    ),

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
