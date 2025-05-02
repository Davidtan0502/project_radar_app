import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliceDepartmentPage extends StatefulWidget {
  const PoliceDepartmentPage({super.key});

  @override
  State<PoliceDepartmentPage> createState() => _PoliceDepartmentPageState();
}

class _PoliceDepartmentPageState extends State<PoliceDepartmentPage> {
  final List<Map<String, dynamic>> _hotlines = [
    {
      'name': 'Raxabago - Tondo Police Station',
      'number': '+63 998 598 7894',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:0998 598 7894',
      'color': Colors.indigo,
    },
    {
      'name': 'Moriones - Tondo Police Station',
      'number': '+63 998 598 7896',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/MorionesTondoPS2',
      'phoneUri': 'tel:0998 598 7896',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Cruz Police Station',
      'number': '+63 998 598 7898',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/mpd.psthree',
      'phoneUri': 'tel:0998 598 7898',
      'color': Colors.indigo,
    },
    {
      'name': 'Sampaloc Police Station',
      'number': '+63 998 598 7900',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/PS4mpd',
      'phoneUri': 'tel:0998 598 7900',
      'color': Colors.indigo,
    },
    {
      'name': 'Ermita Police Station',
      'number': '+63 998 598 7902',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/estacion.ermita',
      'phoneUri': 'tel:0998 598 7902',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Ana Police Station',
      'number': '+63 998 598 7904',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100080997518053',
      'phoneUri': 'tel:0998 598 7904',
      'color': Colors.indigo,
    },
    {
      'name': 'Jose Abad Santos Police Station',
      'number': '+63 998 598 7906',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/jas.siete',
      'phoneUri': 'tel:0998 598 7906',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Mesa Police Station',
      'number': '+63 998 598 7908',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/StaMesaPoliceStationPS8',
      'phoneUri': 'tel:0998 598 7908',
      'color': Colors.indigo,
    },
    {
      'name': 'Malate Police Station',
      'number': '+63 998 598 7909',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100063710633871',
      'phoneUri': 'tel:0998 598 7909',
      'color': Colors.indigo,
    },
    {
      'name': 'Pandacan Police Station',
      'number': '+63 998 598 7912',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/pandacan10',
      'phoneUri': 'tel:0998 598 7912',
      'color': Colors.indigo,
    },
    {
      'name': 'Meisic Police Station',
      'number': '+63 998 598 7914',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/binondops.mpdreact',
      'phoneUri': 'tel:0998 598 7914',
      'color': Colors.indigo,
    },
    {
      'name': 'Delpan Police Station',
      'number': '+63 963 500 1054',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100087532271461',
      'phoneUri': 'tel:0963 500 1054',
      'color': Colors.indigo,
    },
    {
      'name': 'Baseco Police Station',
      'number': '+63 939 618 1340',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/basecopolicestation',
      'phoneUri': 'tel:0939 618 1340',
      'color': Colors.indigo,
    },
    {
      'name': 'Barbosa Police Station',
      'number': '+63 920 518 7080',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=61561626107272',
      'phoneUri': 'tel:0920 518 7080',
      'color': Colors.indigo,
    },
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filtered =
        _hotlines.where((h) {
          return h['name'].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          );
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Police Department Hotlines'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: const Color(0xFFF5F8FC),
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
                                    Icons.local_police,
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
