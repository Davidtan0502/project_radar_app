import 'package:flutter/material.dart';
import 'package:project_radar_app/community/evacuation_screen.dart';
import 'package:project_radar_app/community/donation_info_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final headerHeight = screenHeight * 0.08;
    final sectionSpacing = screenHeight * 0.025;
    final sidePadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: headerHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF3F73A3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: headerHeight * 0.3,
                horizontal: sidePadding,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Community Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: sectionSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: SizedBox(
                        height: 50,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search community resources...",
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF3F73A3)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF3F73A3), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: sectionSpacing * 1.5),

                    // Evacuation Facilities Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evacuation Facilities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Stay safe and informed with available evacuation centers in Manila City.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Horizontal scroll list of evacuation centers
                          SizedBox(
                            height: 200,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildEvacuationCard(
                                    context,
                                    Icons.location_city,
                                    "Delpan Center",
                                    "74 Delpan St, San Nicolas, Manila, 1006 Metro Manila"),
                                _buildEvacuationCard(
                                    context,
                                    Icons.school,
                                    "Rosauro Almario School",
                                    "Manila International Container Terminal, 1012 MICT S Access Rd, Tondo, Manila, Metro Manila"),
                                _buildEvacuationCard(
                                    context,
                                    Icons.school,
                                    "Pedro Guevarra School",
                                    "HXXC+5F7, 302 San Fernando St, Binondo, Manila, 1010 Metro Manila"),
                                _buildEvacuationCard(
                                    context,
                                    Icons.school,
                                    "B.S. Aquino Elementary",
                                    "HXR5+4M8, Port Area, Manila, Metro Manila"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: sectionSpacing * 1.5),

                    // Community Support Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Community Support Services',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connect with your community and get support when you need it most.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Donation Drive: navigates to DonationInfoScreen
                          _buildServiceTile(
                              Icons.volunteer_activism,
                              Colors.redAccent,
                              "How to donate?",
                              "Support disaster relief efforts by donating goods or funds.",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DonationInfoScreen()),
                                );
                              }),

                          _buildServiceTile(Icons.settings, const Color.fromARGB(255, 0, 0, 0),
                              "Coming Soon", "--"),
                          _buildServiceTile(Icons.settings, const Color.fromARGB(255, 0, 0, 0),
                              "Coming Soon", "--"),
                          _buildServiceTile(Icons.settings, const Color.fromARGB(255, 0, 0, 0),
                              "Coming Soon", "--"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEvacuationCard(
    BuildContext context, IconData icon, String name, String address) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EvacuationDetailScreen(
            name: name,
            address: address,
          ),
        ),
      );
    },
    child: Container(
      height: 200,
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      constraints: const BoxConstraints(maxWidth: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // top image/icon area (fixed)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(icon, size: 36, color: const Color(0xFF3F73A3)),
            ),
          ),

          // bottom content takes remaining space and prevents overflow
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title — constrained so it won't push layout beyond available space
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Address — also constrained
                  Flexible(
                    child: Text(
                      address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // (Community Support)
  Widget _buildServiceTile(
      IconData icon, Color color, String title, String subtitle,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(
        minHeight: 70,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title, 
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15
          )
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Detail screen for evacuation center
class EvacuationDetailScreen extends StatelessWidget {
  final String name;
  final String address;

  const EvacuationDetailScreen({
    super.key,
    required this.name,
    required this.address,
  });

  Future<void> _openMapsWithOrigin(BuildContext context, String destinationAddress) async {
    // Try to get current location; returns null on failure/denied.
    Position? position;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      position = null;
    }

    // origin string if available
    String? origin;
    if (position != null) {
      origin = '${position.latitude},${position.longitude}';
    }

    // Encode components
    final String encodedDestination = Uri.encodeComponent(destinationAddress);
    final String? encodedOrigin = origin != null ? Uri.encodeComponent(origin) : null;

    // 1) Try Android native navigation intent (google.navigation) — most reliable for driving directions on Android.
    //    Example: google.navigation:q=lat,lng OR q=place+name
    final Uri androidNavUri = Uri.parse('google.navigation:q=$encodedDestination&mode=d');

    // 2) Try comgooglemaps scheme (iOS/Android if Google Maps app installed) with saddr/daddr
    final String appOriginParam = encodedOrigin != null ? 'saddr=$encodedOrigin&' : '';
    final Uri gmapsAppUri = Uri.parse('comgooglemaps://?${appOriginParam}daddr=$encodedDestination&directionsmode=driving');

    // 3) Web fallback (Google Maps directions)
    // Use /maps/dir/?api=1&origin=...&destination=...
    final Map<String, String> webParams = origin != null
        ? {'api': '1', 'origin': origin, 'destination': destinationAddress, 'travelmode': 'driving'}
        : {'api': '1', 'destination': destinationAddress};
    final Uri webUri = Uri.https('www.google.com', '/maps/dir/', webParams);

    debugPrint('Trying androidNavUri: $androidNavUri');
    debugPrint('Trying gmapsAppUri: $gmapsAppUri');
    debugPrint('Trying webUri: $webUri');

    try {
      // Try android navigation intent first
      if (await canLaunchUrl(androidNavUri)) {
        final launched = await launchUrl(androidNavUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('androidNavUri launch returned false, continuing to other options.');
      } else {
        debugPrint('androidNavUri not available');
      }
    } catch (e) {
      debugPrint('Error launching androidNavUri: $e');
    }

    try {
      // Try comgooglemaps scheme
      if (await canLaunchUrl(gmapsAppUri)) {
        final launched = await launchUrl(gmapsAppUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('gmapsAppUri launch returned false, continuing to web fallback.');
      } else {
        debugPrint('gmapsAppUri not available on device.');
      }
    } catch (e) {
      debugPrint('Error launching gmapsAppUri: $e');
    }

    try {
      // Try web fallback
      if (await canLaunchUrl(webUri)) {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('webUri launch returned false as well.');
      } else {
        debugPrint('webUri cannot be launched.');
      }
    } catch (e) {
      debugPrint('Error launching webUri: $e');
    }

    // Final fallback: search the address in maps
    final Uri fallbackSearch = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': destinationAddress});
    try {
      if (await canLaunchUrl(fallbackSearch)) {
        await launchUrl(fallbackSearch, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Error launching fallbackSearch: $e');
    }

    // If all failed, notify user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Added white background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F73A3),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50)
              ),
            ),
            const SizedBox(height: 8),
            Text(
              address, 
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15
              )
            ),
            const SizedBox(height: 20),
            const Text(
              "Additional Information:",
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50)
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "This evacuation center provides shelter and basic necessities "
              "for residents affected by disasters in Manila City. The facility "
              "is equipped with emergency supplies, medical aid, and temporary "
              "accommodations for affected families.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              "Available Amenities:",
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50)
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAmenityChip("Medical Assistance"),
                _buildAmenityChip("Food & Water"),
                _buildAmenityChip("Sleeping Areas"),
                _buildAmenityChip("Sanitation"),
                _buildAmenityChip("Child Care"),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openMapsWithOrigin(context, address),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F73A3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Get Directions",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmenityChip(String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: const Color(0xFFE8F1FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
