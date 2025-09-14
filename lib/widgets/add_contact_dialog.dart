import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // Always strip +63 for editing, keep only the digits after
    if (widget.initialPhone != null &&
        widget.initialPhone!.startsWith('+63')) {
      _phone = widget.initialPhone!.substring(3);
    } else {
      _phone = widget.initialPhone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null
            ? 'Add Emergency Contact'
            : 'Edit Emergency Contact',
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
              validator: (value) =>
                  value!.trim().isEmpty ? 'Enter a name' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixText: '+63 ',
              ),
              keyboardType: TextInputType.phone,
              initialValue: widget.initialPhone != null
                  ? widget.initialPhone!.replaceFirst('+63', '')
                  : '',
              onSaved: (value) => _phone = '+63${value!.trim()}',
              validator: (value) {
                final digits = value!.trim();
                if (digits.isEmpty) return 'Enter a phone number';
                if (!digits.startsWith('9')) {
                  return 'Number must start with 9';
                }
                if (digits.length != 10) {
                  return 'Phone number must be 10 digits';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
                  return 'Invalid characters in phone';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF1565C0)),
          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
