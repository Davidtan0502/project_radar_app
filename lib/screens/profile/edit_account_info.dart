import 'package:flutter/foundation.dart'; // add for kIsWeb
import 'dart:typed_data'; // for Uint8List (web)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:project_radar_app/screens/profile/account_management_screen.dart';
import 'package:project_radar_app/services/navigation.dart';
import 'package:flutter/services.dart'; // for TextInputFormatter
import 'dart:math' as math;

// WEB TESTING NOTE:
// If images load on mobile but not in Chrome (web build): it's almost always a CORS configuration
// issue on the Firebase Storage bucket. Mobile native SDKs don't need CORS.
// Check bucket CORS if you see network console errors in the browser.

class UnitFormatter extends TextInputFormatter {
  final String unit;

  UnitFormatter(this.unit);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final lower = text.toLowerCase();

    if (lower.endsWith(unit)) {
      // Ensure a single space before the unit
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
  String? _profileImageUrl; // remote profile image URL (if exists)
  String? _idImageUrl; // remote id image URL (if exists)
  Uint8List? _profileImageBytes; // for web preview/upload
  Uint8List? _idImageBytes;      // for web preview/upload

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
  final _resTownController = TextEditingController(); // this holds the dropdown value (dropdown-only)
  final _resTownManualController = TextEditingController(); // kept but NOT used for resident (kept for compatibility)
  final _resZipController = TextEditingController();
  final _resCityController = TextEditingController(text: "Manila City"); // always autofilled & read-only
  final _resCountryController = TextEditingController(text: "Philippines"); // read-only

  // New: Work address controllers
  final _workStreetController = TextEditingController();
  final _workBarangayController = TextEditingController();
  final _workTownController = TextEditingController();
  final _workTownManualController = TextEditingController();
  final _workZipController = TextEditingController();
  final _workCityController = TextEditingController(text: "Manila City"); // editable for EMPLOYEE
  final _workCountryController = TextEditingController(text: "Philippines"); // read-only

  // New: Home address controllers (used by EMPLOYEE and STUDENT)
  final _homeHouseController = TextEditingController();
  final _homeStreetController = TextEditingController();
  final _homeBarangayController = TextEditingController();
  final _homeTownController = TextEditingController();
  final _homeTownManualController = TextEditingController();
  final _homeZipController = TextEditingController();
  final _homeCityController = TextEditingController();
  final _homeCountryController = TextEditingController(text: "Philippines"); // read-only

  // New: School address controllers
  final _schoolNameController = TextEditingController();
  final _schoolStreetController = TextEditingController();
  final _schoolBarangayController = TextEditingController();
  final _schoolTownController = TextEditingController();
  final _schoolTownManualController = TextEditingController();
  final _schoolZipController = TextEditingController();
  final _schoolCityController = TextEditingController(text: "Manila City"); // editable for STUDENT
  final _schoolCountryController = TextEditingController(text: "Philippines"); // read-only

  // track user category from firestore (RESIDENT / EMPLOYEE / STUDENT)
  String? _userCategory;
  // store initial category loaded from Firestore to detect changes
  String? _initialUserCategory;

  // NEW: optional middle name checkbox state
  bool _hasMiddleName = false;

  @override
  void initState() {
    super.initState();
    _initializeFormListeners();
    _addAddressCapitalizationListeners();
    _loadUserData();

    _bloodTypeController.addListener(() {
      final input = _bloodTypeController.text.toUpperCase(); // convert to uppercase
      final validTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

      // Only update if input is one of the valid types or a valid prefix
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    // read userCategory if present
    _userCategory = (data['userCategory'] ?? '').toString().trim().toUpperCase();
    // remember initial category to detect changes later and delete old maps if needed
    _initialUserCategory = _userCategory;
    // Compose address if legacy flat 'address' exists
    String composedAddress = '';
    if ((data['address'] ?? '').toString().trim().isNotEmpty) {
      composedAddress = data['address'].toString();
    }

    // Helper to safely read nested maps
    Map<String, dynamic>? safeMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final residentMap = safeMap(data['residentAddress']);
    final homeMap = safeMap(data['homeAddress']);
    final workMap = safeMap(data['workAddress']);
    final schoolMap = safeMap(data['schoolAddress']);

    setState(() {
      _firstNameController.text = _capitalizeWords(data['firstName'] ?? '');
      _middleNameController.text = _capitalizeWords(data['middleName'] ?? '');
      // set hasMiddleName depending on whether middle name exists
      _hasMiddleName = (_middleNameController.text.trim().isNotEmpty);

      _lastNameController.text = _capitalizeWords(data['lastName'] ?? '');
      _emailController.text = data['email'] ?? '';
      _phoneController.text = _formatPhone(data['phone'] ?? '');
      _dobController.text = data['dob'] ?? '';
      _bloodTypeController.text = data['bloodType'] ?? '';
      _heightController.text = data['height'] ?? '';
      _weightController.text = data['weight'] ?? '';

      // prefer Firestore photoURL, fallback to FirebaseAuth user photoURL
      final fsPhoto = (data['photoURL'] ?? '')..toString().trim();
      _profileImageUrl = fsPhoto.isNotEmpty ? fsPhoto : (user.photoURL ?? null);

      final fsId = (data['idURL'] ?? '')..toString().trim();
      _idImageUrl = fsId.isNotEmpty ? fsId : null;

      // Populate address controllers according to priority:
      // If nested maps exist for respective addresses, use those.
      // Otherwise, if legacy composedAddress exists, keep it in _addressController.
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
        _schoolNameController.text = schoolMap['schoolName']?.toString() ?? '';
        _schoolStreetController.text = schoolMap['street']?.toString() ?? '';
        _schoolBarangayController.text = schoolMap['barangay']?.toString() ?? '';
        _schoolTownController.text = schoolMap['town']?.toString() ?? '';
        _schoolZipController.text = schoolMap['zip']?.toString() ?? '';
        _schoolCityController.text = schoolMap['city']?.toString() ?? (_schoolCityController.text);
        _schoolCountryController.text = schoolMap['country']?.toString() ?? 'Philippines';
      }

      // For resident: DO NOT convert unknown town into 'Other' manual.
      // For work/home/school keep normalize behavior:
      _normalizeLoadedTownValue(_workTownController, _workTownManualController);
      _normalizeLoadedTownValue(_schoolTownController, _schoolTownManualController);
      _normalizeLoadedTownValue(_homeTownController, _homeTownManualController);

      _isFormDirty = false;
    });
  }

  void _normalizeLoadedTownValue(TextEditingController main, TextEditingController manual) {
    final val = main.text.trim();
    if (val.isNotEmpty && !_towns.contains(val)) {
      // move to manual controller and mark main as 'Other' so dropdown shows Other selected
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
    // Controllers to auto-capitalize each word for addresses & school name
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
      _homeTownController,
      _homeCityController,
      _schoolNameController,
      _schoolStreetController,
      _schoolBarangayController,
      _schoolTownController,
      // Add manual town controllers so manual typed town names are also capitalized:
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
          // preserve cursor position as best as possible
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

  // Upload helper: accepts File (mobile) or Uint8List (web)
  Future<String?> _uploadImageToStorage(dynamic image, String path) async {
    // image: either File (mobile) or Uint8List (web)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final ref = FirebaseStorage.instance.ref().child(path).child('${user.uid}.jpg');

    // set metadata for correct content-type
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    UploadTask uploadTask;
    if (image is File) {
      uploadTask = ref.putFile(image, metadata);
    } else if (image is Uint8List) {
      uploadTask = ref.putData(image, metadata);
    } else {
      throw ArgumentError('Unsupported image type for upload');
    }

    uploadTask.snapshotEvents.listen((event) {
      final progress = event.totalBytes > 0 ? event.bytesTransferred / event.totalBytes : 0.0;
      setState(() {
        if (path.contains('profile_images')) {
          _profileUploadProgress = progress;
        } else {
          _idUploadProgress = progress;
        }
      });
    });

    try {
      // Await upload and log debug info (useful to diagnose web issues)
      final snapshot = await uploadTask;

      // briefly show 100%
      setState(() {
        if (path.contains('profile_images')) {
          _profileUploadProgress = 1.0;
        } else {
          _idUploadProgress = 1.0;
        }
      });
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        if (path.contains('profile_images')) {
          _profileUploadProgress = null;
        } else {
          _idUploadProgress = null;
        }
      });

      // Try to get download URL and log it for debugging
      try {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('DEBUG: uploaded to path: ${snapshot.ref.fullPath}');
        debugPrint('DEBUG: downloadURL -> $downloadUrl');
        return downloadUrl;
      } catch (e, st) {
        debugPrint('DEBUG: getDownloadURL failed for ${snapshot.ref.fullPath} -> $e\n$st');
        return null;
      }
    } catch (e, st) {
      // Upload failed
      debugPrint('DEBUG: upload failed for path ${ref.fullPath} -> $e\n$st');
      // ensure progress cleared
      setState(() {
        if (path.contains('profile_images')) {
          _profileUploadProgress = null;
        } else {
          _idUploadProgress = null;
        }
      });
      return null;
    }
  }

 // UPDATED: show preview BEFORE committing selection, supports web + mobile
Future<void> _pickImage(ImageSource source, bool isProfile) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source);
  if (picked == null) return;

  // On web we read bytes; on mobile we can use File from path
  Uint8List? bytes;
  File? file;
  try {
    if (kIsWeb) {
      // WEB: read image as bytes for preview and upload via putData
      bytes = await picked.readAsBytes();
      debugPrint('DEBUG: picked image (web) bytes=${bytes.lengthInBytes}');
    } else {
      // Mobile: we can use File path
      file = File(picked.path);
      debugPrint('DEBUG: picked image (mobile) path=${picked.path}');
    }
  } catch (e) {
    debugPrint('Error reading picked image: $e');
    return;
  }

  // Validate size (for web bytes or file)
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

  // Show a preview dialog so user can inspect before committing.
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
    // reopen camera
    await _pickImage(ImageSource.camera, isProfile);
  } else if (action == 'gallery') {
    await _pickImage(ImageSource.gallery, isProfile);
  } else {
    // cancel -> do nothing
  }
}

