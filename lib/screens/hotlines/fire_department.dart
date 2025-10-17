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
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/MDFRVI',
      'phoneUri': 'tel:09940096243',
      'color': Colors.redAccent,
    },
    {
      'name': 'Tanduay - Fire Station',
      'number': '+63 993 483 2700',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/bfp.ncr.tanduay.fs',
      'phoneUri': 'tel:09934832700',
      'color': Colors.redAccent,
    },
    {
      'name': 'Paco - Fire Station',
      'number': '+63 976 483 6353',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/pacofspaco',
      'phoneUri': 'tel:09764836353',
      'color': Colors.redAccent,
    },
    {
      'name': 'Intramuros - Fire Station',
      'number': '+63 956 958 6301',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/intramuros.firestation',
      'phoneUri': 'tel:09569586301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Pandacan - Fire Station',
      'number': '+63 950 429 2897',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/pandacan.fss.3',
      'phoneUri': 'tel:09504292897',
      'color': Colors.redAccent,
    },
    {
      'name': 'San Lazaro - Fire Station',
      'number': '+63 928 940 6032',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/sanlazaro.engine',
      'phoneUri': 'tel:09289406032',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sta Mesa - Fire Station',
      'number': '+63 917 635 8578',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/stamesafss',
      'phoneUri': 'tel:09176358578',
      'color': Colors.redAccent,
    },
    {
      'name': 'Gagalangin - Fire Station',
      'number': '+63 976 045 7030',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/gagalangin.firestation',
      'phoneUri': 'tel:09760457030',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sta Ana - Fire Station',
      'number': '+63 915 484 6575',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100042525486496',
      'phoneUri': 'tel:09154846575',
      'color': Colors.redAccent,
    },
    {
      'name': 'Sampaloc - Fire Station',
      'number': '+63 905 692 3584',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/fs.sampaloc.3?rdid=IA0PV9I5hAhGO72l&share_url=https%3A%2F%2Fwww.facebook.com%2Fshare%2F1A7YFxeGVE#',
      'phoneUri': 'tel:09056923584',
      'color': Colors.redAccent,
    },
    {
      'name': 'Malacañang - Fire Station',
      'number': '+63 956 816 8301',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/mfs.fam.92',
      'phoneUri': 'tel:09568168301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Bacood - Fire Station',
      'number': '+63 912 542 0294',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=61571422847293',
      'phoneUri': 'tel:09125420294',
      'color': Colors.redAccent,
    },
    {
      'name': 'Malacañang - Fire Station',
      'number': '+63 956 816 8301',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/trese.161',
      'phoneUri': 'tel:09568168301',
      'color': Colors.redAccent,
    },
    {
      'name': 'Arroceros - Fire Station',
      'number': '+63 995 987 0248',
      'description': 'Responds to fire emergencies and promotes fire safety and prevention.',
      'facebookUrl': 'https://www.facebook.com/profile.php?id=100064616057050',
      'phoneUri': 'tel:09959870248',
      'color': Colors.redAccent,
    },
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8F9FA);

    final filtered = _fireHotlines.where((h) {
      return h['name'].toString().toLowerCase().contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Fire Department Hotlines',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
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
                    hintText: 'Search fire station...',
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
                              'No fire stations found',
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
                                  Icons.local_fire_department,
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