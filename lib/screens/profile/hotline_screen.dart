import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      'phoneUri': 'tel:+639507003710',
      'color': Colors.blue,
    },
    {
      'name': 'Manila Health Department (MHD)',
      'number': '+63 936 992 5513',
      'description':
          'Provides health services, responds to medical emergencies and outbreaks.',
      'facebookUrl': 'https://www.facebook.com/manilahealthdepartment',
      'phoneUri': 'tel:+639369925513',
      'color': Colors.green,
    },
    {
      'name': 'Manila Police District (MPD)',
      'number': '+63 917 899 2092',
      'description':
          'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/manilapolicedistrict2017',
      'phoneUri': 'tel:+639178992092',
      'color': Colors.indigo,
    },
    {
      'name': 'Manila District Fire and Rescue Volunteer',
      'number': '+63 2 527-6951',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:+6325276951',
      'color': Colors.redAccent,
    },
    {
      'name': 'Bureau of Fire - NCR Intramuros FS',
      'number': '+63 956 958 6301',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/intramuros.firestation',
      'phoneUri': 'tel:+639569586301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Raxabago - Tondo Police Station',
      'number': '+63 998 598 7894',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:+639985987894',
      'color': Colors.indigo,
    },
    {
      'name': 'Moriones - Tondo Police Station',
      'number': '+63 998 598 7896',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MorionesTondoPS2',
      'phoneUri': 'tel:+639985987896',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Cruz Police Station',
      'number': '+63 998 598 7898',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/mpd.psthree',
      'phoneUri': 'tel:+639985987898',
      'color': Colors.indigo,
    },
    {
      'name': 'Sampaloc Police Station',
      'number': '+63 998 598 7900',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/PS4mpd',
      'phoneUri': 'tel:+639985987900',
      'color': Colors.indigo,
    },
    {
      'name': 'Ermita Police Station',
      'number': '+63 998 598 7902',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/estacion.ermita',
      'phoneUri': 'tel:+639985987902',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Ana Police Station',
      'number': '+63 998 598 7904',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100080997518053',
      'phoneUri': 'tel:+639985987904',
      'color': Colors.indigo,
    },
    {
      'name': 'Jose Abad Santos Police Station',
      'number': '+63 998 598 7906',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/jas.siete',
      'phoneUri': 'tel:+639985987906',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Mesa Police Station',
      'number': '+63 998 598 7908',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/StaMesaPoliceStationPS8',
      'phoneUri': 'tel:+639985987908',
      'color': Colors.indigo,
    },
    {
      'name': 'Malate Police Station',
      'number': '+63 998 598 7909',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100063710633871',
      'phoneUri': 'tel:+639985987909',
      'color': Colors.indigo,
    },
    {
      'name': 'Pandacan Police Station',
      'number': '+63 998 598 7912',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/pandacan10',
      'phoneUri': 'tel:+639985987912',
      'color': Colors.indigo,
    },
    {
      'name': 'Meisic Police Station',
      'number': '+63 998 598 7914',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/binondops.mpdreact',
      'phoneUri': 'tel:+639985987914',
      'color': Colors.indigo,
    },
    {
      'name': 'Delpan Police Station',
      'number': '+63 963 500 1054',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100087532271461',
      'phoneUri': 'tel:+639635001054',
      'color': Colors.indigo,
    },
    {
      'name': 'Baseco Police Station',
      'number': '+63 939 618 1340',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/basecopolicestation',
      'phoneUri': 'tel:+639396181340',
      'color': Colors.indigo,
    },
    {
      'name': 'Barbosa Police Station',
      'number': '+63 920 518 7080',
      'description':
          'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=61561626107272',
      'phoneUri': 'tel:+639205187080',
      'color': Colors.indigo,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredHotlines =
        _hotlines.where((hotline) {
          return hotline['name'].toString().toLowerCase().contains(
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
            // Search Field
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
              onChanged: (text) {
                setState(() {
                  _searchText = text;
                });
              },
            ),
            const SizedBox(height: 16),

            // Hotline Cards
            Expanded(
              child:
                  filteredHotlines.isEmpty
                      ? const Center(
                        child: Text(
                          "No results found.",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredHotlines.length,
                        itemBuilder: (context, index) {
                          final hotline = filteredHotlines[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == filteredHotlines.length - 1 ? 0 : 16,
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                              shadowColor: hotline['color'].withOpacity(0.3),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  hotline['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  hotline['number'],
                                  style: TextStyle(color: hotline['color']),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: hotline['color'],
                                  child: const Icon(
                                    Icons.local_phone,
                                    color: Colors.white,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hotline['description'],
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
                                                  hotline['phoneUri'],
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
                                                backgroundColor:
                                                    hotline['color'],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final uri = Uri.parse(
                                                  hotline['facebookUrl'],
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
                                                foregroundColor:
                                                    hotline['color'],
                                                side: BorderSide(
                                                  color: hotline['color'],
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
