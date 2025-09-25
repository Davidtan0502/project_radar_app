import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:project_radar_app/screens/alerts/report_detail_screen.dart';

class ReportTrackerScreen extends StatefulWidget {
  final int initialTab;
  final String? highlightIncidentId;

  const ReportTrackerScreen({
    super.key,
    this.initialTab = 0,
    this.highlightIncidentId,
  });

  @override
  State<ReportTrackerScreen> createState() => _ReportTrackerScreenState();
}

class _ReportTrackerScreenState extends State<ReportTrackerScreen> {
  final ReportTrackerController _controller = ReportTrackerController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.setHighlightIncidentId(widget.highlightIncidentId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildAuthenticationRequiredView();
    }

    return _buildMainContent(currentUser.uid);
  }

  Widget _buildAuthenticationRequiredView() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text("Authentication Required",
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text("Please log in to view your reports",
                style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: _authButtonStyle(),
              child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(String userId) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: TabBarView(
          children: [
            _buildReportsList(userId: userId, filterResolved: false),
            _buildReportsList(userId: userId, filterResolved: true),
            _buildFilteredResolvedReports(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildReportsList({
    required String userId,
    required bool filterResolved,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getUserIncidentsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState("Unable to load reports.");
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(filterResolved);
        }

        final incidents = _controller.filterAndSortIncidents(
          snapshot.data!.docs,
          filterResolved: filterResolved,
        );

        if (incidents.isEmpty) return _buildEmptyState(filterResolved);

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            final isHighlighted = incident.id == _controller.highlightIncidentId;
            
            return IncidentCard(
              incident: incident,
              isHighlighted: isHighlighted,
              showDelete: !filterResolved,
              onTap: () => _navigateToDetail(incident),
              onDelete: () => _showDeleteConfirmation(incident.id),
              onHighlightRemoved: () => _controller.clearHighlight(),
            );
          },
        );
      },
    );
  }

  Widget _buildFilteredResolvedReports() {
    return Column(
      children: [
        _buildSearchAndFilterSection(),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _controller.getResolvedIncidentsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState("Unable to load resolved reports.");
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(true);
              }

              final incidents = _controller.filterResolvedIncidents(
                snapshot.data!.docs,
                searchQuery: _controller.searchQuery,
                timeFilter: _controller.timeFilter,
              );

              if (incidents.isEmpty) return _buildEmptyState(true);

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16,
                ),
                itemCount: incidents.length,
                itemBuilder: (context, index) {
                  return ResolvedIncidentCard(
                    incident: incidents[index],
                    onTap: () => _navigateToDetail(incidents[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Search reports...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() {
              _controller.setSearchQuery(value.toLowerCase());
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip("Today", "24h"),
              _buildFilterChip("7 Days", "7d"),
              _buildFilterChip("All", "all"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      selected: _controller.timeFilter == value,
      onSelected: (_) => setState(() => _controller.setTimeFilter(value)),
      selectedColor: const Color(0xFF3F73A3),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: _controller.timeFilter == value ? Colors.white : Colors.grey[700],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF3F73A3)),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            "Loading your reports...",
            style: TextStyle(
                color: Colors.grey,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filterResolved ? Icons.check_circle_outline : Icons.inbox,
            size: 70,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            filterResolved ? "No Resolved Reports" : "No Ongoing Reports",
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 19,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            filterResolved
                ? "All your reports are currently being processed"
                : "You haven't submitted any reports yet",
            style: const TextStyle(color: Colors.grey, fontSize: 15),
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
          Icon(Icons.error_outline, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text("Something went wrong",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 19,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: _authButtonStyle(),
            child: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  ButtonStyle _authButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3F73A3),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
    );
  }

  void _navigateToDetail(DocumentSnapshot incident) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: incident),
      ),
    );
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DeleteConfirmationDialog(
        onConfirm: () => _controller.deleteReport(docId, context),
      ),
    );
  }
}

// Controller class for business logic
class ReportTrackerController {
  String? highlightIncidentId;
  String searchQuery = "";
  String timeFilter = "24h";

  Stream<QuerySnapshot> getUserIncidentsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('incidents')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getResolvedIncidentsStream() {
    return FirebaseFirestore.instance
        .collection('incidents')
        .where('status', isEqualTo: 'resolved')
        .snapshots();
  }

