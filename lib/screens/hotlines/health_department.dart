import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthDepartmentPage extends StatefulWidget {
  const HealthDepartmentPage({super.key});

  @override
  State<HealthDepartmentPage> createState() => _HealthDepartmentPageState();
}

class _HealthDepartmentPageState extends State<HealthDepartmentPage> {
  final List<Map<String, dynamic>> _hotlines = [
    {
      'name': 'Sampaloc Manila Hospital',
      'number': '+63 960 588 9068',
      'description':
          'Provides health services, responds to medical emergencies and outbreaks.',
      'facebookUrl': 'https://www.facebook.com/OspitalNgSampalocManila/',
      'phoneUri': 'tel:09605889068',
      'color': Colors.green,
    },
    {
      'name': 'Sample Call',
      'number': '+63 977 778 8472',
      'description': 'Emergency health response and blood donation services.',
      'facebookUrl': 'https://www.facebook.com/phredcross',
      'phoneUri': 'tel:09777788472',
      'color': Colors.green,
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
        title: const Text('Health Department Hotlines'),
        backgroundColor: Colors.green,
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
                                    Icons.local_hospital,
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
