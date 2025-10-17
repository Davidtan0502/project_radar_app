import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_radar_app/screens/profile/account_information.dart';
import 'package:project_radar_app/screens/profile/emergency_contacts_screen.dart';
import 'package:project_radar_app/screens/profile/help_and_support.dart';
import 'package:project_radar_app/screens/profile/settings&privacy_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';
import 'package:project_radar_app/widgets/capitalize_names.dart';
import 'package:shimmer/shimmer.dart';

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
  String _resolvedPhotoURL = ''; // final URL to use in Image.network
  bool _isVerified = false;
  String _email = '';
  final SupabaseClient _supabase = Supabase.instance.client;

  // NEW: store latest user document map so we can inspect addresses and dob
  Map<String, dynamic>? _userDataMap;

  // cache resolved storage paths to URLs to avoid repeated calls
  final Map<String, String> _resolvedUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen to auth state changes for real-time updates
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _firstName = '';
            _lastName = '';
            _photoURL = '';
            _resolvedPhotoURL = '';
            _isVerified = false;
            _email = '';
            _userDataMap = null;
          });
        }
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('app_users')
            .select()
            .eq('id', user.id)
            .single();

        if (response != null) {
          final data = response;
          final rawPhoto = (data['photo_url'] ?? '').toString().trim();

          setState(() {
            _userDataMap = Map<String, dynamic>.from(data);
            _firstName = capitalizeName(data['first_name'] ?? '');
            _lastName = capitalizeName(data['last_name'] ?? '');
            _isVerified = data['is_verified'] ?? false;
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
          // fallback to auth user info
          final rawPhoto = (user.userMetadata?['avatar_url'] ?? '').toString().trim();
          final fullName = user.userMetadata?['full_name']?.toString() ?? '';

          setState(() {
            _userDataMap = null;
            _firstName = fullName.isNotEmpty ? capitalizeName(fullName) : 'User';
            _lastName = '';
            _isVerified = false; // Supabase doesn't have emailConfirmed property
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

  /// Normalize storage paths for Supabase Storage
  String _normalizeStoragePath(String raw) {
    var p = raw.trim();

    // If it's an http url, return it as-is
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    // For Supabase storage paths, they're usually relative to the bucket
    // Remove any leading slashes
    p = p.replaceFirst(RegExp(r'^/'), '');

    return p;
  }

  Future<void> _resolvePhotoUrlIfNeeded(String photoUrl) async {
    if (!mounted) return;
    if (photoUrl.isEmpty) {
      if (mounted) setState(() => _resolvedPhotoURL = '');
      return;
    }

    final raw = photoUrl;

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

    // Normalize path and try to get public URL
    final normalizedPath = _normalizeStoragePath(raw);
    debugPrint('DEBUG: Attempting to resolve profile photo path "$raw" -> normalized "$normalizedPath"');

    try {
      // Supabase storage provides direct public URLs
      final url = _supabase.storage.from('avatars').getPublicUrl(normalizedPath);
      if (!mounted) return;
      
      // Cache and set
      _resolvedUrlCache[raw] = url;
      setState(() => _resolvedPhotoURL = url);
      debugPrint('DEBUG: Resolved storage path "$raw" -> $url');
      return;
    } catch (e) {
      // couldn't resolve: leave _resolvedPhotoURL empty and print debug info
      debugPrint('DEBUG: unable to resolve photo storage path "$raw": $e');

      // As a fallback, try the common folder structure
      try {
        final userId = _supabase.auth.currentUser?.id ?? '';
        if (userId.isNotEmpty) {
          final guessed = 'profile_images/$userId.jpg';
          debugPrint('DEBUG: trying guessed path "$guessed"');
          final url2 = _supabase.storage.from('avatars').getPublicUrl(guessed);
          if (!mounted) return;
          _resolvedUrlCache[raw] = url2;
          setState(() => _resolvedPhotoURL = url2);
          debugPrint('DEBUG: Resolved guessed path -> $url2');
          return;
        }
      } catch (e2) {
        debugPrint('DEBUG: guessed path also failed: $e2');
      }

      // final fallback: leave resolved empty so UI uses placeholder
      if (mounted) setState(() => _resolvedPhotoURL = '');
      return;
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Confirm Logout",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Text(
                  "Are you sure you want to log out? You'll need to sign in again to access your account.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "Cancel",
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
                        onPressed: () async {
                          await _supabase.auth.signOut();
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(onTap: () {}),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Logout",
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
      },
    );
  }

  // ----------------- completeness helpers -----------------
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

  bool _isProfileCompleteForCategory(Map<String, dynamic>? data) {
    if (data == null) return false;

    // Require DOB present
    final dob = (data['dob'] ?? '').toString().trim();
    final hasDob = dob.isNotEmpty;
    if (!hasDob) return false;

    final category = (data['user_category'] ?? '').toString().toUpperCase();

    if (category == 'RESIDENT') {
      final resident = data['resident_address'] is Map ? Map<String, dynamic>.from(data['resident_address']) : null;
      return _hasNonEmpty(resident, ['house', 'street', 'barangay', 'zip']) && _hasTownOrCity(resident);
    } else if (category == 'EMPLOYEE') {
      final work = data['work_address'] is Map ? Map<String, dynamic>.from(data['work_address']) : null;
      final home = data['home_address'] is Map ? Map<String, dynamic>.from(data['home_address']) : null;
      return _hasNonEmpty(work, ['street', 'barangay', 'zip']) && _hasTownOrCity(work) &&
             _hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && _hasTownOrCity(home);
    } else if (category == 'STUDENT') {
      final school = data['school_address'] is Map ? Map<String, dynamic>.from(data['school_address']) : null;
      final home = data['home_address'] is Map ? Map<String, dynamic>.from(data['home_address']) : null;
      return _hasNonEmpty(school, ['school_name', 'street', 'barangay', 'zip']) && _hasTownOrCity(school) &&
             _hasNonEmpty(home, ['house', 'street', 'barangay', 'zip']) && _hasTownOrCity(home);
    } else {
      // unknown category: accept if any address map or legacy address exist
      final fallback = (data['address'] ?? '').toString().trim();
      final anyMapPresent = (data['resident_address'] is Map && (data['resident_address'] as Map).isNotEmpty) ||
                           (data['work_address'] is Map && (data['work_address'] as Map).isNotEmpty) ||
                           (data['school_address'] is Map && (data['school_address'] as Map).isNotEmpty) ||
                           (data['home_address'] is Map && (data['home_address'] as Map).isNotEmpty);
      return fallback.isNotEmpty || anyMapPresent;
    }
  }
  // ----------------- END helpers -----------------

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF28588B);
    const backgroundColor = Color(0xFFF8F9FA);

    final fullName = '$_firstName $_lastName'.trim();

    // Determine whether we should show the verified icon:
    final dbIsVerified = (_userDataMap != null) ? (_userDataMap!['is_verified'] ?? false) : _isVerified;
    final profileIsComplete = _isProfileCompleteForCategory(_userDataMap);
    final shouldShowVerified = profileIsComplete || dbIsVerified;

    // Fetch DOB from stored user map if available
    final dobRaw = (_userDataMap != null) ? (_userDataMap!['dob'] ?? '') : '';
    final dobDisplay = (dobRaw != null && dobRaw.toString().trim().isNotEmpty) ? dobRaw.toString() : '-';

    // --- Header sizing that matches CommunityScreen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenHeight * 0.08;
    final sidePadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header (now matches Community header style/size) — wrapped in SafeArea to match Community's SafeArea behavior
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

          // Profile Section
          Container(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05, // 5% left
                MediaQuery.of(context).size.height * 0.001, // 1% top - minimal space
                MediaQuery.of(context).size.width * 0.05, // 5% right
                MediaQuery.of(context).size.height * 0.02, // 2% bottom
              ),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: _isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
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
                                  final fallback = _supabase.auth.currentUser?.userMetadata?['avatar_url'] ?? '';
                                  if (fallback.isNotEmpty) {
                                    return Image.network(
                                      fallback,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildProfilePlaceholder(),
                                    );
                                  }
                                  return _buildProfilePlaceholder();
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
                                  final fallback = _supabase.auth.currentUser?.userMetadata?['avatar_url'] ?? '';
                                  if (fallback.isNotEmpty) {
                                    return Image.network(
                                      fallback,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildProfilePlaceholder(),
                                    );
                                  }
                                  return _buildProfilePlaceholder();
                                },
                              ),
                            );
                          }

                          // Otherwise show placeholder
                          return _buildProfilePlaceholder();
                        })(),
                ),

                const SizedBox(height: 20),

                // Name with verification badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 180,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                        padding: EdgeInsets.only(left: 3.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Email and Birthday
                if (_isLoading)
                  Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 200,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                      ),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        _email,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      // Birthday line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cake_outlined, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            dobDisplay,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Options List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  // Profile Options Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildModernOptionTile(
                          icon: Icons.person_outline,
                          title: 'Account Information',
                          subtitle: 'View and manage your account details',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountInformationScreen(),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1, color: Colors.grey.shade200),
                        ),
                        _buildModernOptionTile(
                          icon: Icons.contact_phone_outlined,
                          title: 'Emergency Contacts',
                          subtitle: 'Manage your emergency contacts',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmergencyContactsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings & Support Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildModernOptionTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings & Privacy',
                          subtitle: 'Manage your app settings and privacy',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1, color: Colors.grey.shade200),
                        ),
                        _buildModernOptionTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact support',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.red.shade100,
                        width: 1,
                      ),
                    ),
                    child: _buildModernOptionTile(
                      icon: Icons.logout_outlined,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      isDestructive: true,
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.account_circle, size: 120, color: Colors.grey),
    );
  }

  Widget _buildModernOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFF28588B);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}