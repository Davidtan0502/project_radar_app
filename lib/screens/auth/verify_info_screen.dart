import 'package:flutter/material.dart';

/// A confirmation screen that displays the user's input
class VerifyInfoScreen extends StatefulWidget {
  final String lastName;
  final String firstName;
  final String middleName;
  final String email;
  final String phone;
  final String password;

  // New optional fields: RegisterScreen does not need to pass these,
  // but if it does, we'll display them.
  final String? userCategory;
  final Map<String, dynamic>? residentAddress;
  final Map<String, dynamic>? workAddress;
  final Map<String, dynamic>? homeAddress;
  final Map<String, dynamic>? schoolAddress;

  // Callbacks (kept for compatibility with RegisterScreen)
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const VerifyInfoScreen({
    super.key,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.email,
    required this.phone,
    required this.password,
    // optional address/category fields
    this.userCategory,
    this.residentAddress,
    this.workAddress,
    this.homeAddress,
    this.schoolAddress,
    // callbacks (RegisterScreen passes () {} so this matches)
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  State<VerifyInfoScreen> createState() => _VerifyInfoScreenState();
}

class _VerifyInfoScreenState extends State<VerifyInfoScreen> {
  bool _isLoading = false;

  /// Pops with `false` to signal "edit".
  void _handleEdit() {
    // call provided callback (kept for compatibility) but preserve existing behavior
    widget.onEdit();
    Navigator.pop(context, false);
  }

  /// Pops with `true` to signal "confirm".
  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    // call provided callback (kept for compatibility)
    widget.onConfirm();
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pop(context, true);
  }

  /// Capitalize each word in a multi-word string
  String _capitalizeEachWord(String value) {
    if (value.trim().isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) =>
            word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : ''))
        .join(' ');
  }

  /// Map short category tokens to friendly labels
  /// Accepts: "RESIDENT", "EMPLOYEE", "STUDENT" (case-insensitive) and falls back
  /// to the existing capitalization logic for other values.
  String _friendlyCategory(String? token) {
    if (token == null) return '';
    final t = token.trim().toUpperCase();
    switch (t) {
      case 'RESIDENT':
        return 'Resident';
      case 'EMPLOYEE':
        return 'Employee';
      case 'STUDENT':
        return 'Student';
      default:
        // fallback to previous behavior (title-case whatever was passed)
        return _capitalizeEachWord(token.trim());
    }
  }

  /// Safely read a string field from an address map, return empty string if missing
  String _addr(Map<String, dynamic>? m, String key) {
    if (m == null) return '';
    final val = m[key];
    if (val == null) return '';
    return val.toString();
  }

  // ------------ helper label-detection functions (extended variants) ------------

  bool _containsLabel(String value, List<String> labels) {
    if (value.trim().isEmpty) return false;
    // join escaped labels and match as whole words (case-insensitive)
    final escaped = labels.map(RegExp.escape).join('|');
    final pattern = RegExp(r'\b(' + escaped + r')\b', caseSensitive: false);
    return pattern.hasMatch(value);
  }

  bool _hasStreetLabel(String value) {
    // Common street-like suffixes/abbreviations that indicate the user already labeled the street:
    // street, st, st., str, str., road, rd, rd., avenue, ave, ave., av, av., boulevard, blvd, blvd.,
    // lane, ln, ln., drive, dr, dr., place, pl, pl., way
    return _containsLabel(value, [
      'street',
      'st',
      'st\\.',
      'str',
      'str\\.',
      'road',
      'rd',
      'rd\\.',
      'avenue',
      'ave',
      'ave\\.',
      'av',
      'av\\.',
      'boulevard',
      'blvd',
      'blvd\\.',
      'lane',
      'ln',
      'ln\\.',
      'drive',
      'dr',
      'dr\\.',
      'place',
      'pl',
      'pl\\.',
      'way'
    ]);
  }

  bool _hasBarangayLabel(String value) {
    // Recognize barangay variants: barangay, brgy, brgy., brg, brg., bgy, bgy., brgy-
    return _containsLabel(value, [
      'barangay',
      'barangay\\.',
      'brgy',
      'brgy\\.',
      'brg',
      'brg\\.',
      'bgy',
      'bgy\\.',
      'brgy\\-'
    ]);
  }

  bool _hasCityLabel(String value) {
    // Recognize city variants: city, city.  (we purposely keep this tight to avoid false matches)
    return _containsLabel(value, ['city', 'city\\.']);
  }

  /// Build a compact address block (label + inline text)
  /// NOTE: this was changed to produce a single inline string (comma-separated)
  /// so it uses less vertical space and avoids overflow.
  Widget _buildAddressBlock(String title, Map<String, dynamic> map) {
    // collect non-empty parts in preferred order
    final parts = <String>[];
    final schoolName = _addr(map, 'schoolName');
    if (schoolName.isNotEmpty) parts.add(_capitalizeEachWord(schoolName));

    final house = _addr(map, 'house');
    final street = _addr(map, 'street');
    if (house.isNotEmpty && street.isNotEmpty) {
      // For street: append "Street" only when user did NOT include a street label already
      final streetPart = _hasStreetLabel(street)
          ? _capitalizeEachWord(street)
          : '${_capitalizeEachWord(street)} Street';
      parts.add('${_capitalizeEachWord(house)}, $streetPart');
    } else if (house.isNotEmpty) {
      parts.add(_capitalizeEachWord(house));
    } else if (street.isNotEmpty) {
      final streetPart = _hasStreetLabel(street)
          ? _capitalizeEachWord(street)
          : '${_capitalizeEachWord(street)} Street';
      parts.add(streetPart);
    }

    final barangay = _addr(map, 'barangay');
    if (barangay.isNotEmpty) {
      // Prefix "Barangay " only when user did NOT already include it (or brgy variants)
      final barangayPart = _hasBarangayLabel(barangay)
          ? _capitalizeEachWord(barangay)
          : 'Barangay ${_capitalizeEachWord(barangay)}';
      parts.add(barangayPart);
    }

    final town = _addr(map, 'town');
    if (town.isNotEmpty) parts.add(_capitalizeEachWord(town));

    final zip = _addr(map, 'zip');
    if (zip.isNotEmpty) parts.add('ZIP: $zip');

    final city = _addr(map, 'city');
    if (city.isNotEmpty) {
      // Only for Home Address we append "City" (unless user already wrote 'city')
      if (title == 'Home Address') {
        final cityPart = _hasCityLabel(city)
            ? _capitalizeEachWord(city)
            : '${_capitalizeEachWord(city)} City';
        parts.add(cityPart);
      } else {
        // For non-home addresses, just show city as-is/title-cased
        parts.add(_capitalizeEachWord(city));
      }
    }

    final country = _addr(map, 'country');
    if (country.isNotEmpty) parts.add(_capitalizeEachWord(country));

    // Join into single inline string (comma-separated). If empty, show '-'.
    final inline = parts.isNotEmpty ? parts.join(', ') : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            // allow soft wrapping; since it's a single Text it will wrap horizontally
            child: Text(
              inline,
              style: const TextStyle(color: Color.fromARGB(221, 11, 11, 11)),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Details'),
        backgroundColor: const Color(0xFF336699),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            // <-- Allow the details to scroll if they don't fit vertically -->
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Please confirm your details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile('Last Name', _capitalizeEachWord(widget.lastName)),
                  _buildInfoTile('First Name', _capitalizeEachWord(widget.firstName)),
                  // only show middle name label if non-empty (keeps layout similar)
                  if (widget.middleName.trim().isNotEmpty)
                    _buildInfoTile('Middle Name', _capitalizeEachWord(widget.middleName)),
                  _buildInfoTile('Email', widget.email),
                  _buildInfoTile('Phone', '+63${widget.phone}'),
                  _buildInfoTile('Password', '*' * widget.password.length),

                  // New: show selected category if provided (mapped from short token to friendly label)
                  if (widget.userCategory != null && widget.userCategory!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoTile('Category', _friendlyCategory(widget.userCategory)),
                  ],

                  const SizedBox(height: 12),

                  // Address sections — show only if maps are provided & non-empty
                  if (widget.residentAddress != null && widget.residentAddress!.isNotEmpty) ...[
                    _buildAddressBlock('Resident Address', widget.residentAddress!),
                  ],
                  if (widget.workAddress != null && widget.workAddress!.isNotEmpty) ...[
                    _buildAddressBlock('Work Address', widget.workAddress!),
                  ],
                  if (widget.homeAddress != null && widget.homeAddress!.isNotEmpty) ...[
                    _buildAddressBlock('Home Address', widget.homeAddress!),
                  ],
                  if (widget.schoolAddress != null && widget.schoolAddress!.isNotEmpty) ...[
                    _buildAddressBlock('School Address', widget.schoolAddress!),
                  ],

                  const SizedBox(height: 16),
                  // keep buttons below the scrollable content; they will appear after content
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleEdit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF336699)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF336699),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF336699),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(color: Color.fromARGB(221, 11, 11, 11)),
            ),
          ),
        ],
      ),
    );
  }
}
