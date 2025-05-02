import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FireDepartmentPage extends StatefulWidget {
  const FireDepartmentPage({super.key});

  @override
  State<FireDepartmentPage> createState() => _FireDepartmentPageState();
}

class _FireDepartmentPageState extends State<FireDepartmentPage> {
  final List<Map<String, dynamic>> _fireHotlines = [
    {
      'name': 'San Nicolas - Fire Station',
      'number': '+63 956-942-6172',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+639569426172',
      'color': Colors.redAccent,
    },
    {
      'name': 'Tanduay - Fire Station',
      'number': '+63 976-483-6353',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+639764836353',
      'color': Colors.redAccent,
    },
    {
      'name': 'Paco - Fire Station',
      'number': '+63 998-283-4355',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+639982834355',
      'color': Colors.redAccent,
    },
    {
      'name': 'Intramuros - Fire Station',
      'number': '+63 956-686-8201',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+63 9566868201',
      'color': Colors.redAccent,
    },
    {
      'name': 'Pandacan - Fire Station',
      'number': '+63 905-489-6601',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+63 9054896601',
      'color': Colors.redAccent,
    },
    {
      'name': 'Pandacan - Fire Station',
      'number': '+63 905-489-6601',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639985987894',
      'color': Colors.redAccent,
    },
    {
      'name': 'Tondo - Fire Station',
      'number': '+63 920-721-6126',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639207216126',
      'color': Colors.redAccent,
    },
    {
      'name': 'San Lazaro - Fire Station',
      'number': '+63 945-779-0717',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639457790717',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sta Mesa - Fire Station',
      'number': '+63 915-089-7830',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639150897830',
      'color': Colors.redAccent,
    },
    {
      'name': 'Gagalangin - Fire Station',
      'number': '+63 956-942-6172',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639569426172',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sta Ana - Fire Station',
      'number': '+63 995-218-0830',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639952180830',
      'color': Colors.redAccent,
    },
    {
      'name': 'Arroceros - Fire Station',
      'number': '+63 966-234-1645',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639662341645',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sampaloc - Fire Station',
      'number': '+63 967-526-2798',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639675262798',
      'color': Colors.redAccent,
    },
    {
      'name': 'Malacañang - Fire Station',
      'number': '+63 956-816-8301',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639568168301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Bacood - Fire Station',
      'number': '+63 966-293-8652',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639662938652',
      'color': Colors.redAccent,
    },
    {
      'name': 'SRF - Fire Station',
      'number': '+63 956-590-5141',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639565905141',
      'color': Colors.redAccent,
    },
    {
      'name': 'Ems San Lazaro / Comet Alpha - Fire Station',
      'number': '+63 967-580-4207',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639675804207',
      'color': Colors.redAccent,
    },
    {
      'name': 'Ems Intramuros / Comet Bravo - Fire Station',
      'number': '+63 998-546-6555',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639985466555',
      'color': Colors.redAccent,
    },
    {
      'name': 'Ems Sampaloc / Comet Charlie - Fire Station',
      'number': '+63 966-409-8706',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639664098706',
      'color': Colors.redAccent,
    },
    {
      'name': 'Commel Manila - Fire Station',
      'number': '+63 969-398-9700',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639693989700',
      'color': Colors.redAccent,
    },
    {
      'name': 'Bureau of Fire - NCR Intramuros FS',
      'number': '+63 956 958 6301',
      'description': 'Responds to fire emergencies and promotes fire safety.',
      'facebookUrl': 'https://www.facebook.com/intramuros.firestation',
      'phoneUri': 'tel:+639569586301',
      'color': Colors.redAccent,
    },
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        _fireHotlines.where((h) {
          return h['name'].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text('Fire Department Hotlines'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            Expanded(
              child:
                  filtered.isEmpty
                      ? const Center(child: Text('No results found.'))
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final h = filtered[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == filtered.length - 1 ? 0 : 16,
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
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  h['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h['description'],
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final uri = Uri.parse(
                                                  h['phoneUri'],
                                                );
                                                if (!await launchUrl(
                                                  uri,
                                                  mode:
                                                      LaunchMode
                                                          .externalApplication,
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
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: h['color'],
                                                minimumSize: const Size(
                                                  140,
                                                  40,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
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
                                                      LaunchMode
                                                          .externalApplication,
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
                                                side: BorderSide(
                                                  color: h['color'],
                                                ),
                                                minimumSize: const Size(
                                                  140,
                                                  40,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
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
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
