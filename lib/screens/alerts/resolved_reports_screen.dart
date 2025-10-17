import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResolvedReportsScreen extends StatelessWidget {
  const ResolvedReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Resolved (Last 24 Hours)",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF3F73A3),
        foregroundColor: Colors.white,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('incidents')
            .stream(primaryKey: ['id'])
            .eq('status', 'resolved')
            .order('timestamp', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.error_outline,
              message: "Error loading resolved reports",
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF3F73A3)),
              ),
            );
          }

          final incidents = snapshot.data ?? [];
          
          // Filter for last 24 hours in the builder
          final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
          final recentIncidents = incidents.where((incident) {
            final timestamp = _parseTimestamp(incident['timestamp']);
            return timestamp != null && timestamp.isAfter(twentyFourHoursAgo);
          }).toList();

          if (recentIncidents.isEmpty) {
            return _buildMessage(
              icon: Icons.assignment_turned_in_outlined,
              message: "No resolved cases in the last 24 hours",
              subMessage: "Resolved reports will appear here",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recentIncidents.length,
            itemBuilder: (context, index) {
              final data = recentIncidents[index];

              final description = data['description'] ?? 'No description';
              final location = data['address'] ?? 'Unknown location';
              final lat = data['latitude']?.toString() ?? 'N/A';
              final lng = data['longitude']?.toString() ?? 'N/A';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "📍 $location",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Coordinates: ($lat, $lng)",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    String? subMessage,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}