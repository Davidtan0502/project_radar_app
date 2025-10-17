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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.initialName ?? '';
    _phone = widget.initialPhone ?? '';
    
    _nameController.text = _name;
    
    // Format phone for display
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
    const backgroundColor = Color(0xFFF8F9FA);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                Text(
                  widget.initialName == null
                      ? 'Add Emergency Contact'
                      : 'Edit Emergency Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Form
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name Field
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
                  
                  const SizedBox(height: 16),
                  
                  // Phone Field
                  _buildPhoneField(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
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
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: const Color(0xFF28588B),
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 16,
              ),
            ),
            validator: validator,
            onSaved: onSaved,
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
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: const Color(0xFF28588B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+63',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: '9123456789',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    final digits = value!.trim();
                    if (digits.isEmpty) return 'Please enter a phone number';
                    if (!digits.startsWith('9')) {
                      return 'Number must start with 9';
                    }
                    if (digits.length != 10) {
                      return 'Phone number must be 10 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
                      return 'Invalid characters in phone number';
                    }
                    return null;
                  },
                  onSaved: (value) => _phone = '+63${value!.trim()}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Format: 9XXXXXXXXX (10 digits starting with 9)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
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