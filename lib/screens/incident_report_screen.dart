import 'package:flutter/material.dart';

class IncidentReportPage extends StatefulWidget {
  const IncidentReportPage({super.key});

  @override
  State<IncidentReportPage> createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cellphoneController = TextEditingController();
  final _concernController = TextEditingController();
  final _otherIncidentTypeController = TextEditingController();

  String? _incidentType;
  final List<String> _incidentTypes = ['Fire', 'Flood', 'Accident', 'Other'];
  final Color _primaryColor = const Color(0xFF3F73A3);
  final Color _accentColor = const Color(0xFF5D9CEC);
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cellphoneController.dispose();
    _concernController.dispose();
    _otherIncidentTypeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _addressController.clear();
    _cellphoneController.clear();
    _concernController.clear();
    _otherIncidentTypeController.clear();
    setState(() => _incidentType = null);
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report Submitted Successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Improved header with animation
            SliverAppBar(
              backgroundColor: _primaryColor,
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1,
                  child: const Text(
                    'Incident Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                background: Container(
                  color: _primaryColor,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: 0.2,
                      child: const Icon(
                        Icons.report_problem,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report an Incident',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please fill out all fields to submit your report',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: 'Please enter your name',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _addressController,
                                label: 'Address',
                                icon: Icons.location_on_outlined,
                                validator: 'Please enter your address',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _cellphoneController,
                                label: 'Contact Number',
                                icon: Icons.phone_outlined,
                                validator: 'Please enter your contact number',
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildIncidentTypeDropdown(),
                              const SizedBox(height: 16),
                              if (_incidentType == 'Other') ...[
                                _buildTextField(
                                  controller: _otherIncidentTypeController,
                                  label: 'Specify Incident Type',
                                  icon: Icons.edit_outlined,
                                  validator: 'Please specify the incident type',
                                ),
                                const SizedBox(height: 16),
                              ],
                              _buildConcernField(),
                              const SizedBox(height: 32),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) => value == null || value.isEmpty ? validator : null,
    );
  }

  Widget _buildIncidentTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _incidentType,
      decoration: InputDecoration(
        labelText: 'Incident Type',
        prefixIcon: Icon(Icons.warning_amber_outlined, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      ),
      items: _incidentTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(
            type,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _incidentType = value),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select an incident type' : null,
      borderRadius: BorderRadius.circular(10),
      icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
      dropdownColor: Colors.white,
      style: TextStyle(color: Colors.grey.shade800),
    );
  }

  Widget _buildConcernField() {
    return TextFormField(
      controller: _concernController,
      decoration: InputDecoration(
        labelText: 'Detailed Description',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.description_outlined, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      maxLines: 5,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please describe the incident in detail' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child: const Text(
          'SUBMIT REPORT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}