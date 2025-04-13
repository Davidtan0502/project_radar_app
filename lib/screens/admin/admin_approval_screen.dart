import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  Future<void> _approveRegistration(
      BuildContext context, String docId, Map<String, dynamic> userData) async {
    try {
      // 1. Create Firebase Auth account
      final auth = FirebaseAuth.instance;
      final password = _generateRandomPassword();
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: password,
      );

      // 2. Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        ...userData,
        'uid': userCredential.user?.uid,
        'role': 'user',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Remove from pending registrations
      await FirebaseFirestore.instance
          .collection('pending_registrations')
          .doc(docId)
          .delete();

      // 4. Send welcome email
      await _sendWelcomeEmail(userData['email'], password);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully!')),
      );
    } on FirebaseAuthException catch (e) {
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
      // 1. Remove from pending registrations
      await FirebaseFirestore.instance
          .collection('pending_registrations')
          .doc(docId)
          .delete();

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
    debugPrint('Sending welcome email to $email with password: $password');
  }

  Future<void> _sendRejectionEmail(String email) async {
    // Implement your rejection email logic here
    debugPrint('Sending rejection email to $email');
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pending_registrations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending registrations'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['firstName']} ${data['lastName']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${data['email']}'),
                      Text('Phone: ${data['phone']}'),
                      const SizedBox(height: 8),
                      Text(
                        'Submitted: ${(data['createdAt'] as Timestamp).toDate()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _rejectRegistration(context, doc.id, data['email']),
                            child: const Text('Reject',
                                style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _approveRegistration(context, doc.id, data),
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
}