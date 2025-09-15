import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:project_radar_app/screens/alerts/report_detail_screen.dart';

class ReportTrackerScreen extends StatefulWidget {
  const ReportTrackerScreen({super.key});

  @override
  State<ReportTrackerScreen> createState() => _ReportTrackerScreenState();
}

class _ReportTrackerScreenState extends State<ReportTrackerScreen> {
  String _filter = "24h";

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.report_problem_outlined, 
                  size: 64, 
                  color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text("Authentication Required",
                  style: TextStyle(
                      color: Colors.grey[800], 
                      fontSize: 20, 
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text("Please log in to view your reports",
                  style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: 15)),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F73A3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: const Text("Sign In", 
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "My Incident Reports",
            style: TextStyle(
                fontWeight: FontWeight.w800, 
                fontSize: 22, 
                letterSpacing: -0.8),
          ),
          backgroundColor: const Color(0xFF3F73A3),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: const Color(0xFF3F73A3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Color(0xFF3F73A3),
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: "Ongoing"),
                    Tab(text: "Resolved"),
                    Tab(text: "Others"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportsList(userId: currentUser.uid, filterResolved: false),
            _buildReportsList(userId: currentUser.uid, filterResolved: true),
            _buildFilteredResolvedReports(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList({required String userId, required bool filterResolved}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState("Unable to load reports.");
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(filterResolved);
        }

        final docs = snapshot.data!.docs;
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          return filterResolved ? status == "resolved" : status != "resolved";
        }).toList();

        if (filteredDocs.isEmpty) return _buildEmptyState(filterResolved);

        filteredDocs.sort((a, b) {
          final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          return bTimestamp.compareTo(aTimestamp);
        });

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final incident = filteredDocs[index];
            final data = incident.data() as Map<String, dynamic>;

            final incidentType = data['incidentType'] ?? 'Unknown';
            final description = data['description'] ?? '';
            final status = data['status'] ?? 'Pending';
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
                : 'Date not available';

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailScreen(report: incident),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                incidentType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Color(0xFF2C3E50),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(status).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Text(formattedDate,
                                style: TextStyle(
                                    color: Colors.grey[600], 
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          description,
                          style: TextStyle(
                              color: Colors.grey[700], 
                              fontSize: 15, 
                              height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "View Details",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

Widget _buildFilteredResolvedReports() {
  return Column(
    children: [
      // 🔹 Filter chips UI
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilterChip(
              label: const Text("Today",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _filter == "24h",
              onSelected: (_) => setState(() => _filter = "24h"),
              selectedColor: const Color(0xFF3F73A3),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _filter == "24h" ? Colors.white : Colors.grey[700],
              ),
            ),
            FilterChip(
              label: const Text("7 Days",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _filter == "7d",
              onSelected: (_) => setState(() => _filter = "7d"),
              selectedColor: const Color(0xFF3F73A3),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _filter == "7d" ? Colors.white : Colors.grey[700],
              ),
            ),
            FilterChip(
              label: const Text("All",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _filter == "all",
              onSelected: (_) => setState(() => _filter = "all"),
              selectedColor: const Color(0xFF3F73A3),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _filter == "all" ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 8),

      // 🔹 Reports list with incidentType included
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('incidents')
              .where('status', isEqualTo: 'resolved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildErrorState("Unable to load resolved reports.");
            if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(true);

            final now = DateTime.now();
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              if (ts == null) return false;
              final date = ts.toDate();

              if (_filter == "24h") {
                return date.isAfter(now.subtract(const Duration(hours: 24)));
              } else if (_filter == "7d") {
                return date.isAfter(now.subtract(const Duration(days: 7)));
              }
              return true; // all
            }).toList();

            docs.sort((a, b) {
              final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aTimestamp == null && bTimestamp == null) return 0;
              if (aTimestamp == null) return 1;
              if (bTimestamp == null) return -1;
              return bTimestamp.compareTo(aTimestamp);
            });

            if (docs.isEmpty) return _buildEmptyState(true);

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                final incidentType = data['incidentType'] ?? 'Unknown';
                final description = data['description'] ?? '';
                final location = data['address'] ?? 'No location';
                final latitude = data['latitude']?.toString() ?? '';
                final longitude = data['longitude']?.toString() ?? '';
                final timestamp = data['timestamp'] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
                    : 'Unknown date';

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Incident type at the top
                        Text(
                          incidentType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF3F73A3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF2C3E50),
                            )),
                        const SizedBox(height: 8),
                        Text("📍 $location",
                            style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("Coordinates: $latitude, $longitude",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("🕒 $formattedDate",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildAllResolvedReports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .where('status', isEqualTo: 'resolved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState("Unable to load resolved reports.");
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(true);

        final now = DateTime.now();
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['timestamp'] as Timestamp?;
          if (ts == null) return false;
          final date = ts.toDate();

          if (_filter == "24h") {
            return date.isAfter(now.subtract(const Duration(hours: 24)));
          } else if (_filter == "7d") {
            return date.isAfter(now.subtract(const Duration(days: 7)));
          }
          return true; // all
        }).toList();

        docs.sort((a, b) {
          final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          return bTimestamp.compareTo(aTimestamp);
        });

        if (docs.isEmpty) return _buildEmptyState(true);

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final description = data['description'] ?? '';
            final location = data['address'] ?? 'No location specified';
            final latitude = data['latitude']?.toString() ?? '';
            final longitude = data['longitude']?.toString() ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
                : 'Unknown date';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, 
                              size: 20, 
                              color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text("Resolved Incident",
                              style: TextStyle(
                                  color: Colors.grey[700], 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2C3E50))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, 
                              size: 16, 
                              color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(location,
                                style: TextStyle(
                                    color: Colors.grey[700], 
                                    fontSize: 14)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.map, 
                              size: 16, 
                              color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text("Coordinates: $latitude, $longitude",
                              style: TextStyle(
                                  color: Colors.grey[600], 
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, 
                              size: 16, 
                              color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(formattedDate,
                              style: TextStyle(
                                  color: Colors.grey[600], 
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF3F73A3)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading your reports...",
            style: TextStyle(
                color: Colors.grey[600], 
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

Widget _buildEmptyState(bool filterResolved) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,   // ✅ vertical center
      crossAxisAlignment: CrossAxisAlignment.center, // ✅ horizontal center
      children: [
        Icon(
          filterResolved ? Icons.check_circle_outline : Icons.inbox,
          size: 70,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 20),
        Text(
          filterResolved ? "No Resolved Reports" : "No Ongoing Reports",
          style: TextStyle(
              color: Colors.grey[700], 
              fontSize: 19, 
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          filterResolved 
              ? "All your reports are currently being processed"
              : "You haven't submitted any reports yet",
          style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}


  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, 
              size: 70, 
              color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text("Something went wrong",
              style: TextStyle(
                  color: Colors.grey[800], 
                  fontSize: 19, 
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, 
                style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 15),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F73A3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            child: const Text("Try Again", 
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'under review':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }
}