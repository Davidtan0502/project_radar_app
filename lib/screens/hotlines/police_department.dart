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
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/RaxabagoTondo',
      'phoneUri': 'tel:09985987894',
      'color': Colors.indigo,
    },
    {
      'name': 'Moriones - Tondo Police Station',
      'number': '+63 998 598 7896',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/MorionesTondoPS2',
      'phoneUri': 'tel:09985987896',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Cruz Police Station',
      'number': '+63 998 598 7898',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/mpd.psthree',
      'phoneUri': 'tel:09985987898',
      'color': Colors.indigo,
    },
    {
      'name': 'Sampaloc Police Station',
      'number': '+63 998 598 7900',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/PS4mpd',
      'phoneUri': 'tel:09985987900',
      'color': Colors.indigo,
    },
    {
      'name': 'Ermita Police Station',
      'number': '+63 998 598 7902',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/estacion.ermita',
      'phoneUri': 'tel:09985987902',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Ana Police Station',
      'number': '+63 998 598 7904',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100080997518053',
      'phoneUri': 'tel:09985987904',
      'color': Colors.indigo,
    },
    {
      'name': 'Jose Abad Santos Police Station',
      'number': '+63 998 598 7906',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/jas.siete',
      'phoneUri': 'tel:09985987906',
      'color': Colors.indigo,
    },
    {
      'name': 'Sta Mesa Police Station',
      'number': '+63 998 598 7908',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/StaMesaPoliceStationPS8',
      'phoneUri': 'tel:09985987908',
      'color': Colors.indigo,
    },
    {
      'name': 'Malate Police Station',
      'number': '+63 998 598 7909',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100063710633871',
      'phoneUri': 'tel:09985987909',
      'color': Colors.indigo,
    },
    {
      'name': 'Pandacan Police Station',
      'number': '+63 998 598 7912',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/pandacan10',
      'phoneUri': 'tel:09985987912',
      'color': Colors.indigo,
    },
    {
      'name': 'Meisic Police Station',
      'number': '+63 998 598 7914',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/binondops.mpdreact',
      'phoneUri': 'tel:09985987914',
      'color': Colors.indigo,
    },
    {
      'name': 'Delpan Police Station',
      'number': '+63 963 500 1054',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100087532271461',
      'phoneUri': 'tel:09635001054',
      'color': Colors.indigo,
    },
    {
      'name': 'Baseco Police Station',
      'number': '+63 939 618 1340',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/basecopolicestation',
      'phoneUri': 'tel:09396181340',
      'color': Colors.indigo,
    },
    {
      'name': 'Barbosa Police Station',
      'number': '+63 920 518 7080',
      'description': 'Maintains peace and order, responds to emergencies and crime scenes.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=61561626107272',
      'phoneUri': 'tel:09205187080',
      'color': Colors.indigo,
    },
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8F9FA);

    final filtered = _hotlines.where((h) {
      return h['name'].toString().toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Police Department Hotlines',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search police station...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF28588B)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                  onChanged: (t) => setState(() => _searchText = t),
                ),
              ),
              
              const SizedBox(height: 20),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No police stations found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching with different keywords',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final h = filtered[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.all(20),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: h['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_police,
                                  color: h['color'],
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                h['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                h['number'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: h['color'],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h['description'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final uri = Uri.parse(h['phoneUri']);
                                                if (!await launchUrl(
                                                  uri,
                                                  mode: LaunchMode.externalApplication,
                                                )) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Could not open Phone App.'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.call, color: Colors.white, size: 20),
                                              label: const Text(
                                                'Call',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: h['color'],
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                final uri = Uri.parse(h['facebookUrl']);
                                                if (!await launchUrl(
                                                  uri,
                                                  mode: LaunchMode.externalApplication,
                                                )) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Could not open Facebook.'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: Icon(Icons.facebook, color: h['color'], size: 20),
                                              label: Text(
                                                'Facebook',
                                                style: TextStyle(
                                                  color: h['color'],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                side: BorderSide(color: h['color']!),
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}