import 'package:flutter/foundation.dart';
import 'dart:io';
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

  // Basic Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  // Keep legacy single address too (for backward compatibility)
  final _addressController = TextEditingController();

  // Health / other
  final _bloodTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Town options (same as register)
  final List<String> _towns = [
    "Tondo",
    "Binondo",
    "Quiapo",
    "Intramuros",
    "Ermita",
    "Malate",
    "Paco",
    "Pandacan",
    "Port Area",
    "San Nicolas",
    "Santa Ana",
    "Santa Cruz",
    "Santa Mesa",
    "San Miguel",
    "San Andres Bukid",
    "Sampaloc",
  ];

  // New: address controllers for Resident
  final _resHouseController = TextEditingController();
  final _resStreetController = TextEditingController();
  final _resBarangayController = TextEditingController();
  final _resTownController = TextEditingController();
  final _resTownManualController = TextEditingController();
  final _resZipController = TextEditingController();
  final _resCityController = TextEditingController(text: "Manila City");
  final _resCountryController = TextEditingController(text: "Philippines");

  // New: Work address controllers
  final _workStreetController = TextEditingController();
  final _workBarangayController = TextEditingController();
  final _workTownController = TextEditingController();
  final _workTownManualController = TextEditingController();
  final _workZipController = TextEditingController();
  final _workCityController = TextEditingController(text: "Manila City");
  final _workCountryController = TextEditingController(text: "Philippines");

  // New: Home address controllers (used by EMPLOYEE and STUDENT)
  final _homeHouseController = TextEditingController();
  final _homeStreetController = TextEditingController();
  final _homeBarangayController = TextEditingController();
  final _homeTownController = TextEditingController();
  final _homeTownManualController = TextEditingController();
  final _homeZipController = TextEditingController();
  final _homeCityController = TextEditingController();
  final _homeCountryController = TextEditingController(text: "Philippines");

  // New: School address controllers
  final _schoolNameController = TextEditingController();
  final _schoolStreetController = TextEditingController();
  final _schoolBarangayController = TextEditingController();
  final _schoolTownController = TextEditingController();
  final _schoolTownManualController = TextEditingController();
  final _schoolZipController = TextEditingController();
  final _schoolCityController = TextEditingController(text: "Manila City");
  final _schoolCountryController = TextEditingController(text: "Philippines");

  // track user category from supabase (RESIDENT / EMPLOYEE / STUDENT)
  String? _userCategory;
  // store initial category loaded from database to detect changes
  String? _initialUserCategory;

  // NEW: optional middle name checkbox state
  bool _hasMiddleName = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeFormListeners();
    _addAddressCapitalizationListeners();
    _loadUserData();

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
      _userCategory = (data['user_category'] ?? '').toString().trim().toUpperCase();
      _initialUserCategory = _userCategory;
      String composedAddress = '';
      if ((data['address'] ?? '').toString().trim().isNotEmpty) {
        composedAddress = data['address'].toString();
      }

      Map<String, dynamic>? safeMap(dynamic v) {
        if (v is Map) return Map<String, dynamic>.from(v);
        return null;
      }

      final residentMap = safeMap(data['resident_address']);
      final homeMap = safeMap(data['home_address']);
      final workMap = safeMap(data['work_address']);
      final schoolMap = safeMap(data['school_address']);

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

        // Work
        if (workMap != null && workMap.isNotEmpty) {
          _workStreetController.text = workMap['street']?.toString() ?? '';
          _workBarangayController.text = workMap['barangay']?.toString() ?? '';
          _workTownController.text = workMap['town']?.toString() ?? '';
          _workZipController.text = workMap['zip']?.toString() ?? '';
          _workCityController.text = workMap['city']?.toString() ?? (_workCityController.text);
          _workCountryController.text = workMap['country']?.toString() ?? 'Philippines';
        }

        // Home
        if (homeMap != null && homeMap.isNotEmpty) {
          _homeHouseController.text = homeMap['house']?.toString() ?? '';
          _homeStreetController.text = homeMap['street']?.toString() ?? '';
          _homeBarangayController.text = homeMap['barangay']?.toString() ?? '';
          _homeTownController.text = homeMap['town']?.toString() ?? '';
          _homeZipController.text = homeMap['zip']?.toString() ?? '';
          _homeCityController.text = homeMap['city']?.toString() ?? _homeCityController.text;
          _homeCountryController.text = homeMap['country']?.toString() ?? 'Philippines';
        }

        // School
        if (schoolMap != null && schoolMap.isNotEmpty) {
          _schoolNameController.text = schoolMap['school_name']?.toString() ?? '';
          _schoolStreetController.text = schoolMap['street']?.toString() ?? '';
          _schoolBarangayController.text = schoolMap['barangay']?.toString() ?? '';
          _schoolTownController.text = schoolMap['town']?.toString() ?? '';
          _schoolZipController.text = schoolMap['zip']?.toString() ?? '';
          _schoolCityController.text = schoolMap['city']?.toString() ?? (_schoolCityController.text);
          _schoolCountryController.text = schoolMap['country']?.toString() ?? 'Philippines';
        }

        _normalizeLoadedTownValue(_workTownController, _workTownManualController);
        _normalizeLoadedTownValue(_schoolTownController, _schoolTownManualController);
        _normalizeLoadedTownValue(_homeTownController, _homeTownManualController);

        _isFormDirty = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _normalizeLoadedTownValue(TextEditingController main, TextEditingController manual) {
    final val = main.text.trim();
    if (val.isNotEmpty && !_towns.contains(val)) {
      manual.text = val;
      main.text = 'Other';
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
      _resTownManualController,
      _resZipController,
      _resCityController,
      _resCountryController,
      // work
      _workStreetController,
      _workBarangayController,
      _workTownController,
      _workTownManualController,
      _workZipController,
      _workCityController,
      _workCountryController,
      // home
      _homeHouseController,
      _homeStreetController,
      _homeBarangayController,
      _homeTownController,
      _homeTownManualController,
      _homeZipController,
      _homeCityController,
      _homeCountryController,
      // school
      _schoolNameController,
      _schoolStreetController,
      _schoolBarangayController,
      _schoolTownController,
      _schoolTownManualController,
      _schoolZipController,
      _schoolCityController,
      _schoolCountryController,
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
      _workStreetController,
      _workBarangayController,
      _workTownController,
      _homeHouseController,
      _homeStreetController,
      _homeBarangayController,
      _workCityController,
      _homeTownController,
      _homeCityController,
      _schoolNameController,
      _schoolStreetController,
      _schoolBarangayController,
      _schoolTownController,
      _schoolCityController,
      _resTownManualController,
      _workTownManualController,
      _homeTownManualController,
      _schoolTownManualController,
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
    _resTownManualController.dispose();
    _resZipController.dispose();
    _resCityController.dispose();
    _resCountryController.dispose();

    _workStreetController.dispose();
    _workBarangayController.dispose();
    _workTownController.dispose();
    _workTownManualController.dispose();
    _workZipController.dispose();
    _workCityController.dispose();
    _workCountryController.dispose();

    _homeHouseController.dispose();
    _homeStreetController.dispose();
    _homeBarangayController.dispose();
    _homeTownController.dispose();
    _homeTownManualController.dispose();
    _homeZipController.dispose();
    _homeCityController.dispose();
    _homeCountryController.dispose();

    _schoolNameController.dispose();
    _schoolStreetController.dispose();
    _schoolBarangayController.dispose();
    _schoolTownController.dispose();
    _schoolTownManualController.dispose();
    _schoolZipController.dispose();
    _schoolCityController.dispose();
    _schoolCountryController.dispose();

    super.dispose();
  }

  bool _isFileSizeValid(File file, {int maxSizeMB = 5}) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
  }

  Future<String?> _uploadImageToStorage(dynamic image, String path) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      String fileName = '${user.id}.jpg';
      String fullPath = '$path/$fileName';

      if (image is File) {
        await _supabase.storage
            .from('avatars')
            .upload(fullPath, image);
      } else if (image is Uint8List) {
        await _supabase.storage
            .from('avatars')
            .uploadBinary(fullPath, image);
      } else {
        throw ArgumentError('Unsupported image type for upload');
      }

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fullPath);

      debugPrint('Uploaded to: $publicUrl');
      return publicUrl;

    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
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

  Map<String, dynamic> _collectAddressMap({
    required TextEditingController house,
    required TextEditingController street,
    required TextEditingController barangay,
    required TextEditingController townMain,
    required TextEditingController townManual,
    required TextEditingController zip,
    required TextEditingController city,
    required TextEditingController country,
  }) {
    final String townValue = _getTownValue(townMain, townManual);
    return {
      'house': house.text.trim(),
      'street': street.text.trim(),
      'barangay': barangay.text.trim(),
      'town': townValue,
      'zip': zip.text.trim(),
      'city': city.text.trim(),
      'country': country.text.trim(),
    };
  }

  String _getTownValue(TextEditingController main, TextEditingController manual) {
    final mainVal = main.text.trim();
    if (mainVal.toLowerCase() == 'other') {
      return manual.text.trim();
    }
    return mainVal;
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
    if (m['zip'] != null && m['zip'].toString().trim().isNotEmpty) parts.add('ZIP ${m['zip'].toString().trim()}');
    return parts.join(', ');
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!);
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) return NetworkImage(_profileImageUrl!);
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      String? profileUrl;
      if (_removeProfileImage) {
        try {
          await _supabase.storage
              .from('avatars')
              .remove(['profile_images/${user.id}.jpg']);
        } catch (_) {}
      } else if (_profileImage != null || _profileImageBytes != null) {
        final img = _profileImage ?? _profileImageBytes!;
        profileUrl = await _uploadImageToStorage(img, 'profile_images');
      }

      String? idUrl;
      if (_removeIdImage) {
        try {
          await _supabase.storage
              .from('avatars')
              .remove(['id_uploads/${user.id}.jpg']);
        } catch (_) {}
      } else if (_idImage != null || _idImageBytes != null) {
        final img = _idImage ?? _idImageBytes!;
        idUrl = await _uploadImageToStorage(img, 'id_uploads');
      }

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
      };

      if (profileUrl != null) {
        updates['photo_url'] = profileUrl;
      }
      if (idUrl != null) {
        updates['id_url'] = idUrl;
      }

      if (_removeProfileImage) {
        updates['photo_url'] = null;
      }
      if (_removeIdImage) {
        updates['id_url'] = null;
      }

      if ((_userCategory ?? '').isNotEmpty) {
        updates['user_category'] = (_userCategory ?? '').toString().toUpperCase();
      }

      final newCat = (_userCategory ?? '').toString().toUpperCase();
      final oldCat = (_initialUserCategory ?? '').toString().toUpperCase();

      if (newCat == 'RESIDENT') {
        final map = _collectAddressMap(
          house: _resHouseController,
          street: _resStreetController,
          barangay: _resBarangayController,
          townMain: _resTownController,
          townManual: _resTownManualController,
          zip: _resZipController,
          city: _resCityController,
          country: _resCountryController,
        );
        updates['resident_address'] = map;
        updates['address'] = _composeAddressStringFromMap(map);
      } else if (newCat == 'EMPLOYEE') {
        final workMap = _collectAddressMap(
          house: TextEditingController(),
          street: _workStreetController,
          barangay: _workBarangayController,
          townMain: _workTownController,
          townManual: _workTownManualController,
          zip: _workZipController,
          city: _workCityController,
          country: _workCountryController,
        );
        final homeMap = _collectAddressMap(
          house: _homeHouseController,
          street: _homeStreetController,
          barangay: _homeBarangayController,
          townMain: _homeTownController,
          townManual: _homeTownManualController,
          zip: _homeZipController,
          city: _homeCityController,
          country: _homeCountryController,
        );
        updates['work_address'] = workMap;
        updates['home_address'] = homeMap;
        updates['address'] = _composeAddressStringFromMap(homeMap);
      } else if (newCat == 'STUDENT') {
        final schoolMap = {
          'school_name': _schoolNameController.text.trim(),
          'street': _schoolStreetController.text.trim(),
          'barangay': _schoolBarangayController.text.trim(),
          'town': _getTownValue(_schoolTownController, _schoolTownManualController),
          'zip': _schoolZipController.text.trim(),
          'city': _schoolCityController.text.trim(),
          'country': _schoolCountryController.text.trim(),
        };
        final homeMap = _collectAddressMap(
          house: _homeHouseController,
          street: _homeStreetController,
          barangay: _homeBarangayController,
          townMain: _homeTownController,
          townManual: _homeTownManualController,
          zip: _homeZipController,
          city: _homeCityController,
          country: _homeCountryController,
        );
        updates['school_address'] = schoolMap;
        updates['home_address'] = homeMap;
        updates['address'] = _composeAddressStringFromMap(homeMap);
      }

      if (oldCat != newCat) {
        if (newCat == 'RESIDENT') {
          updates['work_address'] = null;
          updates['home_address'] = null;
          updates['school_address'] = null;
        } else if (newCat == 'EMPLOYEE') {
          updates['resident_address'] = null;
          updates['school_address'] = null;
        } else if (newCat == 'STUDENT') {
          updates['resident_address'] = null;
          updates['work_address'] = null;
        } else {
          updates['resident_address'] = null;
          updates['work_address'] = null;
          updates['school_address'] = null;
          updates['home_address'] = null;
        }
      }

      debugPrint('DEBUG: database updates prepared = $updates');

      final response = await _supabase
          .from('app_users')
          .update(updates)
          .eq('id', user.id);

      if (response.error != null) {
        throw Exception('Failed to update profile: ${response.error!.message}');
      }

      debugPrint('DEBUG: Database update completed for user ${user.id}');

      _initialUserCategory = _userCategory;

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
        backgroundColor: const Color(0xFF28588B),
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
              onPressed: () {
                setState(() {
                  _removeProfileImage = true;
                  _profileImage = null;
                  _profileImageBytes = null;
                  _profileImageUrl = null;
                  _markFormDirty();
                });
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
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _removeProfileImage = true;
                        _profileImage = null;
                        _profileImageBytes = null;
                        _profileImageUrl = null;
                        _markFormDirty();
                      });
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
                    setState(() {
                      _hasMiddleName = val ?? false;
                      if (!_hasMiddleName) {
                        _middleNameController.clear();
                      }
                      _markFormDirty();
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
            keyboardType: TextInputType.phone,
          ),
          _buildEditableField(
            'Date of Birth',
            _dobController,
            hint: 'MM/DD/YYYY',
            isDateField: true,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: (_userCategory != null && _userCategory!.isNotEmpty) ? _userCategory!.toUpperCase() : null,
              decoration: InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: <Map<String, String>>[
                {'value': 'RESIDENT', 'label': 'Resident'},
                {'value': 'EMPLOYEE', 'label': 'Employee'},
                {'value': 'STUDENT', 'label': 'Student'},
              ].map((m) {
                return DropdownMenuItem<String>(
                  value: m['value'],
                  child: Text(m['label'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _userCategory = (val ?? '').toString().toUpperCase();
                  _markFormDirty();
                });
              },
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please select a category';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final cat = (_userCategory ?? 'RESIDENT').toUpperCase();
    
    Widget _buildAddressCard(String title, List<Widget> children) {
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }

    if (cat == 'EMPLOYEE') {
      return Column(
        children: [
          _buildAddressCard('Work Address', [
            _buildEditableField('Street/Building No.', _workStreetController, hint: 'Street / Building'),
            _buildEditableField('Barangay/Subdivision', _workBarangayController, hint: 'Barangay / Subdivision'),
            _buildTownDropdown(_workTownController, _workTownManualController, 'Town (optional)'),
            _buildEditableField('ZIP Code', _workZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
              if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
              return null;
            }),
            _buildEditableField('City/Municipality', _workCityController, hint: 'City', isReadOnly: false),
            _buildEditableField('Country', _workCountryController, hint: 'Philippines', isReadOnly: true),
          ]),
          const SizedBox(height: 16),
          _buildAddressCard('Home Address', [
            _buildEditableField('House/Unit/Building No.', _homeHouseController, hint: 'House/Unit'),
            _buildEditableField('Street Name', _homeStreetController, hint: 'Street Name'),
            _buildEditableField('Barangay/Subdivision', _homeBarangayController, hint: 'Barangay Name'),
            _buildTownDropdown(_homeTownController, _homeTownManualController, 'Town (optional)'),
            _buildEditableField('ZIP Code', _homeZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
              if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
              return null;
            }),
            _buildEditableField('City/Municipality', _homeCityController, hint: 'City'),
            _buildEditableField('Country', _homeCountryController, hint: 'Philippines', isReadOnly: true),
          ]),
        ],
      );
    } else if (cat == 'STUDENT') {
      return Column(
        children: [
          _buildAddressCard('School Address', [
            _buildEditableField('Full School Name', _schoolNameController, hint: 'Full School Name'),
            _buildEditableField('Street Name', _schoolStreetController, hint: 'Street Name'),
            _buildEditableField('Barangay/Subdivision', _schoolBarangayController, hint: 'Barangay Name'),
            _buildTownDropdown(_schoolTownController, _schoolTownManualController, 'Town'),
            _buildEditableField('ZIP Code', _schoolZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
              if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
              return null;
            }),
            _buildEditableField('City/Municipality', _schoolCityController, hint: 'City', isReadOnly: false),
            _buildEditableField('Country', _schoolCountryController, hint: 'Philippines', isReadOnly: true),
          ]),
          const SizedBox(height: 16),
          _buildAddressCard('Home Address', [
            _buildEditableField('House/Unit/Building No.', _homeHouseController, hint: 'House/Unit'),
            _buildEditableField('Street Name', _homeStreetController, hint: 'Street Name'),
            _buildEditableField('Barangay/Subdivision', _homeBarangayController, hint: 'Barangay Name'),
            _buildEditableField('Town (Optional)', _homeTownController, hint: 'Town Name', validator: (val) {return null;}),
            if (_homeTownController.text.toLowerCase() == 'other')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _homeTownManualController,
                  decoration: InputDecoration(
                    labelText: 'Type town name',
                    hintText: 'Enter town',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            _buildEditableField('ZIP Code', _homeZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
              if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
              return null;
            }),
            _buildEditableField('City/Municipality', _homeCityController, hint: 'City'),
            _buildEditableField('Country', _homeCountryController, hint: 'Philippines', isReadOnly: true),
          ]),
        ],
      );
    } else {
      final List<DropdownMenuItem<String>> residentTownItems = [
        ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
      ];
      final currentResTown = _resTownController.text.trim();
      if (currentResTown.isNotEmpty && !_towns.contains(currentResTown)) {
        residentTownItems.add(DropdownMenuItem(value: currentResTown, child: Text(currentResTown)));
      }

      return _buildAddressCard('Address', [
        _buildEditableField('House/Unit/Building No.', _resHouseController, hint: 'House/Unit'),
        _buildEditableField('Street Name', _resStreetController, hint: 'Street Name'),
        _buildEditableField('Barangay/Subdivision', _resBarangayController, hint: 'Barangay Name'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: _resTownController.text.isNotEmpty ? _resTownController.text : null,
            items: residentTownItems,
            onChanged: (val) {
              setState(() {
                _resTownController.text = val ?? '';
                _markFormDirty();
              });
            },
            decoration: InputDecoration(
              labelText: 'Town',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        _buildEditableField('ZIP Code', _resZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
          return null;
        }),
        _buildEditableField('City/Municipality', _resCityController, hint: 'Manila', isReadOnly: true),
        _buildEditableField('Country', _resCountryController, hint: 'Philippines', isReadOnly: true),
      ]);
    }
  }

  Widget _buildTownDropdown(TextEditingController mainController, TextEditingController manualController, String label) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: mainController.text.isNotEmpty ? mainController.text : null,
            items: [
              ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
              const DropdownMenuItem(value: 'Other', child: Text('Other (type manually)')),
            ],
            onChanged: (val) {
              setState(() {
                mainController.text = val ?? '';
                if (val != 'Other') manualController.clear();
                _markFormDirty();
              });
            },
            decoration: InputDecoration(
              labelText: label,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (mainController.text.toLowerCase() == 'other')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: manualController,
              decoration: InputDecoration(
                labelText: 'Type town name',
                hintText: 'Enter town',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
      ],
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
                  _idImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_idImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      )
                    : (_idImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_idImageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          )
                        : (_idImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_idImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Tap to upload ID', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ))),
                  if (_idImage != null || _idImageBytes != null || (_idImageUrl != null && !_removeIdImage))
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
                          onPressed: () {
                            setState(() {
                              _removeIdImage = true;
                              _idImage = null;
                              _idImageBytes = null;
                              _idImageUrl = null;
                              _markFormDirty();
                            });
                          },
                        ),
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isDateField || isReadOnly,
        onTap: isDateField
            ? () async {
                FocusScope.of(context).requestFocus(FocusNode());
                await _selectDate(context);
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isDateField ? const Icon(Icons.calendar_today, size: 20) : null,
        ),
        validator: (value) {
          if (validator != null) return validator(value);
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (isDateField) {
            try {
              final parts = value.split('/');
              if (parts.length != 3) throw FormatException();
              final m = int.parse(parts[0]);
              final d = int.parse(parts[1]);
              final y = int.parse(parts[2]);
              final dob = DateTime(y, m, d);
              final today = DateTime.now();
              int age = today.year - dob.year;
              if (today.month < dob.month ||
                  (today.month == dob.month && today.day < dob.day)) {
                age--;
              }
              if (age < 8) {
                return 'Age must be at least 8 years';
              }
              if (age >= 95) {
                return 'Age must be less than 95 years';
              }
            } catch (_) {
              return 'Invalid date format';
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