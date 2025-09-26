import 'package:flutter/material.dart';
import 'package:project_radar_app/notification/notification_service.dart';

class IncidentDetailsScreen extends StatelessWidget {
  final String incidentId;
  final String type;
  final Map<String, dynamic>? additionalData;
  
  const IncidentDetailsScreen({
    super.key,
    required this.incidentId,
    required this.type,
    this.additionalData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _handleBackNavigation(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _markAsReadAndNavigate(context, '/home');
            },
            tooltip: 'Mark as Read & Go Home',
          ),
        ],
      ),
      body: _buildContent(context),
      bottomNavigationBar: _buildBottomButtons(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIncidentCard(context),
          const SizedBox(height: 20),
          _buildDetailsSection(context),
          const SizedBox(height: 20),
          _buildActionsSection(context),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Incident ID:', incidentId),
            _buildDetailRow('Type:', type),
            _buildDetailRow('Status:', 'Active'),
            _buildDetailRow('Priority:', _getPriorityLevel()),
            _buildDetailRow('Date Reported:', _getFormattedDate()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailCard('Description', 
          additionalData?['description'] ?? 'No description provided.'),
        _buildDetailCard('Location', 
          additionalData?['location'] ?? 'Location not specified.'),
        _buildDetailCard('Additional Info', 
          additionalData?['additionalInfo'] ?? 'No additional information.'),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3,
          children: [
            _buildActionButton(Icons.photo_library, 'View Photos', () {
              // Handle view photos
            }),
            _buildActionButton(Icons.map, 'View on Map', () {
              // Handle view on map
            }),
            _buildActionButton(Icons.share, 'Share Report', () {
              // Handle share
            }),
            _buildActionButton(Icons.history, 'View History', () {
              // Handle view history
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleBackNavigation(context),
                child: const Text('Back to Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _markAsReadAndNavigate(context, '/reportTracker'),
                child: const Text('View All Reports'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[700],
        elevation: 0,
      ),
    );
  }

  String _getPriorityLevel() {
    return additionalData?['priority'] ?? 'Medium';
  }

  String _getFormattedDate() {
    return additionalData?['date'] ?? DateTime.now().toString().split(' ')[0];
  }

  void _handleBackNavigation(BuildContext context) {
    NotificationService().markAsRead(incidentId);
    Navigator.of(context).pop();
  }

  void _markAsReadAndNavigate(BuildContext context, String route) {
    NotificationService().markAsRead(incidentId);
    
    if (route == '/home') {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
      );
    }
  }
}