// NEW: generic preview dialog that accepts either File or Uint8List
// returns 'use'|'retake'|'gallery'|'cancel'
// Web testing note: on web this dialog displays Image.memory(...) (in-memory preview).
Future<String?> _showImagePreviewBeforeSave(dynamic image, bool isProfile) {
  // image: File (mobile) or Uint8List (web)
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Widget content;
      if (image is Uint8List) {
        // WEB: show in-memory preview using Image.memory
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
      firstDate: ninetyfiveYearsAgo, // no older than 95 yrs
      lastDate: eightYearsAgo, // no younger than 8 yrs
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
    required TextEditingController townMain, // main dropdown controller
    required TextEditingController townManual, // manual controller
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

  // Return actual town value to save: if main == 'Other' use manual controller, otherwise main value
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

  // ---------- REPLACE _getProfileImageProvider() ----------
  ImageProvider? _getProfileImageProvider() {
  // priority: local File (mobile) -> in-memory bytes (web) -> remote URL -> null (no image)
  if (_profileImage != null) return FileImage(_profileImage!);
  if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!); // WEB: show picked image before upload
  if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) return NetworkImage(_profileImageUrl!);
  // Return null so CircleAvatar will display its child (icon/placeholder)
  return null;
}

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? profileUrl;
      // If removeProfileImage is true - we'll delete the storage object and remove field in Firestore
      if (_removeProfileImage) {
        try {
          await FirebaseStorage.instance.ref('profile_images/${user.uid}.jpg').delete();
        } catch (_) {
          // ignore delete errors
        }
      } else if (_profileImage != null || _profileImageBytes != null) {
        final img = _profileImage ?? _profileImageBytes!;
        profileUrl = await _uploadImageToStorage(img, 'profile_images');
      }

      String? idUrl;
      if (_removeIdImage) {
        try {
          await FirebaseStorage.instance.ref('id_uploads/${user.uid}.jpg').delete();
        } catch (_) {
          // ignore delete errors
        }
      } else if (_idImage != null || _idImageBytes != null) {
        final img = _idImage ?? _idImageBytes!;
        idUrl = await _uploadImageToStorage(img, 'id_uploads');
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Build maps conditionally depending on userCategory
      final updates = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'middleName': _hasMiddleName ? _middleNameController.text.trim() : '',
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'bloodType': _bloodTypeController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        if (profileUrl != null) 'photoURL': profileUrl,
        if (idUrl != null) 'idURL': idUrl,
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If user explicitly removed profile image -> remove field in Firestore
      if (_removeProfileImage) {
        updates['photoURL'] = FieldValue.delete();
      }
      if (_removeIdImage) {
        updates['idURL'] = FieldValue.delete();
      }

      // Persist the userCategory as well (so change is saved to Firestore)
      if ((_userCategory ?? '').isNotEmpty) {
        updates['userCategory'] = (_userCategory ?? '').toString().toUpperCase();
      }

      // address composition based on category (keeps your original logic)
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
        updates['residentAddress'] = map;
        updates['address'] = _composeAddressStringFromMap(map);
        // ensure other maps removed if category changed
      } else if (newCat == 'EMPLOYEE') {
        final workMap = _collectAddressMap(
          house: TextEditingController(), // work has no house in register schema; keep empty
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
        updates['workAddress'] = workMap;
        updates['homeAddress'] = homeMap;
        updates['address'] = _composeAddressStringFromMap(homeMap);
      } else if (newCat == 'STUDENT') {
        final schoolMap = {
          'schoolName': _schoolNameController.text.trim(),
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
        updates['schoolAddress'] = schoolMap;
        updates['homeAddress'] = homeMap;
        updates['address'] = _composeAddressStringFromMap(homeMap);
      } else {
        // no extra address maps for unknown category; keep legacy single address if present
      }

      // ---------- NEW: Delete old category-specific maps when category changed ----------
      if (oldCat != newCat) {
        // If user changed category, remove maps that are NOT relevant to the new category
        // This ensures old category data is deleted as requested.
        if (newCat == 'RESIDENT') {
          updates['workAddress'] = FieldValue.delete();
          updates['homeAddress'] = FieldValue.delete();
          updates['schoolAddress'] = FieldValue.delete();
        } else if (newCat == 'EMPLOYEE') {
          updates['residentAddress'] = FieldValue.delete();
          updates['schoolAddress'] = FieldValue.delete();
        } else if (newCat == 'STUDENT') {
          updates['residentAddress'] = FieldValue.delete();
          updates['workAddress'] = FieldValue.delete();
        } else {
          // unknown -> delete all specialized maps
          updates['residentAddress'] = FieldValue.delete();
          updates['workAddress'] = FieldValue.delete();
          updates['schoolAddress'] = FieldValue.delete();
          updates['homeAddress'] = FieldValue.delete();
        }
      }
      // -------------------------------------------------------------------------------

      debugPrint('DEBUG: firestore updates prepared = $updates');

      // Write to Firestore: use update when delete flags present so FieldValue.delete() is applied,
      // otherwise use set(merge:true) to avoid overwriting unexpected fields.
      try {
        if (_removeProfileImage || _removeIdImage || (oldCat != newCat)) {
          // use update so FieldValue.delete() is applied
          await docRef.update(updates);
        } else {
          await docRef.set(updates, SetOptions(merge: true));
        }
      } catch (e) {
        // Fallback: if update fails, attempt merge set (keeps behavior robust)
        debugPrint('DEBUG: Firestore write fallback (update/set failed) -> $e');
        await docRef.set(updates, SetOptions(merge: true));
      }

      debugPrint('DEBUG: Firestore set/update completed for user ${user.uid}');

      // update FirebaseAuth user photo as well so other parts of app that read auth user are in sync
      if (profileUrl != null) {
        try {
          await user.updatePhotoURL(profileUrl);
          await user.reload();
        } catch (_) {}
      } else if (_removeProfileImage) {
        try {
          await user.updatePhotoURL(null);
          await user.reload();
        } catch (_) {}
      }

      // update initial category snapshot so further edits won't be considered a "change" unless user actually changes again
      _initialUserCategory = _userCategory;

      // Clear local state so UI shows placeholder immediately (no stale URL)
      if (mounted) {
        setState(() {
          // profile
          _profileImage = null;
          _profileImageBytes = null;
          _profileImageUrl = null;
          _profileUploadProgress = null;
          _removeProfileImage = false;
          // id
          _idImage = null;
          _idImageBytes = null;
          _idImageUrl = null;
          _idUploadProgress = null;
          _removeIdImage = false;
        });
      }

      // Top notification
      if (!mounted) return;
      await Flushbar(
        message: 'Profile saved successfully!',
        backgroundColor: const Color.fromARGB(255, 25, 167, 0),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(
          Icons.check_circle,
          color: Colors.white,
        ),
        messageColor: const Color.fromARGB(255, 255, 255, 255),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        animationDuration: const Duration(milliseconds: 300),
        duration: const Duration(seconds: 3),
      ).show(context);

      if (!mounted) return;
      setState(() => _isFormDirty = false);

      // Pop after notification disappears
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  Future<bool> _confirmUnsavedChanges() async {
    // If no edits, allow pop immediately
    if (!_isFormDirty) return true;

    // Otherwise show confirmation dialog
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
            // Close the dialog and return `false`
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            // Close the dialog and return `true`
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // If somehow null, treat as cancel
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radarBlue = const Color(0xFF1565C0);
    return WillPopScope(
      onWillPop: _confirmUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: radarBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmUnsavedChanges()) Navigator.pop(context, true);
            },
          ),
          elevation: 0,
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildProfileImageSection(),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(),
                const SizedBox(height: 24),
                _buildAddressSection(), // NEW: conditional address UI
                const SizedBox(height: 24),
                _buildIdUploadSection(),
                const SizedBox(height: 24),
                _buildHealthInfoSection(),
                const SizedBox(height: 30),
                _buildSaveButton(radarBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showProfileImageOptions(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _getProfileImageProvider(),
                    child: _profileImage == null &&
                            _profileImageBytes == null && // WEB: prevent showing icon when using MemoryImage
                            _profileImageUrl == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
              ),
              if (_profileImage != null ||
                  _profileImageBytes != null || // WEB: allow edit when MemoryImage is used
                  _profileImageUrl != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: () => _showProfileImageOptions(),
                    ),
                  ),
                ),
              // Upload progress overlay
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
          const SizedBox(height: 12),
          // show remove button only if local or remote image exists and not already flagged removed
          if ((_profileImage != null || _profileImageBytes != null || (_profileImageUrl != null && !_removeProfileImage)))
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _removeProfileImage = true;
                  _profileImage = null;
                  _profileImageBytes = null; // clear web bytes too
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

  // show bottom sheet with options to view/take/choose/remove
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
                    leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    title: const Text('View Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // VIEW: if local File -> show Image.file; if web bytes -> Image.memory; else Image.network
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
                        // WEB: preview memory image
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
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information'),
        const SizedBox(height: 12),
        _buildEditableField('First Name', _firstNameController, hint: 'First Name'),
        // Middle name is optional with checkbox
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
            // make validator only when enabled
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
          isReadOnly: true, // prevent editing
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

        // === NEW: Editable Category Dropdown ===
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: (_userCategory != null && _userCategory!.isNotEmpty) ? _userCategory!.toUpperCase() : null,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                // Note: don't clear address fields automatically — keep user-provided data
                // so they can re-use or edit as needed. Address logic on save will use the
                // selected _userCategory to write the appropriate maps.
              });
            },
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please select a category';
              return null;
            },
          ),
        ),
        // === end category ===

        // legacy single Address left out visually; separate fields used instead
      ],
    );
  }

  Widget _buildAddressSection() {
    // default fallback: show resident if no category known
    final cat = (_userCategory ?? 'RESIDENT').toUpperCase();
    if (cat == 'EMPLOYEE') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text('Work Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEditableField('Street/Building No.', _workStreetController, hint: 'Street / Building'),
          _buildEditableField('Barangay/Subdivision', _workBarangayController, hint: 'Barangay / Subdivision'),
          // Town Dropdown for work (optional + manual "Other")
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _workTownController.text.isNotEmpty ? _workTownController.text : null,
              items: [
                ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
                const DropdownMenuItem(value: 'Other', child: Text('Other (type manually)')),
              ],
              onChanged: (val) {
                setState(() {
                  _workTownController.text = val ?? '';
                  // if user selects an actual town, clear manual value
                  if (val != 'Other') _workTownManualController.clear();
                  _markFormDirty();
                });
              },
              decoration: InputDecoration(
                labelText: 'Town (optional)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              // town is optional now: no validation
            ),
          ),
          // manual town input shown only when 'Other' is selected
          if (_workTownController.text.toLowerCase() == 'other')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _workTownManualController,
                decoration: InputDecoration(
                  labelText: 'Type town name',
                  hintText: 'Enter town',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          _buildEditableField('ZIP Code', _workZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
            if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
            return null;
          }),
          // City is editable for EMPLOYEE (per your request)
          _buildEditableField('City/Municipality', _workCityController, hint: 'City', isReadOnly: false),
          // Country read-only
          _buildEditableField('Country', _workCountryController, hint: 'Philippines', isReadOnly: true),
          const SizedBox(height: 16),
          const Text('Home Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEditableField('House/Unit/Building No.', _homeHouseController, hint: 'House/Unit'),
          _buildEditableField('Street Name', _homeStreetController, hint: 'Street Name'),
          _buildEditableField('Barangay/Subdivision', _homeBarangayController, hint: 'Barangay Name'),
          // Home town dropdown optional + manual
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _homeTownController.text.isNotEmpty ? _homeTownController.text : null,
              items: [
                ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
                const DropdownMenuItem(value: 'Other', child: Text('Other (type manually)')),
              ],
              onChanged: (val) {
                setState(() {
                  _homeTownController.text = val ?? '';
                  if (val != 'Other') _homeTownManualController.clear();
                  _markFormDirty();
                });
              },
              decoration: InputDecoration(
                labelText: 'Town (optional)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
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
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          _buildEditableField('ZIP Code', _homeZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
            if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
            return null;
          }),
          _buildEditableField('City/Municipality', _homeCityController, hint: 'City',),
          _buildEditableField('Country', _homeCountryController, hint: 'Philippines', isReadOnly: true),
        ],
      );
    } else if (cat == 'STUDENT') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text('School Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEditableField('Full School Name', _schoolNameController, hint: 'Full School Name'),
          _buildEditableField('Street Name', _schoolStreetController, hint: 'Street Name'),
          _buildEditableField('Barangay/Subdivision', _schoolBarangayController, hint: 'Barangay Name'),
          // School town dropdown optional + manual
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _schoolTownController.text.isNotEmpty ? _schoolTownController.text : null,
              items: [
                ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
                const DropdownMenuItem(value: 'Other', child: Text('Other (type manually)')),
              ],
              onChanged: (val) {
                setState(() {
                  _schoolTownController.text = val ?? '';
                  if (val != 'Other') _schoolTownManualController.clear();
                  _markFormDirty();
                });
              },
              decoration: InputDecoration(
                labelText: 'Town',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (_schoolTownController.text.toLowerCase() == 'other')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _schoolTownManualController,
                decoration: InputDecoration(
                  labelText: 'Type town name',
                  hintText: 'Enter town',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          _buildEditableField('ZIP Code', _schoolZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
            if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
            return null;
          }),
          // City is editable for STUDENT (per your request)
          _buildEditableField('City/Municipality', _schoolCityController, hint: 'City', isReadOnly: false),
          _buildEditableField('Country', _schoolCountryController, hint: 'Philippines', isReadOnly: true),
          const SizedBox(height: 16),
          const Text('Home Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEditableField('House/Unit/Building No.', _homeHouseController, hint: 'House/Unit'),
          _buildEditableField('Street Name', _homeStreetController, hint: 'Street Name'),
          _buildEditableField('Barangay/Subdivision', _homeBarangayController, hint: 'Barangay Name'),
          _buildEditableField('Town (Optional)', _homeTownController, hint: 'Town Name', validator: (val) {return null;},),
          // if homeTown is 'Other' show manual input
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
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          _buildEditableField('ZIP Code', _homeZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
            if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
            return null;
          }),
          _buildEditableField('City/Municipality', _homeCityController, hint: 'City',),
          _buildEditableField('Country', _homeCountryController, hint: 'Philippines', isReadOnly: true),
        ],
      );
    } else {
      // RESIDENT or default — show resident address (dropdown-only town)
      // If the loaded resident town is not in _towns, include it dynamically so the dropdown can show it.
      final List<DropdownMenuItem<String>> residentTownItems = [
        ..._towns.map((town) => DropdownMenuItem(value: town, child: Text(town))),
      ];
      final currentResTown = _resTownController.text.trim();
      if (currentResTown.isNotEmpty && !_towns.contains(currentResTown)) {
        residentTownItems.add(DropdownMenuItem(value: currentResTown, child: Text(currentResTown)));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text('Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEditableField('House/Unit/Building No.', _resHouseController, hint: 'House/Unit'),
          _buildEditableField('Street Name', _resStreetController, hint: 'Street Name'),
          _buildEditableField('Barangay/Subdivision', _resBarangayController, hint: 'Barangay Name'),
          // Resident town dropdown: dropdown-only (no Other/manual option)
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
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              // town optional (no validation) — remains dropdown-only
            ),
          ),
          _buildEditableField('ZIP Code', _resZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
            if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
            return null;
          }),
          _buildEditableField('City/Municipality', _resCityController, hint: 'Manila', isReadOnly: true),
          _buildEditableField('Country', _resCountryController, hint: 'Philippines', isReadOnly: true),
        ],
      );
    }
  }

  Widget _buildIdUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ID Upload (optional)'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery, false),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Stack(
              children: [
                // Show priority: local File -> in-memory bytes (web) -> remote URL -> placeholder
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
                // Add a small remove icon overlay when id exists
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
    );
  }

  Widget _buildHealthInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Health Information (optional)'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _bloodTypeController,
            decoration: InputDecoration(
              labelText: 'Blood Type',
              hintText: 'O+',
              filled: true,
              fillColor: Colors.white,
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
              return null; // allow blank
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
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            inputFormatters: [UnitFormatter("cm")], // Auto space cm
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
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            inputFormatters: [UnitFormatter("kg")], // Auto space kg
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

  // Slightly extended helper: accepts optional validator
  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isDateField = false,
    bool isReadOnly = false, // new
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
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isDateField ? const Icon(Icons.calendar_today, size: 20) : null,
        ),
        validator: (value) {
          // custom validator precedence
          if (validator != null) return validator(value);
          // default validation: required
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
}
