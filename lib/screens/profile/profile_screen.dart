import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_radar_app/screens/profile/account_information.dart';
import 'package:project_radar_app/screens/profile/emergency_contacts_screen.dart';
import 'package:project_radar_app/screens/profile/help_and_support.dart';
import 'package:project_radar_app/screens/profile/settings&privacy_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/widgets/capitalize_names.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_storage/firebase_storage.dart'; // added to resolve storage paths to download URLs

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _firstName = '';
  String _lastName = '';
  String _photoURL = '';
  String _resolvedPhotoURL = ''; // final URL to use in Image.network (may be same as _photoURL)
  bool _isVerified = false;
  String _email = '';
  Stream<DocumentSnapshot>? _userDocStream;
  late final User? _user;

  // NEW: store latest user document map so we can inspect addresses and dob
  Map<String, dynamic>? _userDataMap;

  // cache resolved storage paths to download URLs to avoid repeated getDownloadURL() calls
  final Map<String, String> _resolvedUrlCache = {};

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      // Listen to the user document so changes (like isVerified) show up immediately
      _userDocStream =
          FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots();
      _userDocStream!.listen(
        (doc) async {
          if (!mounted) return;
          final data = (doc.data() as Map<String, dynamic>?) ?? {};

          // prefer photoURL stored in document, then auth user photoURL
          final rawPhoto = (data['photoURL'] ?? _user!.photoURL ?? '').toString().trim();

          setState(() {
            _userDataMap = data; // store for completeness/dob checks
            _firstName = capitalizeName(data['firstName'] ?? '');
            _lastName = capitalizeName(data['lastName'] ?? '');
            _isVerified = data['isVerified'] ?? false;
            _photoURL = rawPhoto;
            _email = (data['email'] ?? _user!.email) ?? '';
            _isLoading = false;
          });

          // If user removed their photo, clear cache & resolved url so placeholder is immediate
          if (rawPhoto.isEmpty) {
            _resolvedUrlCache.clear();
            if (mounted) setState(() => _resolvedPhotoURL = '');
            return;
          }

          // resolve photo URL if needed (non-blocking)
          await _resolvePhotoUrlIfNeeded(_photoURL);
        },
        onError: (_) {
          // Fallback to one-time load if stream errors
          _loadUserData();
        },
      );
    } else {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _user;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data()!;
          final rawPhoto = (data['photoURL'] ?? user.photoURL ?? '').toString().trim();

          setState(() {
            _userDataMap = Map<String, dynamic>.from(data);
            _firstName = capitalizeName(data['firstName'] ?? '');
            _lastName = capitalizeName(data['lastName'] ?? '');
            _isVerified = data['isVerified'] ?? false;
            _photoURL = rawPhoto;
            _email = (data['email'] ?? user.email) ?? '';
            _isLoading = false;
          });

          // If user removed photo, clear cache & resolved url immediately
          if (rawPhoto.isEmpty) {
            _resolvedUrlCache.clear();
            if (mounted) setState(() => _resolvedPhotoURL = '');
            return;
          }

          // resolve photo URL if needed
          await _resolvePhotoUrlIfNeeded(_photoURL);
        } else {
          // fallback to FirebaseAuth info
          final displayName = user.displayName ?? '';
          final parts = displayName.split(' ');
          final rawPhoto = (user.photoURL ?? '').toString().trim();

          setState(() {
            _userDataMap = null;
            _firstName = parts.isNotEmpty ? capitalize(parts.first) : 'User';
            _lastName = parts.length > 1 ? capitalize(parts.last) : '';
            _isVerified = user.emailVerified;
            _photoURL = rawPhoto;
            _email = user.email ?? '';
            _isLoading = false;
          });

          if (rawPhoto.isEmpty) {
            _resolvedUrlCache.clear();
            if (mounted) setState(() => _resolvedPhotoURL = '');
            return;
          }

          await _resolvePhotoUrlIfNeeded(_photoURL);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading user data: $e');
    }
  }

  /// Normalize common storage-string formats into a 'ref child path' we can pass to FirebaseStorage.ref().child(path)
  /// Examples handled:
  /// - already http(s) -> returns unchanged (caller will use direct URL)
  /// - "gs://bucket/path/to/file.jpg" -> -> "path/to/file.jpg"
  /// - leading "/" -> trimmed
  /// - raw filename or "profile_images/uid.jpg" -> used as-is
  String _normalizeStoragePath(String raw) {
    var p = raw.trim();

    // If it's an http url, return it as-is
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    // gs://bucket/path/to/file.jpg  -> strip gs://<bucket>/
    if (p.startsWith('gs://')) {
      // remove 'gs://'
      final withoutScheme = p.replaceFirst(RegExp(r'^gs://'), '');
      // remove bucket name and leading slash
      final firstSlash = withoutScheme.indexOf('/');
      if (firstSlash >= 0 && firstSlash + 1 < withoutScheme.length) {
        p = withoutScheme.substring(firstSlash + 1);
      } else {
        // fallback to whatever remains
        p = withoutScheme;
      }
    }

    // If it's a firebase console 'gs' like "bucket/o/path%2Ffile.jpg" sometimes appears, decode if needed:
    // remove leading "o/" or "b/<bucket>/o/" patterns (in case user stored an API-like path)
    p = p.replaceFirst(RegExp(r'^o/'), '');
    p = p.replaceFirst(RegExp(r'^/'), '');

    // If the path contains URL-encoded slashes (e.g. profile_images%2Fuid.jpg) decode
    if (p.contains('%2F') || p.contains('%2f')) {
      try {
        p = Uri.decodeFull(p);
      } catch (_) {}
    }

    return p;
  }

  // Try to resolve a photo path stored in Firestore to a real download URL
  // If photoUrl already looks like an http(s) URL we use it directly.
  // If it's a storage path (e.g. "profile_images/uid.jpg" or just a filename),
  // attempt to call Firebase Storage to getDownloadURL. Failures are caught and
  // ignored (we leave _resolvedPhotoURL empty so placeholder is shown).
  Future<void> _resolvePhotoUrlIfNeeded(String photoUrl) async {
    if (!mounted) return;
    if (photoUrl == null || photoUrl.toString().trim().isEmpty) {
      if (mounted) setState(() => _resolvedPhotoURL = '');
      return;
    }

    final raw = photoUrl.toString().trim();

    // Quick heuristic: if it already starts with http(s) use directly
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (mounted) setState(() => _resolvedPhotoURL = raw);
      return;
    }

    // If we've already resolved this raw string before return cached
    if (_resolvedUrlCache.containsKey(raw)) {
      final cached = _resolvedUrlCache[raw]!;
      if (mounted) setState(() => _resolvedPhotoURL = cached);
      return;
    }

    // Normalize common variants and try to get download URL
    final normalizedPath = _normalizeStoragePath(raw);
    debugPrint('DEBUG: Attempting to resolve profile photo path "$raw" -> normalized "$normalizedPath"');

    try {
      final ref = FirebaseStorage.instance.ref().child(normalizedPath);
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      // Cache and set
      _resolvedUrlCache[raw] = url;
      setState(() => _resolvedPhotoURL = url);
      debugPrint('DEBUG: Resolved storage path "$raw" -> $url');
      return;
    } catch (e) {
      // couldn't resolve: leave _resolvedPhotoURL empty and print debug info
      debugPrint('DEBUG: unable to resolve photo storage path "$raw": $e');

      // As a last-ditch fallback, if the stored value looked like just a filename,
      // try the common folder we use in the uploader: "profile_images/<uid>.jpg"
      try {
        final userId = _user?.uid ?? '';
        if (userId.isNotEmpty) {
          final guessed = 'profile_images/$userId.jpg';
          debugPrint('DEBUG: trying guessed path "$guessed"');
          final ref2 = FirebaseStorage.instance.ref().child(guessed);
          final url2 = await ref2.getDownloadURL();
          if (!mounted) return;
          _resolvedUrlCache[raw] = url2;
          setState(() => _resolvedPhotoURL = url2);
          debugPrint('DEBUG: Resolved guessed path -> $url2');
          return;
        }
      } catch (e2) {
        debugPrint('DEBUG: guessed path also failed: $e2');
      }

      // final fallback: leave resolved empty so UI uses placeholder or auth photo later
      if (mounted) setState(() => _resolvedPhotoURL = '');
      return;
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(onTap: () {}),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ----------------- NEW: completeness helpers -----------------
  // Returns true if the given map has a non-empty value for any city-like key
  bool _hasAnyCityLike(Map<String, dynamic>? m) {
    if (m == null) return false;
    final keys = [
      'city',
      'municipality',
      'cityMunicipality',
      'city_municipality',
      'homeCity',
      'workCity',
      'schoolCity'
    ];
    for (final k in keys) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isNotEmpty) return true;
    }
    return false;
  }

  // treat "town" optional: completeness accepts either town OR any city-like key
  bool _hasTownOrCity(Map<String, dynamic>? m) {
    if (m == null) return false;
    final town = (m['town'] ?? '').toString().trim();
    if (town.isNotEmpty) return true;
    return _hasAnyCityLike(m);
  }

  bool _hasNonEmpty(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return false;
    for (final k in keys) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isEmpty) return false;
    }
    return true;
  }

  // Reuse same category completion rules used elsewhere, but allow home town optional
  bool _isProfileCompleteForCategory(Map<String, dynamic>? data) {
    if (data == null) return false;

    // NEW: require DOB present (non-empty) for profile to be considered complete.
    // This ensures the verified icon won't show if DOB wasn't provided.
    final dob = (data['dob'] ?? '').toString().trim();
    if (dob.isEmpty) return false;

    final category = (data['userCategory'] ?? '').toString().toUpperCase();

    if (category == 'RESIDENT') {
      final resident = data['residentAddress'] is Map ? Map<String, dynamic>.from(data['residentAddress']) : null;
      // require house, street, barangay, zip AND (town OR city/municipality)
      return _hasNonEmpty(resident, ['house', 'street', 'barangay', 'zip']) && _hasTownOrCity(resident);
    } else if (category == 'EMPLOYEE') {
      final work = data['workAddress'] is Map ? Map<String, dynamic>.from(data['workAddress']) : null;
      final home = data['homeAddress'] is Map ? Map<String, dynamic>.from(data['homeAddress']) : null;
      // require work address complete (street, barangay, zip + town/city) and home complete (house,street,barangay,zip + town/city)
      return _hasNonEmpty(work, ['street', 'barangay', 'zip']) && _hasTownOrCity(work) &&
             _hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && _hasTownOrCity(home);
    } else if (category == 'STUDENT') {
      final school = data['schoolAddress'] is Map ? Map<String, dynamic>.from(data['schoolAddress']) : null;
      final home = data['homeAddress'] is Map ? Map<String, dynamic>.from(data['homeAddress']) : null;
      // require school (schoolName,street,barangay,zip + town/city) AND home (house,street,barangay,zip + town/city)
      return _hasNonEmpty(school, ['schoolName', 'street', 'barangay', 'zip']) && _hasTownOrCity(school) &&
             _hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && _hasTownOrCity(home);
    } else {
      // unknown category: accept if any address map or legacy address exist
      final fallback = (data['address'] ?? '').toString().trim();
      final anyMapPresent = (data['residentAddress'] is Map && (data['residentAddress'] as Map).isNotEmpty) ||
                           (data['workAddress'] is Map && (data['workAddress'] as Map).isNotEmpty) ||
                           (data['schoolAddress'] is Map && (data['schoolAddress'] as Map).isNotEmpty) ||
                           (data['homeAddress'] is Map && (data['homeAddress'] as Map).isNotEmpty);
      return fallback.isNotEmpty || anyMapPresent;
    }
  }
  // ----------------- END helpers -----------------

  @override
  Widget build(BuildContext context) {
    final fullName = '$_firstName $_lastName'.trim();

    // Determine whether we should show the verified icon:
    final dbIsVerified = (_userDataMap != null) ? (_userDataMap!['isVerified'] ?? false) : _isVerified;
    final profileIsComplete = _isProfileCompleteForCategory(_userDataMap);
    final shouldShowVerified = dbIsVerified && profileIsComplete;

    // Fetch DOB from stored user map if available
    final dobRaw = (_userDataMap != null) ? (_userDataMap!['dob'] ?? '') : '';
    final dobDisplay = (dobRaw != null && dobRaw.toString().trim().isNotEmpty) ? dobRaw.toString() : '-';

    // --- Header sizing that matches CommunityScreen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenHeight * 0.08;
    final sidePadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor:  const Color(0xFFF5F8FC),
      body: Column(
        children: [

          SafeArea(
            top: true,
            child: Container(
              height: headerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF3F73A3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: headerHeight * 0.3,
                horizontal: sidePadding,
              ),
              child: Row(
                children: const [
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Section (Messenger-style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // Profile Picture
                // <-- SAFER: prefer resolved http(s) URLs, avoid Image.network on raw storage paths,
                // clear placeholder immediately when photo is removed
                
              Transform.translate(
                offset: const Offset(0, -35),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: const Icon(Icons.account_circle, size: 120),
                        )
                      : (() {
                          // decide which URL to use (prefer resolved storage URLs)
                          final resolved = _resolvedPhotoURL.trim();
                          final raw = _photoURL.trim();

                          // If we have a resolved http(s) url, use it
                          if (resolved.isNotEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                resolved,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  debugPrint('DEBUG: failed to load resolved profile image -> $resolved');
                                  // fall back to auth photo (if any) or placeholder
                                  final fallback = _user?.photoURL ?? '';
                                  if (fallback.isNotEmpty) {
                                    return Image.network(
                                      fallback,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 120, color: Colors.grey),
                                    );
                                  }
                                  return const Icon(Icons.account_circle, size: 120, color: Colors.grey);
                                },
                              ),
                            );
                          }

                          // If raw looks like an http(s) URL, use it directly
                          if (raw.toLowerCase().startsWith('http://') || raw.toLowerCase().startsWith('https://')) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                raw,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  debugPrint('DEBUG: failed to load raw profile image -> $raw');
                                  final fallback = _user?.photoURL ?? '';
                                  if (fallback.isNotEmpty) {
                                    return Image.network(
                                      fallback,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 120, color: Colors.grey),
                                    );
                                  }
                                  return const Icon(Icons.account_circle, size: 120, color: Colors.grey);
                                },
                              ),
                            );
                          }

                          // Otherwise show placeholder (we avoid calling Image.network on storage paths)
                          return const Icon(Icons.account_circle, size: 120, color: Colors.grey);
                        })(),
                ),
              ),

                const SizedBox(height: 0),

                // Name with verification badge
              Transform.translate(
                offset: const Offset(0, -18), // move name up by 12px; reduce magnitude if it overlaps
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 180,
                          height: 28,
                          color: Colors.white,
                        ),
                      )
                    else
                      Text(
                        fullName.isNotEmpty ? fullName : 'Guest User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                    if (!_isLoading && shouldShowVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),

                const SizedBox(height: 0),

                // Email
                Transform.translate(
                offset: const Offset(0, -12),
                child: _isLoading
                  ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 200,
                      height: 16,
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 4),
                    ),
                  )
                  : Column(
                    children: [
                      Text(
                        _email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      
                      // NEW: Birthday line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cake, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            dobDisplay,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 2),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Options List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView(
                children: [
                  _buildOptionTile(
                    icon: Icons.person_outline,
                    title: 'Account Information',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountInformationScreen(),
                      ),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.settings,
                    title: 'Settings & Privacy',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.contact_phone,
                    title: 'Emergency Contacts',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyContactsScreen(),
                      ),
                    ),
                  ),
                  _buildOptionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: _logout,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F0FA),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : const Color(0xFF28588B),
          size: 24,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
