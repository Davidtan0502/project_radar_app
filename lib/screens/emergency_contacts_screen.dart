import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('sos_contacts') ?? [];
    setState(() {
      _contacts = list
          .map((s) => Map<String, String>.from(jsonDecode(s)))
          .toList();
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _contacts.map((c) => jsonEncode(c)).toList();
    await prefs.setStringList('sos_contacts', list);
  }

  void _addContact() {
    String name = '', phone = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (v) => name = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => phone = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.trim().isNotEmpty && phone.trim().isNotEmpty) {
                setState(() {
                  _contacts.add({'name': name.trim(), 'phone': phone.trim()});
                });
                _saveContacts();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeContact(int idx) {
    setState(() {
      _contacts.removeAt(idx);
    });
    _saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Contacts'),
        backgroundColor: const Color(0xFF3F73A3),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final c = _contacts[i];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(c['name']!),
            subtitle: Text(c['phone']!),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeContact(i),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: const Color(0xFF3F73A3),
        child: const Icon(Icons.add),
      ),
    );
  }
}
