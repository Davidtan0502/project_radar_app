import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.initialName ?? '';
    _phone = widget.initialPhone ?? '';

    _nameController.text = _name;

    if (widget.initialPhone != null && widget.initialPhone!.startsWith('+63')) {
      _phoneController.text = widget.initialPhone!.substring(3);
    } else if (widget.initialPhone != null && widget.initialPhone!.startsWith('0')) {
      _phoneController.text = widget.initialPhone!.substring(1);
    } else {
      _phoneController.text = widget.initialPhone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF28588B);

    // Use insetPadding so the Dialog system already limits width based on device
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Cap the dialog width to a comfortable maximum and to available space.
          final maxWidth = math.min(600.0, constraints.maxWidth);
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row — Icon + flexible title so it doesn't push width
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.initialName == null ? Icons.person_add : Icons.edit,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.initialName == null
                                ? 'Add Emergency Contact'
                                : 'Edit Emergency Contact',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name
                          _buildModernTextField(
                            controller: _nameController,
                            label: 'Contact Name',
                            icon: Icons.person_outline,
                            hintText: 'Enter contact name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                            onSaved: (value) => _name = value!.trim(),
                          ),

                          const SizedBox(height: 14),

                          // Phone
                          _buildPhoneField(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Buttons: restored to Expanded so they match the original equal widths
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveContact,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Save Contact',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    required String? Function(String?)? validator,
    required void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Fixed-width prefix to avoid unpredictable margins contributing to overflow
              SizedBox(
                width: 48,
                child: Center(
                  child: Icon(
                    icon,
                    color: const Color(0xFF28588B),
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                  validator: validator,
                  onSaved: onSaved,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Compact prefix area
              SizedBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_outlined, color: const Color(0xFF28588B), size: 20),
                    const SizedBox(width: 6),
                    Text('+63', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '9123456789',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                  validator: (value) {
                    final digits = value!.trim();
                    if (digits.isEmpty) return 'Please enter a phone number';
                    if (!digits.startsWith('9')) return 'Number must start with 9';
                    if (digits.length != 10) return 'Phone number must be 10 digits';
                    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return 'Invalid characters in phone number';
                    return null;
                  },
                  onSaved: (value) => _phone = '+63${value!.trim()}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Format: 9XXXXXXXXX (10 digits starting with 9)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSave(_name, _phone);
      Navigator.pop(context);
    }
  }
}
