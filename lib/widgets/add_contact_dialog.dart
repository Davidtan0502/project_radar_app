import 'package:flutter/material.dart';

class AddContactDialog extends StatefulWidget {
  final void Function(String name, String phone) onSave;
  final String? initialName;
  final String? initialPhone;

  const AddContactDialog({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialPhone,
  });

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName ?? '';
    _phone = widget.initialPhone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'Add Emergency Contact' : 'Edit Emergency Contact',
        style: const TextStyle(color: Color(0xFF1565C0)),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              onSaved: (value) => _name = value!.trim(),
              validator: (value) => value!.trim().isEmpty ? 'Enter a name' : null,
            ),
            TextFormField(
              initialValue: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              onSaved: (value) => _phone = value!.trim(),
              validator: (value) {
                if (value!.trim().isEmpty) return 'Enter a phone number';
                final phonePattern = RegExp(r'^\d{10,11}$');
                return phonePattern.hasMatch(value.trim()) ? null : 'Invalid phone number';
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF1565C0))),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onSave(_name, _phone);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}