  List<DocumentSnapshot> filterAndSortIncidents(
    List<DocumentSnapshot> docs, {
    required bool filterResolved,
  }) {
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      return filterResolved ? status == "resolved" : status != "resolved";
    }).toList();

    filtered.sort((a, b) {
      final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });

    return filtered;
  }

  List<DocumentSnapshot> filterResolvedIncidents(
    List<DocumentSnapshot> docs, {
    required String searchQuery,
    required String timeFilter,
  }) {
    final now = DateTime.now();
    
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['timestamp'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();

      // Time filter
      if (timeFilter == "24h" && date.isBefore(now.subtract(const Duration(hours: 24)))) {
        return false;
      }
      if (timeFilter == "7d" && date.isBefore(now.subtract(const Duration(days: 7)))) {
        return false;
      }

      // Search filter
      if (searchQuery.isNotEmpty) {
        final incidentType = (data['incidentType'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        if (!incidentType.contains(searchQuery) && !description.contains(searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> deleteReport(String docId, BuildContext context) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('incidents').doc(docId);
      final docSnapshot = await docRef.get();

      Map<String, dynamic>? deletedData;
      if (docSnapshot.exists) {
        deletedData = docSnapshot.data() as Map<String, dynamic>;
      }

      await docRef.delete();

      _showUndoSnackbar(context, docId, deletedData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting report: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUndoSnackbar(BuildContext context, String docId, Map<String, dynamic>? deletedData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Report deleted"),
        backgroundColor: Colors.red,
        action: deletedData != null
            ? SnackBarAction(
                label: "UNDO",
                textColor: Colors.white,
                onPressed: () => _restoreReport(docId, deletedData, context),
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _restoreReport(String docId, Map<String, dynamic> data, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(docId)
          .set(data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to restore: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void setHighlightIncidentId(String? incidentId) {
    highlightIncidentId = incidentId;
  }

  void clearHighlight() {
    highlightIncidentId = null;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
  }

  void setTimeFilter(String filter) {
    timeFilter = filter;
  }
}

// Incident Card Widget
class IncidentCard extends StatelessWidget {
  final DocumentSnapshot incident;
  final bool isHighlighted;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onHighlightRemoved;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.isHighlighted,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
    required this.onHighlightRemoved,
  });

  @override
  Widget build(BuildContext context) {
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
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isHighlighted ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
            if (isHighlighted) onHighlightRemoved();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(incidentType, status, isHighlighted),
                const SizedBox(height: 10),
                _buildDateRow(formattedDate),
                const SizedBox(height: 14),
                _buildDescription(description),
                const SizedBox(height: 16),
                _buildActionsRow(showDelete, onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String incidentType, String status, bool isHighlighted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            incidentType,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isHighlighted ? Colors.blue[800] : const Color(0xFF2C3E50),
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
    );
  }

  Widget _buildDateRow(String formattedDate) {
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          formattedDate,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Text(
      description,
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 15,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionsRow(bool showDelete, VoidCallback onDelete) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showDelete) _buildDeleteButton(onDelete),
        _buildViewDetailsButton(),
      ],
    );
  }

  Widget _buildDeleteButton(VoidCallback onDelete) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 22),
        onPressed: onDelete,
        tooltip: 'Delete Report',
        splashRadius: 20,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildViewDetailsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3F73A3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F73A3).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "View Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return const Color(0xFF4CAF50);
      case 'pending': return const Color(0xFFFF9800);
      case 'in progress': return const Color(0xFF2196F3);
      case 'under review': return const Color(0xFF9C27B0);
      case 'declined': return const Color(0xFFF44336);
      default: return const Color(0xFF607D8B);
    }
  }
}

// Resolved Incident Card Widget
class ResolvedIncidentCard extends StatelessWidget {
  final DocumentSnapshot incident;
  final VoidCallback onTap;

  const ResolvedIncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = incident.data() as Map<String, dynamic>;
    final incidentType = data['incidentType'] ?? 'Unknown';
    final description = data['description'] ?? '';
    final location = data['address'] ?? 'No location';
    final latitude = data['latitude']?.toString() ?? '';
    final longitude = data['longitude']?.toString() ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(incidentType),
                const SizedBox(height: 12),
                _buildDescription(description),
                const SizedBox(height: 8),
                _buildLocationInfo(location, latitude, longitude),
                const SizedBox(height: 4),
                _buildDateInfo(formattedDate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String incidentType) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          incidentType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF3F73A3),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "RESOLVED",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Text(
      description,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildLocationInfo(String location, String latitude, String longitude) {
    return Text(
      "📍 $location",
      style: TextStyle(color: Colors.grey[700], fontSize: 14),
    );
  }

  Widget _buildDateInfo(String formattedDate) {
    return Text(
      "🕒 $formattedDate",
      style: TextStyle(color: Colors.grey[500], fontSize: 12),
    );
  }
}

// Delete Confirmation Dialog
class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Report"),
      content: const Text("Are you sure you want to delete your report? This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(backgroundColor: Colors.red[50]),
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}