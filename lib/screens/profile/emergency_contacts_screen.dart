import 'package:flutter/material.dart';
import 'package:project_radar_app/services/emergency_contact_service.dart';
import 'package:project_radar_app/widgets/add_contact_dialog.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactService _service = EmergencyContactService();
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
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
            },
          ),
    );
  }

  void _removeContact(int index) {
    setState(() => _contacts.removeAt(index));
    _saveContacts();
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
            bottom: 20, // floating button a little up from the bottom
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
