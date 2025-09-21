import 'package:flutter/material.dart';
import 'package:project_radar_app/community/evacuation_screen.dart';

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
                                    "Tondo, Manila"),
                                _buildEvacuationCard(
                                    context,
                                    Icons.school,
                                    "Rosauro Almario School",
                                    "Sta. Cruz"),
                                _buildEvacuationCard(
                                    context,
                                    Icons.school,
                                    "Pedro Guevarra School",
                                    "San Nicolas"),
                                _buildEvacuationCard(
                                    context,
                                    Icons.school,
                                    "B.S. Aquino Elementary",
                                    "Baseco"),
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
                          
                          _buildServiceTile(
                              Icons.volunteer_activism,
                              Colors.redAccent,
                              "Donation Drive",
                              "Support disaster relief efforts by donating goods or funds."),
                          _buildServiceTile(Icons.health_and_safety, Colors.teal,
                              "Medical Assistance", "Get aid for medical expenses."),
                          _buildServiceTile(Icons.directions_bus, Colors.blue,
                              "Transportation Help", "Request a ride for urgent needs."),
                          _buildServiceTile(Icons.school, Colors.orange,
                              "Training Request", "Apply for skills and livelihood training."),
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

  // Evacuation Center Card (clickable)
 static Widget _buildEvacuationCard(
    BuildContext context, IconData icon, String name, String address) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EvacuationScreen(
            name: name,
            address: address,
          ),
        ),
      );
    },
    child: Container(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // Service Tile (Community Support)
  Widget _buildServiceTile(
      IconData icon, Color color, String title, String subtitle) {
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
        onTap: () {},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: () {},
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