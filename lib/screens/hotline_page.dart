import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HotlinesPage extends StatefulWidget {
  const HotlinesPage({super.key});

  @override
  State<HotlinesPage> createState() => _HotlinesPageState();
}

class _HotlinesPageState extends State<HotlinesPage> {
  String _searchText = '';

  final List<Map<String, dynamic>> _hotlines = [
    {
      'name': 'Manila City Disaster Risk Reduction and Management Office (MCDRRMO)',
      'number': '+63 950 700 3710',
      'description': 'The MCDRRMO handles disaster preparedness, response, and mitigation in Manila, including dealing with floods, earthquakes, and other emergencies.',
      'facebookUrl': 'https://www.facebook.com/sagipmanila',
      'phoneUri': 'tel:+639507003710',
      'color': Colors.blue,
    },
    {
      'name': 'Manila Health Department (MHD)',
      'number': '+63 2 711-4145 (MHD Hotline)',
      'description': 'The Manila Health Department is responsible for addressing health-related emergencies, managing medical outbreaks, and providing health services to the public.',
      'facebookUrl': 'https://www.facebook.com/manilahealthdepartment',
      'phoneUri': 'tel:+6327114145',
      'color': Colors.green,
    },
    {
      'name': 'Manila Police District (MPD)',
      'number': '+63 917 899 2092',
      'description': 'The MPD is responsible for law enforcement, maintaining peace and order, and responding to emergency situations in Manila City.',
      'facebookUrl': 'https://www.facebook.com/manilapolicedistrict2017',
      'phoneUri': 'tel:+639178992092',
      'color': Colors.blueAccent,
    },
    {
      'name': 'Manila Bureau of Fire Protection (BFP)',
      'number': '+63 2 527-6951 (Hotline)',
      'description': 'The Manila BFP handles fire emergencies, rescues, and fire prevention within the city. They also provide safety education and respond to disasters.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+6325276951',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredHotlines = _hotlines.where((hotline) {
      return hotline['name']
          .toString()
          .toLowerCase()
          .contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Hotline',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (text) {
                setState(() {
                  _searchText = text;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredHotlines.length,
                itemBuilder: (context, index) {
                  final hotline = filteredHotlines[index];
                  return ExpansionTile(
                    title: Text(
                      hotline['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, 
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hotline['description']),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final Uri url = Uri.parse(hotline['phoneUri']);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                  child: Text(
                                    hotline['number'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hotline['color'],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final Uri url = Uri.parse(hotline['facebookUrl']);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                  child: Text(
                                    'Facebook Page',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hotline['color'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
