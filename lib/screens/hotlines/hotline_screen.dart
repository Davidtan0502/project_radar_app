import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project_radar_app/screens/hotlines/fire_department.dart';
import 'package:project_radar_app/screens/hotlines/health_department.dart';
import 'package:project_radar_app/screens/hotlines/police_department.dart';

class HotlinesPage extends StatefulWidget {
  const HotlinesPage({super.key});

  @override
  State<HotlinesPage> createState() => _HotlinesPageState();
}

class _HotlinesPageState extends State<HotlinesPage> {
  String _searchText = '';
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _hotlines = [
    {
      'name': 'Manila City Disaster Risk Reduction Management Office',
      'number': '+63 950 700 3710',
      'description':
          'Handles disaster preparedness, response, and mitigation in Manila.',
      'facebookUrl': 'https://www.facebook.com/sagipmanila',
      'phoneUri': 'tel:0950 700 3710',
      'color': Colors.blue,
    },
    {
      'name': 'Manila Health Department (MHD)',
      'number': '+63 936 992 5513',
      'description':
          'Provides health services, responds to medical emergencies and outbreaks.',
      'facebookUrl': 'https://www.facebook.com/manilahealthdepartment',
      'phoneUri': 'tel:0936 992 5513',
      'color': Colors.green,
    },
    {
      'name': 'Manila Police District (MPD)',
      'number': '+63 917 899 2092',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/manilapolicedistrict2017',
      'phoneUri': 'tel:0917 899 2092',
      'color': Colors.indigo,
    },
    {
      'name': 'Manila District Fire and Rescue Volunteer',
      'number': '+63 2 527-6951',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:0 252 769 51',
      'color': Colors.redAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered =
        _hotlines.where((h) {
          return h['name'].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          );
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF336699),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(
            top: 36,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Emergency Hotlines',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.phone_in_talk_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search hotline...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (t) => setState(() => _searchText = t),
            ),
            const SizedBox(height: 16),

            // Scrollable list of hotlines + department buttons
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filtered.length + 4,
                itemBuilder: (ctx, i) {
                  if (i < filtered.length) {
                    final h = filtered[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == filtered.length - 1 ? 16 : 16,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor: h['color'].withOpacity(0.3),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: h['color'],
                            child: const Icon(
                              Icons.local_phone,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            h['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            h['number'],
                            style: TextStyle(color: h['color']),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h['description'],
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.parse(h['phoneUri']);
                                          if (!await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          )) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not open Phone App.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.call,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Call',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: h['color'],
                                          minimumSize: const Size(140, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.parse(
                                            h['facebookUrl'],
                                          );
                                          if (!await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          )) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not open Facebook.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.facebook),
                                        label: const Text('Facebook'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: h['color'],
                                          side: BorderSide(color: h['color']),
                                          minimumSize: const Size(140, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (i == filtered.length) {
                    return const SizedBox(height: 16);
                  } else if (i == filtered.length + 1) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.local_fire_department),
                      label: const Text(
                        'Fire Department',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size.fromHeight(80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FireDepartmentPage(),
                            ),
                          ),
                    );
                  } else if (i == filtered.length + 2) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.local_hospital),
                        label: const Text(
                          'Health Department',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HealthDepartmentPage(),
                              ),
                            ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.local_police),
                        label: const Text(
                          'Police Department',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.indigo,
                          minimumSize: const Size.fromHeight(80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PoliceDepartmentPage(),
                              ),
                            ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
