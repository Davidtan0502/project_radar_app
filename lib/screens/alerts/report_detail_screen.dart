import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class ReportDetailScreen extends StatefulWidget {
  final DocumentSnapshot report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _loading = false;
  bool _expanded = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _refreshReport() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.report.id)
          .get(const GetOptions(source: Source.server));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Report refreshed successfully"),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      debugPrint("Error refreshing report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to refresh report"),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLocationOnMap(String address) {
    // This would integrate with your map functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening map for: $address'),
        backgroundColor: Colors.blue[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Report Details"),
        backgroundColor: const Color(0xFF3F73A3),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReport,
            tooltip: 'Refresh report',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(),
            tooltip: 'Share report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReport,
        color: const Color(0xFF3F73A3),
        backgroundColor: Colors.white,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('incidents')
              .doc(widget.report.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (_loading && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildNotFoundState();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            return _buildReportContent(data);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "Error loading report",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshReport,
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Report not found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "This report may have been deleted",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String rawAddress, String barangay, String city) {
    if (barangay.isEmpty) {
      return rawAddress;
    }
    
    // Check if barangay is already part of the address
    if (rawAddress.toLowerCase().contains(barangay.toLowerCase())) {
      return rawAddress;
    }
    
    // Check if barangay is the same as city (common when Google Maps doesn't have barangay data)
    if (city.isNotEmpty && barangay.toLowerCase() == city.toLowerCase()) {
      return rawAddress; // Don't add duplicate
    }
    
    // Check if address ends with city and barangay is different
    if (city.isNotEmpty && rawAddress.toLowerCase().endsWith(city.toLowerCase())) {
      // Replace city with barangay if they're different but address contains city
      if (barangay.toLowerCase() != city.toLowerCase()) {
        return '${rawAddress.substring(0, rawAddress.length - city.length).trim()}, $barangay';
      }
      return rawAddress;
    }
    
    // Default: add barangay to address
    return '$rawAddress, $barangay';
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    final String incidentType = data['incidentType'] ?? "Incident";
    final String description = data['description'] ?? "No description provided";
    final String status = data['status'] ?? "Pending";
    
    // Get address components
    final String rawAddress = data['address'] ?? "Unknown address";
    final String barangay = data['barangay'] ?? "";
    final String city = data['city'] ?? "";
    
    // Smart address formatting to avoid duplicates
    final String address = _formatAddress(rawAddress, barangay, city);
    
    final String name = data['name'] ?? "Anonymous";
    final String contactNumber = data['contactNumber'] ?? "Not provided";
    final double? latitude = data['latitude'] as double?;
    final double? longitude = data['longitude'] as double?;
    final bool requiresReview = data['requiresReview'] ?? false;
    final double suspicionScore = (data['suspicionScore'] ?? 0.0).toDouble();
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];

    final String formattedDate = data['timestamp'] != null
        ? DateFormat('MMMM d, yyyy')
            .format((data['timestamp'] as Timestamp).toDate())
        : "Unknown date";
    final String timeDetail = data['timestamp'] != null
        ? DateFormat('h:mm a')
            .format((data['timestamp'] as Timestamp).toDate())
        : "";

    final List<dynamic> statusUpdates = data['statusUpdates'] ?? [];

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderCard(
            incidentType,
            description,
            status,
            formattedDate,
            timeDetail,
            address,
            name,
            contactNumber,
            latitude,
            longitude,
            requiresReview,
            suspicionScore,
            imageUrls,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildTimeline(statusUpdates),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    String incidentType,
    String description,
    String status,
    String formattedDate,
    String timeDetail,
    String address,
    String name,
    String contactNumber,
    double? latitude,
    double? longitude,
    bool requiresReview,
    double suspicionScore,
    List<dynamic> imageUrls,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  incidentType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$formattedDate • $timeDetail',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          
          // Suspicion Score & Review Required
          if (requiresReview || suspicionScore > 0.5) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (requiresReview)
                  _buildWarningChip("Requires Review", Icons.warning_amber),
                if (suspicionScore > 0.5)
                  _buildWarningChip(
                    "Suspicion: ${(suspicionScore * 100).toStringAsFixed(0)}%", 
                    Icons.psychology
                  ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          // Description with expand/collapse
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("Description",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  description.length > 100
                      ? '${description.substring(0, 100)}...'
                      : description,
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey[700], height: 1.5),
                ),
                secondChild: Text(
                  description,
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey[700], height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Information rows
          _buildInfoRow(Icons.location_on, "Location", address,
              onTap: () => _showLocationOnMap(address),
              onCopy: () => _copyToClipboard(address, "Address copied")),
          _buildInfoRow(Icons.person, "Reported by", name,
              onCopy: () => _copyToClipboard(name, "Name copied")),
          _buildInfoRow(Icons.phone, "Contact", contactNumber,
              onCopy: () => _copyToClipboard(contactNumber, "Number copied")),
          
          // Coordinates if available
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 8),
            _buildCoordinatesRow(latitude, longitude),
          ],
          
          // Images if available
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImagesSection(imageUrls),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesSection(List<dynamic> imageUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Attached Images",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index] as String;
              return GestureDetector(
                onTap: () => _showImagePreview(context, imageUrl),
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWarningChip(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.orange[800]),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[800])),
        ],
      ),
    );
  }

  Widget _buildCoordinatesRow(double latitude, double longitude) {
    final coords = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    return GestureDetector(
      onTap: () => _copyToClipboard(coords, "Coordinates copied"),
      child: Row(
        children: [
          Icon(Icons.my_location, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Coordinates",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(coords,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Icon(Icons.copy, size: 16, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap, VoidCallback? onCopy}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3F73A3)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (onCopy != null)
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: Colors.grey[500]),
                onPressed: onCopy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> statusUpdates) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Status Timeline",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50))),
              const SizedBox(width: 8),
              Chip(
                label: Text(statusUpdates.length.toString()),
                backgroundColor: Colors.blue[50],
                labelStyle: const TextStyle(color: Colors.blue),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (statusUpdates.isEmpty)
            _buildEmptyTimeline()
          else
            _buildTimelineList(statusUpdates),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text("No updates yet",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text("Status updates will appear here",
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTimelineList(List<dynamic> statusUpdates) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: statusUpdates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final update = statusUpdates[index];
        return _buildTimelineItem(update, index == 0);
      },
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> update, bool isLatest) {
    final String statusText = update['status'] ?? "Unknown";
    final note = update['note'] ?? "";
    DateTime? updateTime;

    if (update['timestamp'] is Timestamp) {
      updateTime = (update['timestamp'] as Timestamp).toDate();
    } else if (update['timestamp'] is String) {
      try {
        updateTime = DateTime.parse(update['timestamp']);
      } catch (_) {}
    }

    final timeStr = updateTime != null ? DateFormat('MMM d').format(updateTime) : "";
    final timeDetail = updateTime != null ? DateFormat('h:mm a').format(updateTime) : "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(timeStr,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 13)),
        ),
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(statusText),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: isLatest
                    ? [
                        BoxShadow(
                          color: _getStatusColor(statusText).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
            Container(
                width: 3,
                height: 90,
                color: _getStatusColor(statusText).withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(statusText).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(statusText).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getStatusIcon(statusText),
                        size: 16, color: _getStatusColor(statusText)),
                    const SizedBox(width: 8),
                    Text(timeDetail,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(statusText,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(statusText))),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(note,
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareReport() async {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Share functionality coming soon"),
        backgroundColor: Colors.blue[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return const Color(0xFF2196F3);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'under review':
        return Colors.purple;
      case 'declined':
        return const Color.fromARGB(255, 176, 39, 39);
      default:
        return const Color(0xFF3F73A3);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in progress':
        return Icons.access_time;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'under review':
        return Icons.visibility;
      default:
        return Icons.info;
    }
  }
}