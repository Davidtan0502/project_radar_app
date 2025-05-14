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
      'number': '+63 994 009 6243',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:09940096243',
      'color': Colors.redAccent,
    },
    {
      'name': 'Tanduay - Fire Station',
      'number': '+63 993 483 2700',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/bfp.ncr.tanduay.fs',
      'phoneUri': 'tel:09934832700',
      'color': Colors.redAccent,
    },
    {
      'name': 'Paco - Fire Station',
      'number': '+63 976 483 6353',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/pacofspaco',
      'phoneUri': 'tel:09764836353',
      'color': Colors.redAccent,
    },
    {
      'name': 'Intramuros - Fire Station',
      'number': '+63 956 958 6301',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/intramuros.firestation',
      'phoneUri': 'tel:09569586301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Pandacan - Fire Station',
      'number': '+63 950 429 2897',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/pandacan.fss.3',
      'phoneUri': 'tel:09504292897',
      'color': Colors.redAccent,
    },
    {
      'name': 'San Lazaro - Fire Station',
      'number': '+63 928 940 6032',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/sanlazaro.engine',
      'phoneUri': 'tel:09289406032',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sta Mesa - Fire Station',
      'number': '+63 917 635 8578',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/stamesafss',
      'phoneUri': 'tel:09176358578',
      'color': Colors.redAccent,
    },
    {
      'name': 'Gagalangin - Fire Station',
      'number': '+63 976 045 7030',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/gagalangin.firestation',
      'phoneUri': 'tel:09760457030',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sta Ana - Fire Station',
      'number': '+63 915 484 6575',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100042525486496',
      'phoneUri': 'tel:09154846575',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sampaloc - Fire Station',
      'number': '+63 905 692 3584',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:09056923584',
      'color': Colors.redAccent,
    },
    {
      'name': 'Malacañang - Fire Station',
      'number': '+63 956 816 8301',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/mfs.fam.92',
      'phoneUri': 'tel:09568168301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Bacood - Fire Station',
      'number': '+63 912 542 0294',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=61571422847293',
      'phoneUri': 'tel:09125420294',
      'color': Colors.redAccent,
    },
    {
      'name': 'Malacañang - Fire Station',
      'number': '+63 956 816 8301',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/trese.161',
      'phoneUri': 'tel:09568168301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Arroceros - Fire Station',
      'number': '+63 995 987 0248',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/trese.161',
      'phoneUri': 'tel:09959870248',
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
