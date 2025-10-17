import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  Future<void> _approveRegistration(
      BuildContext context, String docId, Map<String, dynamic> userData) async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Create user account in Supabase Auth
      final password = _generateRandomPassword();
      final authResponse = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: userData['email'],
          password: password,
          emailConfirm: true, // Auto-confirm email for approved users
        ),
      );

      final userId = authResponse.user!.id;

      // 2. Create user profile in Supabase database
      await supabase
          .from('app_users')
          .insert({
            'id': userId,
            'first_name': userData['first_name'],
            'last_name': userData['last_name'],
            'middle_name': userData['middle_name'],
            'email': userData['email'],
            'phone': userData['phone'],
            'role': 'user',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'user_category': userData['user_category'],
            // Copy address data based on user category
            if (userData['user_category'] == "RESIDENT") 
              'resident_address': userData['resident_address'],
            if (userData['user_category'] == "EMPLOYEE") 
              'work_address': userData['work_address'],
            if (userData['user_category'] == "EMPLOYEE" || userData['user_category'] == "STUDENT")
              'home_address': userData['home_address'],
            if (userData['user_category'] == "STUDENT") 
              'school_address': userData['school_address'],
          });

      // 3. Remove from pending registrations
      await supabase
          .from('pending_registrations')
          .delete()
          .eq('id', docId);

      // 4. Send welcome email
      await _sendWelcomeEmail(userData['email'], password);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully!')),
      );
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth Error: ${e.message}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectRegistration(
      BuildContext context, String docId, String email) async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Remove from pending registrations
      await supabase
          .from('pending_registrations')
          .delete()
          .eq('id', docId);

      // 2. Send rejection email
      await _sendRejectionEmail(email);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration rejected')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _generateRandomPassword() {
    const length = 12;
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _sendWelcomeEmail(String email, String password) async {
    // Implement your email sending logic here
    // You can use Supabase Edge Functions or your own email service
    debugPrint('Sending welcome email to $email with password: $password');
  }

  Future<void> _sendRejectionEmail(String email) async {
    // Implement your rejection email logic here
    debugPrint('Sending rejection email to $email');
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Registrations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('pending_registrations')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingRegistrations = snapshot.data ?? [];

          if (pendingRegistrations.isEmpty) {
            return const Center(child: Text('No pending registrations'));
          }

          return ListView.builder(
            itemCount: pendingRegistrations.length,
            itemBuilder: (context, index) {
              final data = pendingRegistrations[index];
              final docId = data['id'] as String;

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['first_name']} ${data['last_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${data['email']}'),
                      Text('Phone: ${data['phone']}'),
                      Text('Category: ${data['user_category']}'),
                      const SizedBox(height: 8),
                      Text(
                        'Submitted: ${_formatDate(data['created_at'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _rejectRegistration(context, docId, data['email']),
                            child: const Text('Reject',
                                style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _approveRegistration(context, docId, data),
                            child: const Text('Approve'),
                          ),
                        ],
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

  String _formatDate(dynamic date) {
    if (date is String) {
      return DateTime.parse(date).toString();
    } else if (date is DateTime) {
      return date.toString();
    }
    return 'Unknown date';
  }
}