import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class UnitFormatter extends TextInputFormatter {
  final String unit;

  UnitFormatter(this.unit);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final lower = text.toLowerCase();

    if (lower.endsWith(unit)) {
      final core = text.substring(0, text.length - unit.length).trimRight();
      final formatted = '$core $unit';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}

class EditAccountinfo extends StatefulWidget {
  const EditAccountinfo({super.key});

  @override
  State<EditAccountinfo> createState() => _EditAccountinfoState();
}

class _EditAccountinfoState extends State<EditAccountinfo> {
  // Images: mobile uses File, web uses Uint8List (bytes). We keep both to support both platforms.
  File? _profileImage;
  File? _idImage;
  String? _profileImageUrl;
  String? _idImageUrl;
  Uint8List? _profileImageBytes;
  Uint8List? _idImageBytes;

  // flags for deletion
  bool _removeProfileImage = false;
  bool _removeIdImage = false;

  // upload progress indicators
  double? _profileUploadProgress;
  double? _idUploadProgress;

  final _formKey = GlobalKey<FormState>();
  bool _isFormDirty = false;
  bool _isSaving = false;
  final Map<TextEditingController, String?> _fieldErrors = {};
  AutovalidateMode _autoValidateMode = AutovalidateMode.onUserInteraction;

  // Basic Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  final _addressController = TextEditingController();

  // Health / other
  final _bloodTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Address controllers
  final _resHouseController = TextEditingController();
  final _resStreetController = TextEditingController();
  final _resBarangayController = TextEditingController();
  final _resTownController = TextEditingController();
  final _resZipController = TextEditingController();
  final _resCityController = TextEditingController();
  final _resCountryController = TextEditingController(text: "Philippines");

  // NEW: optional middle name checkbox state
  bool _hasMiddleName = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeFormListeners();
    _addAddressCapitalizationListeners();
    _loadUserData();
    _autoValidateMode = AutovalidateMode.onUserInteraction;

    _bloodTypeController.addListener(() {
      final input = _bloodTypeController.text.toUpperCase();
      final validTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

      if (input.isEmpty || validTypes.any((type) => type.startsWith(input))) {
        if (_bloodTypeController.text != input) {
          _bloodTypeController.value = _bloodTypeController.value.copyWith(
            text: input,
            selection: TextSelection.fromPosition(
              TextPosition(offset: input.length),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('id', user.id)
          .single();
      
      final data = response;
      String composedAddress = '';
      if ((data['address'] ?? '').toString().trim().isNotEmpty) {
        composedAddress = data['address'].toString();
      }

      Map<String, dynamic>? safeMap(dynamic v) {
        if (v is Map) return Map<String, dynamic>.from(v);
        return null;
      }

      final residentMap = safeMap(data['resident_address']);

      setState(() {
        _firstNameController.text = _capitalizeWords(data['first_name'] ?? '');
        _middleNameController.text = _capitalizeWords(data['middle_name'] ?? '');
        _hasMiddleName = (_middleNameController.text.trim().isNotEmpty);
        _lastNameController.text = _capitalizeWords(data['last_name'] ?? '');
        _emailController.text = data['email'] ?? '';
        _phoneController.text = _formatPhone(data['phone'] ?? '');
        _dobController.text = data['dob'] ?? '';
        _bloodTypeController.text = data['blood_type'] ?? '';
        _heightController.text = data['height'] ?? '';
        _weightController.text = data['weight'] ?? '';

        _profileImageUrl = (data['photo_url'] ?? '').toString().trim();
        _idImageUrl = (data['id_url'] ?? '').toString().trim();

        _addressController.text = composedAddress;

        // Resident
        if (residentMap != null && residentMap.isNotEmpty) {
          _resHouseController.text = residentMap['house']?.toString() ?? '';
          _resStreetController.text = residentMap['street']?.toString() ?? '';
          _resBarangayController.text = residentMap['barangay']?.toString() ?? '';
          _resTownController.text = residentMap['town']?.toString() ?? '';
          _resZipController.text = residentMap['zip']?.toString() ?? '';
          _resCityController.text = residentMap['city']?.toString() ?? (_resCityController.text);
          _resCountryController.text = residentMap['country']?.toString() ?? 'Philippines';
        }

        _isFormDirty = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _initializeFormListeners() {
    for (final ctrl in [
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _dobController,
      _addressController,
      _bloodTypeController,
      _heightController,
      _weightController,
      // resident
      _resHouseController,
      _resStreetController,
      _resBarangayController,
      _resTownController,
      _resZipController,
      _resCityController,
      _resCountryController,
    ]) {
      ctrl.addListener(_markFormDirty);
    }
  }

  void _addAddressCapitalizationListeners() {
    final addressControllers = [
      _resHouseController,
      _resStreetController,
      _resBarangayController,
      _resTownController,
      _resCityController,
    ];

    for (final ctrl in addressControllers) {
      ctrl.addListener(() {
        final text = ctrl.text;
        final capitalized = _capitalizeWords(text);
        if (capitalized != text) {
          final sel = ctrl.selection;
          final int baseOffset = sel.baseOffset;
          final int offset = math.min(baseOffset, capitalized.length);
          ctrl.value = TextEditingValue(
            text: capitalized,
            selection: TextSelection.collapsed(offset: offset),
          );
        }
      });
    }
  }

  void _markFormDirty() {
    if (!_isFormDirty) setState(() => _isFormDirty = true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();

    _resHouseController.dispose();
    _resStreetController.dispose();
    _resBarangayController.dispose();
    _resTownController.dispose();
    _resZipController.dispose();
    _resCityController.dispose();
    _resCountryController.dispose();

    super.dispose();
  }

  bool _isFileSizeValid(File file, {int maxSizeMB = 5}) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
  }

  Future<String?> _uploadImageToStorage(dynamic imageFileOrBytes, String folder) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final fileName = '${user.id}.jpg';
    final fullPath = '$folder/${user.id}/$fileName';

    // Step 1: Remove any existing file (ignore if missing)
    try {
      await _supabase.storage.from('profiles').remove([fullPath]);
    } catch (e) {
      debugPrint('No existing file to remove (that\'s fine): $e');
    }

    // Step 2: Upload file
    final fileOptions = FileOptions(cacheControl: '3600', upsert: true);
    final bucket = _supabase.storage.from('profiles');

    if (kIsWeb && imageFileOrBytes is Uint8List) {
      // Web upload
      await bucket.uploadBinary(fullPath, imageFileOrBytes, fileOptions: fileOptions);
    } else if (imageFileOrBytes is File) {
      // Mobile upload
      await bucket.upload(fullPath, imageFileOrBytes, fileOptions: fileOptions);
    } else {
      throw Exception('Unsupported image format');
    }

    // Step 3: Get the public URL
    final publicUrl = bucket.getPublicUrl(fullPath);
    debugPrint('✅ Uploaded successfully: $publicUrl');
    return publicUrl;
  } catch (e) {
    debugPrint('uploadToProfilesBucket failed: $e');
    return null;
  }
}

  /// Returns true if remove succeeded (or file didn't exist), false on error.
  Future<bool> _deleteFileFromStorage(String folder, String userId) async {
    final path = '$folder/$userId.jpg';
    try {
      await _supabase.storage.from('profiles').remove([path]);
      debugPrint('Storage.remove succeeded: $path');
      return true;
    } catch (e, st) {
      debugPrint('Storage.remove failed for $path: $e\n$st');
      return false;
    }
  }

  /// Clear the URL/path fields in your app_users row.
  Future<bool> _clearUserImageField(String userId, {required bool isProfile}) async {
    try {
      final columnUrl = isProfile ? 'photo_url' : 'id_url';
      final columnPath = isProfile ? 'photo_path' : 'id_path';
      final updates = <String, dynamic>{columnUrl: null, columnPath: null, 'updated_at': DateTime.now().toIso8601String()};
      // Use select().single() to get response shape consistent with your save flow
      final resp = await _supabase.from('app_users').update(updates).eq('id', userId).select().single();
      debugPrint('DB cleared ${isProfile ? 'profile' : 'id'} fields for $userId -> $resp');
      return true;
    } catch (e, st) {
      debugPrint('DB update exception clearing image fields: $e\n$st');
      return false;
    }
  }

  /// Combined flow: delete from storage first, then clear DB, then update UI state.
  Future<void> deleteProfileOrId({required bool isProfile}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final folder = isProfile ? 'profile_images' : 'id_uploads';
    final userId = user.id;

    final removed = await _deleteFileFromStorage(folder, userId);
    if (!removed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete image from storage. Check permissions or network.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final cleared = await _clearUserImageField(userId, isProfile: isProfile);
    if (!cleared) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File removed but failed to update profile record.'), backgroundColor: Colors.orange),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    setState(() {
      if (isProfile) {
        _profileImage = null;
        _profileImageBytes = null;
        _profileImageUrl = null;
        _removeProfileImage = false;
        _profileUploadProgress = null;
      } else {
        _idImage = null;
        _idImageBytes = null;
        _idImageUrl = null;
        _removeIdImage = false;
        _idUploadProgress = null;
      }
      _isFormDirty = false;
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully.')),
      );
    }
  }

 Future<void> _pickImage(ImageSource source, bool isProfile) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source);
  if (picked == null) return;

  Uint8List? bytes;
  File? file;
  try {
    if (kIsWeb) {
      bytes = await picked.readAsBytes();
      debugPrint('DEBUG: picked image (web) bytes=${bytes.lengthInBytes}');
    } else {
      file = File(picked.path);
      debugPrint('DEBUG: picked image (mobile) path=${picked.path}');
    }
  } catch (e) {
    debugPrint('Error reading picked image: $e');
    return;
  }

  // 🔹 Check file size
  if (bytes != null) {
    final sizeInMB = bytes.lengthInBytes / (1024 * 1024);
    if (sizeInMB > 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image size too large (max 5MB)'), backgroundColor: Colors.red),
      );
      return;
    }
  } else if (file != null && !_isFileSizeValid(file)) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image size too large (max 5MB)'), backgroundColor: Colors.red),
    );
    return;
  }

  final action = await _showImagePreviewBeforeSave(bytes ?? file!, isProfile);
  if (!mounted) return;

  if (action == 'use') {
    setState(() {
      if (isProfile) {
        _profileImage = file;
        _profileImageBytes = bytes;
        _removeProfileImage = false;
        _profileImageUrl = null;
      } else {
        _idImage = file;
        _idImageBytes = bytes;
        _removeIdImage = false;
        _idImageUrl = null;
      }
      _markFormDirty();
    });

    // 🔹 Upload immediately after user confirms
    final imageToUpload = file ?? bytes;
    final folder = isProfile ? 'profile_images' : 'id_uploads';

    final newUrl = await _uploadImageToStorage(imageToUpload, folder);

    if (newUrl != null && mounted) {
      setState(() {
        if (isProfile) {
          _profileImageUrl = newUrl;
        } else {
          _idImageUrl = newUrl;
        }
      });
      debugPrint('✅ Image updated: $newUrl');
    } else {
      debugPrint('⚠️ Upload failed or returned null URL');
    }
  } else if (action == 'retake') {
    await _pickImage(ImageSource.camera, isProfile);
  } else if (action == 'gallery') {
    await _pickImage(ImageSource.gallery, isProfile);
  }
}

  Future<String?> _showImagePreviewBeforeSave(dynamic image, bool isProfile) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Widget content;
        if (image is Uint8List) {
          content = Image.memory(image, fit: BoxFit.contain);
        } else if (image is File) {
          content = Image.file(image, fit: BoxFit.contain);
        } else {
          content = const SizedBox.shrink();
        }
        return AlertDialog(
          title: Text(isProfile ? 'Preview Profile Photo' : 'Preview ID Photo'),
          content: SizedBox(width: double.maxFinite, child: content),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop('cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('gallery'), child: const Text('Choose from Gallery')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('retake'), child: const Text('Retake')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop('use'), child: const Text('Use Photo')),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final ninetyfiveYearsAgo = DateTime(now.year - 95, now.month, now.day);
    final eightYearsAgo = DateTime(now.year - 8, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: eightYearsAgo,
      firstDate: ninetyfiveYearsAgo,
      lastDate: eightYearsAgo,
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.month}/${picked.day}/${picked.year}";
        _markFormDirty();
      });
    }
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+63')) {
      return '0${phone.substring(3)}';
    }
    return phone;
  }

  Map<String, dynamic> _collectAddressMap() {
    return {
      'house': _resHouseController.text.trim(),
      'street': _resStreetController.text.trim(),
      'barangay': _resBarangayController.text.trim(),
      'town': _resTownController.text.trim(),
      'zip': _resZipController.text.trim(),
      'city': _resCityController.text.trim(),
      'country': _resCountryController.text.trim(),
    };
  }

  String _composeAddressStringFromMap(Map<String, dynamic> m) {
    final parts = <String>[];
    void addIf(String? s) {
      if (s != null && s.toString().trim().isNotEmpty) parts.add(s.toString().trim());
    }

    addIf(m['house']);
    addIf(m['street']);
    if (m['barangay'] != null && m['barangay'].toString().trim().isNotEmpty) {
      parts.add('Barangay ${m['barangay'].toString().trim()}');
    }
    addIf(m['town']);
    addIf(m['city']);
    if (m['zip'] != null && m['zip'].toString().trim().isNotEmpty) parts.add('${m['zip'].toString().trim()}');
    return parts.join(', ');
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!);
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) return NetworkImage(_profileImageUrl!);
    return null;
  }

 Future<void> _deleteFileByPath(String? path) async {
  if (path == null || path.isEmpty) {
    debugPrint('Skip delete — no path provided');
    return;
  }

  try {
    // Normalize: handle full URLs or wrong prefixes
    String normalizedPath = path.trim();

    // Case 1: full URL (convert to internal path)
    if (normalizedPath.startsWith('http')) {
      final uri = Uri.parse(normalizedPath);
      final segments = uri.pathSegments;
      final idx = segments.indexOf('profiles');
      if (idx != -1 && idx + 1 < segments.length) {
        normalizedPath = segments.sublist(idx + 1).join('/');
      }
    }

    // Case 2: accidental leading slashes or "public/" prefix
    if (normalizedPath.startsWith('public/')) {
      normalizedPath = normalizedPath.replaceFirst('public/', '');
    }
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    debugPrint('Attempting to delete storage object: $normalizedPath');

    final response = await _supabase.storage.from('profiles').remove([normalizedPath]);
    debugPrint('Storage.remove response: $response');

    // Double-check: list objects to confirm delete
    final listAfter = await _supabase.storage.from('profiles').list(
      path: normalizedPath.split('/').first,
    );
    debugPrint('Files still present in folder after delete: ${listAfter.map((e) => e.name).toList()}');
  } catch (e, st) {
    debugPrint('deleteFileByPath failed: $e\n$st');
  }
}

  Future<void> _saveProfile() async {
  // DEBUG INSTRUMENTATION START
debugPrint('=== _saveProfile() DEBUG RUN ===');
debugPrint('_isSaving before start = $_isSaving');
debugPrint('_autoValidateMode before start = $_autoValidateMode');
debugPrint('_hasMiddleName = $_hasMiddleName');

// snapshot of controllers
debugPrint('controllers snapshot:');
final controllers = {
  'First Name': _firstNameController.text,
  'Middle Name': _middleNameController.text,
  'Last Name': _lastNameController.text,
  'Phone Number': _phoneController.text,
  'Res House': _resHouseController.text,
  'Res Street': _resStreetController.text,
  'Res Barangay': _resBarangayController.text,
  'Res City': _resCityController.text,
};
controllers.forEach((k, v) => debugPrint('  $k => "${v}"'));

// snapshot of _fieldErrors map
debugPrint('_fieldErrors.keys: ${_fieldErrors.keys.toList()}');
// human-friendly print for controller-keyed _fieldErrors
debugPrint('_fieldErrors size: ${_fieldErrors.length}');
_fieldErrors.forEach((ctrl, msg) {
  // try to map controller -> label for readable logging
  String label;
  if (identical(ctrl, _firstNameController)) label = 'First Name';
  else if (identical(ctrl, _middleNameController)) label = 'Middle Name';
  else if (identical(ctrl, _lastNameController)) label = 'Last Name';
  else if (identical(ctrl, _phoneController)) label = 'Phone Number';
  else if (identical(ctrl, _resHouseController)) label = 'Res House';
  else if (identical(ctrl, _resStreetController)) label = 'Res Street';
  else if (identical(ctrl, _resBarangayController)) label = 'Res Barangay';
  else if (identical(ctrl, _resCityController)) label = 'Res City';
  else label = ctrl.toString(); // fallback
  debugPrint('  _fieldErrors["$label"] = "$msg"');
});

// check form validator state quickly
bool formValid = _formKey.currentState?.validate() ?? true;
debugPrint('Form validate() returned: $formValid');
// DEBUG INSTRUMENTATION END


  // 2) Phone format guard (must start with 0 and be exactly 11 digits)
  final phoneVal = _phoneController.text.trim();
  if (!RegExp(r'^0\d{10}$').hasMatch(phoneVal)) {
    // trigger phone field validator display (no SnackBar)
    if (mounted) {
      setState(() {}); // forces validators / UI update
      _formKey.currentState!.validate();
    }
    return;
  }

  // All guards passed — start saving
  setState(() => _isSaving = true);

  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    

    String? profileUrl;
    if (_removeProfileImage) {
      try {
        await _supabase.storage
            .from('profiles')
            .remove(['profile_images/${user.id}.jpg']);
      } catch (_) {}
    } else if (_profileImage != null || _profileImageBytes != null) {
      final img = _profileImage ?? _profileImageBytes!;
      profileUrl = await _uploadImageToStorage(
    _profileImage ?? _profileImageBytes,
    'profile_images',
  );

      if (profileUrl == null && (img != null)) {
        debugPrint('Profile upload failed; aborting save.');
        if (mounted) {
          Flushbar(
            message: 'Failed to upload profile photo. Check storage permissions or network.',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ).show(context);
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    String? idUrl;
    if (_removeIdImage) {
      try {
        await _supabase.storage
            .from('profiles')
            .remove(['id_uploads/${user.id}.jpg']);
      } catch (_) {}
    } else if (_idImage != null || _idImageBytes != null) {
      final img = _idImage ?? _idImageBytes!;
      idUrl = await _uploadImageToStorage(_idImage ?? _idImageBytes,'id_uploads',);

      if (idUrl == null && (img != null)) {
        debugPrint('ID upload failed; aborting save.');
        if (mounted) {
          Flushbar(
            message: 'Failed to upload ID image. Check storage permissions or network.',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ).show(context);
        }
        setState(() => _isSaving = false);
        return;
      }
    }

        // Check if profile is complete (has DOB and ALL required address fields)
    final hasDOB = _dobController.text.trim().isNotEmpty;

    // Check if ALL required address fields are filled
    final hasHouseNo = _resHouseController.text.trim().isNotEmpty;
    final hasStreet = _resStreetController.text.trim().isNotEmpty;
    final hasBarangay = _resBarangayController.text.trim().isNotEmpty;
    final hasZipCode = _resZipController.text.trim().isNotEmpty;
    final hasCity = _resCityController.text.trim().isNotEmpty;

    final hasCompleteAddress = hasHouseNo && hasStreet && hasBarangay && hasZipCode && hasCity;
    final isProfileComplete = hasDOB && hasCompleteAddress;

    final updates = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'middle_name': _hasMiddleName ? _middleNameController.text.trim() : '',
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
      'blood_type': _bloodTypeController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
      
      // Auto-verify ONLY when ALL required fields are complete
      'is_verified': isProfileComplete,
    };

    if (profileUrl != null) {
      updates['photo_url'] = profileUrl;
      updates['photo_path'] = 'profile_images/${user.id}.jpg';
    }
    if (idUrl != null) {
      updates['id_url'] = idUrl;
      updates['id_path'] = 'id_uploads/${user.id}.jpg';
    }

    if (_removeProfileImage) {
      updates['photo_url'] = null;
      updates['photo_path'] = null;
    }
    if (_removeIdImage) {
      updates['id_url'] = null;
      updates['id_path'] = null;
    }

    // Simple address handling
    final addressMap = _collectAddressMap();
    updates['resident_address'] = addressMap;
    updates['address'] = _composeAddressStringFromMap(addressMap);

    // Clear other address types since we're not using categories
    updates['work_address'] = null;
    updates['home_address'] = null;
    updates['school_address'] = null;

    debugPrint('DEBUG: database updates prepared = $updates');

   // ---------- deterministic field-error population (controller-keyed) ----------
    _fieldErrors.clear(); // clear earlier programmatic errors

    // run the Form validators first
    final formOk = _formKey.currentState?.validate() ?? true;

    // personal fields
    if (_firstNameController.text.trim().isEmpty) {
      _fieldErrors[_firstNameController] = 'Please enter First Name';
    }
    if (_lastNameController.text.trim().isEmpty) {
      _fieldErrors[_lastNameController] = 'Please enter Last Name';
    }
    if (_hasMiddleName == true && _middleNameController.text.trim().isEmpty) {
      _fieldErrors[_middleNameController] = 'Please enter Middle Name';
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _fieldErrors[_phoneController] = 'Please enter Phone Number';
    } else if (!RegExp(r'^0\d{10}$').hasMatch(phone)) {
      _fieldErrors[_phoneController] = 'Enter a valid 11-digit number starting with 0';
    }

    // Address fields are optional - no validation for empty fields
    // Only validate format if field has content
    final zip = _resZipController.text.trim();
    if (zip.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(zip)) {
      _fieldErrors[_resZipController] = 'ZIP must be 4 digits';
    }

if (_fieldErrors.isNotEmpty) {
if (mounted) {
setState(() {
_autoValidateMode = AutovalidateMode.always;
});
}
return;
}


debugPrint('_fieldErrors size: ${_fieldErrors.length}');
_fieldErrors.forEach((ctrl, msg) {
debugPrint(' _fieldErrors[${ctrl.hashCode}] = "$msg"');
});

    // Show errors if any — force form to display them (existing pattern)
    if (_fieldErrors.isNotEmpty || !formOk) {
      if (mounted) {
        setState(() {
          _autoValidateMode = AutovalidateMode.always;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _formKey.currentState?.validate();
            setState(() {}); // ensure controller-keyed errorText is picked up
          }
        });
      }
      return;
    }
    // ---------- end controller-keyed population ----------

    // proceed with DB update
    Map<String, dynamic>? returnedRow;

    try {
      final resp = await _supabase
          .from('app_users')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();

      debugPrint('DB update returned: $resp');

      if (resp is Map<String, dynamic>) {
        returnedRow = resp;
      } else {
        try {
          returnedRow = (resp as dynamic)?['data'] as Map<String, dynamic>?;
        } catch (_) {
          returnedRow = null;
        }
      }

      debugPrint('Returned row: $returnedRow');
      debugPrint('DEBUG: Database update completed for user ${user.id}');

    } catch (e, st) {
      debugPrint('======== UPDATE ERROR ========');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
      if (kIsWeb) {
        debugPrint('Check browser DevTools Network/Console for CORS errors.');
      }

      if (mounted) {
        Flushbar(
          message: 'Failed to update profile: $e',
          duration: const Duration(seconds: 3),
        ).show(context);
      }

      rethrow;
    }
    if (mounted) {
      setState(() {
        _profileImage = null;
        _profileImageBytes = null;
        _profileImageUrl = null;
        _profileUploadProgress = null;
        _removeProfileImage = false;
        _idImage = null;
        _idImageBytes = null;
        _idImageUrl = null;
        _idUploadProgress = null;
        _removeIdImage = false;
      });
    }

    if (!mounted) return;
    await Flushbar(
      message: 'Profile saved successfully!',
      backgroundColor: const Color.fromARGB(255, 14, 151, 7),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
      messageColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      animationDuration: const Duration(milliseconds: 300),
      duration: const Duration(seconds: 3),
    ).show(context);

    if (!mounted) return;
    setState(() => _isFormDirty = false);

    Navigator.pop(context, true);
  } catch (e) {
    debugPrint('Error saving profile: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  Future<bool> _confirmUnsavedChanges() async {
    if (!_isFormDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Discard them and go back?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildProfileImageSection() {
    const primaryColor = Color(0xFF28588B);
    
    Widget _grayPlaceholder(double size) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.account_circle,
            size: size * 0.6,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 3),
                ),
                child: ClipOval(
                  child: _getProfileImageProvider() != null
                      ? Image(image: _getProfileImageProvider()!, fit: BoxFit.cover)
                      : _grayPlaceholder(94),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showProfileImageOptions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
              if (_profileUploadProgress != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: CircularProgressIndicator(
                              value: _profileUploadProgress,
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${((_profileUploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_profileImage != null || _profileImageBytes != null || (_profileImageUrl != null && !_removeProfileImage))
            TextButton.icon(
              onPressed: () async {
                await deleteProfileOrId(isProfile: true);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              label: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showProfileImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final hasAny = _profileImage != null || _profileImageBytes != null || _profileImageUrl != null;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                if (hasAny)
                  ListTile(
                    leading: const Icon(Icons.remove_red_eye, color: Color(0xFF28588B)),
                    title: const Text('View Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      if (_profileImage != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_profileImage!),
                            ),
                          ),
                        );
                      } else if (_profileImageBytes != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_profileImageBytes!),
                            ),
                          ),
                        );
                      } else if (_profileImageUrl != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_profileImageUrl!),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF28588B)),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF28588B)),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, true);
                  },
                ),
                if (hasAny)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                    onTap: () async {
                      Navigator.pop(context);
                      await deleteProfileOrId(isProfile: true);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          const SizedBox(height: 16),
          _buildEditableField('First Name', _firstNameController, hint: 'First Name'),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _hasMiddleName,
                  onChanged: (val) {
                    final bool newVal = val ?? false;
                    setState(() {
                      _hasMiddleName = newVal;
                      if (!newVal) {
                        _middleNameController.clear();
                        _fieldErrors.remove('Middle Name'); // <-- remove any programmatic error
                      }
                      _markFormDirty();
                    });

                    FocusScope.of(context).unfocus();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _formKey.currentState?.validate();
                    });
                  },
                ),
                const Text("I have a middle name", style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (_hasMiddleName)
            _buildEditableField(
              'Middle Name',
              _middleNameController,
              hint: 'Middle Name',
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter Middle Name';
                final pattern = RegExp(r"^[A-Za-z\s\.'-]+$");
                if (!pattern.hasMatch(val.trim())) return 'Enter a valid middle name';
                return null;
              },
            ),
          _buildEditableField('Last Name', _lastNameController, hint: 'Last Name'),
          _buildEditableField(
            'Email',
            _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            isReadOnly: true,
          ),
          _buildEditableField(
  'Phone Number',
  _phoneController,
  hint: '09123456789',
  keyboardType: TextInputType.number,
  validator: (val) {
    if (val == null || val.trim().isEmpty) return 'Please enter Phone Number';
    final s = val.trim();
    if (!RegExp(r'^0\d{10}$').hasMatch(s)) {
      return 'Enter a valid 11-digit number starting with 0';
    }
    return null;
  },
),
          _buildEditableField(
            'Date of Birth',
            _dobController,
            hint: 'MM/DD/YYYY',
            isDateField: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Address'),
          const SizedBox(height: 16),
          _buildEditableField(
            'House/Unit/Building No.', 
            _resHouseController, 
            hint: 'House/Unit',
            validator: (val) => null, // No validation for optional fields
          ),
          _buildEditableField(
            'Street Name', 
            _resStreetController, 
            hint: 'Street Name',
            validator: (val) => null,
          ),
          _buildEditableField(
            'Barangay/Subdivision', 
            _resBarangayController, 
            hint: 'Barangay Name',
            validator: (val) => null,
          ),
          _buildEditableField(
            'Town (Optional)', 
            _resTownController, 
            hint: 'Town Name',
            validator: (val) => null,
          ),
          _buildEditableField(
            'ZIP Code', 
            _resZipController, 
            hint: '1000', 
            keyboardType: TextInputType.number,
            validator: (val) {
              // Optional validation - only validate if field has content
              if (val != null && val.trim().isNotEmpty) {
                if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) {
                  return 'ZIP must be 4 digits';
                }
              }
              return null;
            },
          ),
          _buildEditableField(
            'City/Municipality', 
            _resCityController, 
            hint: 'Manila',
            validator: (val) => null,
          ),
          _buildEditableField(
            'Country', 
            _resCountryController, 
            hint: 'Philippines', 
            isReadOnly: true,
            validator: (val) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildIdUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ID Upload (optional)'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery, false),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Stack(
                children: [
                  if (_idImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _idImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildInvalidImagePlaceholder(),
                      ),
                    )
                  else if (_idImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _idImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildInvalidImagePlaceholder(),
                      ),
                    )
                  else if (_idImageUrl != null && _idImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _idImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) => _buildInvalidImagePlaceholder(),
                      ),
                    )
                  else
                    // Default placeholder when user has not uploaded anything yet
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to upload ID', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),

                  // Remove button
                  if (_idImage != null || _idImageBytes != null || (_idImageUrl != null && _idImageUrl!.isNotEmpty && !_removeIdImage))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () async {
                            await deleteProfileOrId(isProfile: false);
                          },
                        ),
                      ),
                    ),

                  // Upload progress
                  if (_idUploadProgress != null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: CircularProgressIndicator(
                                  value: _idUploadProgress,
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${((_idUploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Upload a valid government-issued ID.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildInvalidImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 6),
          Text('Invalid image', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
  

  Widget _buildHealthInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Health Information (optional)'),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _bloodTypeController,
              decoration: InputDecoration(
                labelText: 'Blood Type',
                hintText: 'O+',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final validTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
                  if (!validTypes.contains(value.toUpperCase())) {
                    return 'Invalid blood type';
                  }
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Height',
                hintText: '170 cm',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: [UnitFormatter("cm")],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.toLowerCase().endsWith('cm')) {
                    return 'Height must end with cm';
                  }
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight',
                hintText: '65 kg',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: [UnitFormatter("kg")],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.toLowerCase().endsWith('kg')) {
                    return 'Weight must end with kg';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color backgroundColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

 Widget _buildEditableField(
  String label,
  TextEditingController controller, {
  String? hint,
  TextInputType keyboardType = TextInputType.text,
  bool isDateField = false,
  bool isReadOnly = false,
  String? Function(String?)? validator,
}) {
  // fields we want to require and show red error text when empty
  const Set<String> _requiredLabels = {
    'First Name',
    'Last Name',
    'Phone Number',
    'Date of Birth',
  };

 return Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    autovalidateMode: _autoValidateMode, // ✅ add this line
    keyboardType: keyboardType,
    readOnly: isDateField || isReadOnly,

    onChanged: (val) {
      // ✅ clear field-specific errors when user types
      if (_fieldErrors.containsKey(controller)) {
        setState(() {
          _fieldErrors.remove(controller);
        });
      }

      // ✅ switch autovalidation mode back to user interaction
      if (_autoValidateMode == AutovalidateMode.always) {
        setState(() {
          _autoValidateMode = AutovalidateMode.onUserInteraction;
        });
      }

      _markFormDirty(); // keep your existing logic
    },

    inputFormatters: label == 'Phone Number'
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ]
        : (keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : []),

    onTap: isDateField
        ? () async {
            FocusScope.of(context).requestFocus(FocusNode());
            await _selectDate(context);
          }
        : null,

    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      suffixIcon:
          isDateField ? const Icon(Icons.calendar_today, size: 20) : null,

      // ✅ show controller-based error under the correct field
      errorText: _fieldErrors[controller],
    ),

    validator: (value) {
      final text = value?.trim() ?? '';

      // (1) Custom validator first
      if (validator != null) {
        final result = validator(value);
        if (result != null) return result;
      }

      // (2) Required fields
      if (_requiredLabels.contains(label) && text.isEmpty) {
        return 'Please enter $label';
      }

      // (3) Phone field validation
      if (label == 'Phone Number' && text.isNotEmpty) {
        final normalized = text.replaceAll(RegExp(r'[^0-9]'), '');
        final phoneRegex = RegExp(r'^0\d{10}$');
        if (!phoneRegex.hasMatch(normalized)) {
          return 'Enter a valid 11-digit number starting with 0';
        }
      }

      // (4) DOB validation
      if (isDateField && text.isNotEmpty) {
        try {
          final parts = text.split('/');
          if (parts.length != 3) throw FormatException();
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final dob = DateTime(year, month, day);
          final now = DateTime.now();
          int age = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
          if (age < 8) return 'Age must be at least 8 years';
          if (age > 95) return 'Age must be less than 95 years';
        } catch (_) {
          return 'Invalid date format (MM/DD/YYYY)';
        }
      }

      return null;
    },
  ),
);
}

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF28588B);
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (await _confirmUnsavedChanges()) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _confirmUnsavedChanges()) Navigator.pop(context, true);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidateMode,
            child: ListView(
              children: [
                _buildProfileImageSection(),
                const SizedBox(height: 20),
                _buildPersonalInfoSection(),
                const SizedBox(height: 20),
                _buildAddressSection(),
                const SizedBox(height: 20),
                _buildIdUploadSection(),
                const SizedBox(height: 20),
                _buildHealthInfoSection(),
                const SizedBox(height: 24),
                _buildSaveButton(primaryColor),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}