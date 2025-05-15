import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_radar_app/services/emergency_contact_service.dart';
import 'package:project_radar_app/widgets/add_contact_dialog.dart';
import 'package:another_flushbar/flushbar.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactService _service = EmergencyContactService();
  List<Map<String, String>> _contacts = [];
  late final Stream<User?> _authStream;
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Reload contacts whenever auth state changes (login/logout)
    _authStream = FirebaseAuth.instance.authStateChanges();
    _authSubscription = _authStream.listen((user) {
      if (user == null) {
        setState(() => _contacts = []);
      } else {
        _loadContacts();
      }
    });
    // Initial fetch if already signed in
    if (FirebaseAuth.instance.currentUser != null) {
      _loadContacts();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _contacts = []); // clear stale data
    final data = await _service.loadContacts();
    setState(() => _contacts = data);
  }

  Future<void> _saveContacts() async {
    await _service.saveContacts(_contacts);
  }

  void _addContact() {
    showDialog(
      context: context,
      builder:
          (_) => AddContactDialog(
            onSave: (name, phone) {
              setState(() => _contacts.add({'name': name, 'phone': phone}));
              _saveContacts();
              _showTopSnackbar('$name contact has been added.', Colors.green);
            },
          ),
    );
  }

  void _editContact(int index) {
    final contact = _contacts[index];
    showDialog(
      context: context,
      builder:
          (_) => AddContactDialog(
            initialName: contact['name'],
            initialPhone: contact['phone'],
            onSave: (name, phone) {
              setState(() => _contacts[index] = {'name': name, 'phone': phone});
              _saveContacts();
              _showTopSnackbar(
                '$name contact has been updated.',
                Colors.orange,
              );
            },
          ),
    );
  }

  void _removeContact(int index) async {
    final contact = _contacts[index];
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text(
                  'Are you sure you want to delete ${contact['name']}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldDelete) {
      setState(() => _contacts.removeAt(index));
      _saveContacts();
      _showTopSnackbar(
        '${contact['name']} contact has been deleted.',
        Colors.red.shade700,
      );
    }
  }

  void _showTopSnackbar(String message, Color color) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: color,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      icon: const Icon(Icons.info, color: Colors.white),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOS Contacts',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Stack(
        children: [
          _contacts.isEmpty
              ? const Center(
                child: Text(
                  'No emergency contacts added yet.',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final c = _contacts[i];
                  return ListTile(
                    onTap: () => _editContact(i),
                    leading: const Icon(Icons.person, color: Color(0xFF1565C0)),
                    title: Text(
                      c['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      c['phone']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeContact(i),
                    ),
                  );
                },
              ),
          Positioned(
            bottom: 20,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton.extended(
                onPressed: _addContact,
                backgroundColor: const Color(0xFF1565C0),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Contact',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
