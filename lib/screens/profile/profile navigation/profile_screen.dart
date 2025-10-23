import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/account_information.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/emergency_contacts_screen.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/help%20and%20support%20files/help_and_support.dart';
import 'package:project_radar_app/screens/profile/profile%20navigation/settings&privacy_screen.dart';
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
  String _resolvedPhotoURL = '';
  bool _isVerified = false;
  String _email = '';
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userDataMap;
  final Map<String, String> _resolvedUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

          if (rawPhoto.isEmpty) {
            _resolvedUrlCache.clear();
            if (mounted) setState(() => _resolvedPhotoURL = '');
            return;
          }

          await _resolvePhotoUrlIfNeeded(_photoURL);
        } else {
          final rawPhoto = (user.userMetadata?['avatar_url'] ?? '').toString().trim();
          final fullName = user.userMetadata?['full_name']?.toString() ?? '';

          setState(() {
            _userDataMap = null;
            _firstName = fullName.isNotEmpty ? capitalizeName(fullName) : 'User';
            _lastName = '';
            _isVerified = false;
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

  String _normalizeStoragePath(String raw) {
    var p = raw.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
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

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (mounted) setState(() => _resolvedPhotoURL = raw);
      return;
    }

    if (_resolvedUrlCache.containsKey(raw)) {
      final cached = _resolvedUrlCache[raw]!;
      if (mounted) setState(() => _resolvedPhotoURL = cached);
      return;
    }

    final normalizedPath = _normalizeStoragePath(raw);
    
    try {
      final url = _supabase.storage.from('avatars').getPublicUrl(normalizedPath);
      if (!mounted) return;
      
      _resolvedUrlCache[raw] = url;
      setState(() => _resolvedPhotoURL = url);
      return;
    } catch (e) {
      try {
        final userId = _supabase.auth.currentUser?.id ?? '';
        if (userId.isNotEmpty) {
          final guessed = 'profile_images/$userId.jpg';
          final url2 = _supabase.storage.from('avatars').getPublicUrl(guessed);
          if (!mounted) return;
          _resolvedUrlCache[raw] = url2;
          setState(() => _resolvedPhotoURL = url2);
          return;
        }
      } catch (e2) {
        debugPrint('DEBUG: guessed path also failed: $e2');
      }

      if (mounted) setState(() => _resolvedPhotoURL = '');
      return;
    }
  }

  void _logout() {
  final parentContext = context; // capture outer context

  showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) {
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
              Text(
                "Are you sure you want to log out? You'll need to sign in again to access your account.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
                        // Close the dialog first (use dialogContext)
                        Navigator.of(dialogContext).pop();

                        // Then sign out
                        debugPrint('start signOut: ${DateTime.now()}');
                        await _supabase.auth.signOut();
                        debugPrint('end signOut: ${DateTime.now()}');

                        // Finally navigate using the parent context (outer navigator)
                        if (mounted) {
                          Navigator.of(parentContext).pushReplacement(
                            MaterialPageRoute(
                              builder: (c) => LoginScreen(onTap: () {}),
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
      final fallback = (data['address'] ?? '').toString().trim();
      final anyMapPresent = (data['resident_address'] is Map && (data['resident_address'] as Map).isNotEmpty) ||
                           (data['work_address'] is Map && (data['work_address'] as Map).isNotEmpty) ||
                           (data['school_address'] is Map && (data['school_address'] as Map).isNotEmpty) ||
                           (data['home_address'] is Map && (data['home_address'] as Map).isNotEmpty);
      return fallback.isNotEmpty || anyMapPresent;
    }
  }

      @override
      Widget build(BuildContext context) {
        const backgroundColor = Color(0xFFF8F9FA);

        final fullName = '$_firstName $_lastName'.trim();
        final dbIsVerified = (_userDataMap != null) ? (_userDataMap!['is_verified'] ?? false) : _isVerified;
        final profileIsComplete = _isProfileCompleteForCategory(_userDataMap);
        final shouldShowVerified = profileIsComplete || dbIsVerified;
        final dobRaw = (_userDataMap != null) ? (_userDataMap!['dob'] ?? '') : '';
        final dobDisplay = (dobRaw != null && dobRaw.toString().trim().isNotEmpty) ? dobRaw.toString() : '-';

        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final headerHeight = screenHeight * 0.08;
        final sidePadding = screenWidth * 0.05;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea( // SafeArea wraps the entire content like HotlinesPage
            child: Column(
              children: [
                // Header - No SafeArea wrapper here
                Container(
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
                  child: const Row(
                    children: [
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

                // Small spacing between header and profile
                const SizedBox(height: 8),

                // Profile Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    children: [
                      // Profile Picture
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: _isLoading
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : _buildProfileImage(),
                      ),

                      const SizedBox(height: 12),

                      // Name with verification badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 160,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            )
                          else
                            Text(
                              fullName.isNotEmpty ? fullName : 'Guest User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                          if (!_isLoading && shouldShowVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Email and Birthday
                      if (_isLoading)
                        Column(
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 180,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                margin: const EdgeInsets.only(bottom: 4),
                              ),
                            ),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 120,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cake_outlined, 
                                  size: 14, 
                                  color: Colors.grey.shade500
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dobDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Options List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      children: [
                        // Profile Options Card
                        _buildOptionCard(
                          children: [
                            _buildOptionTile(
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
                            _buildDivider(),
                            _buildOptionTile(
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

                        const SizedBox(height: 12),

                        // Settings & Support Card
                        _buildOptionCard(
                          children: [
                            _buildOptionTile(
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
                            _buildDivider(),
                            _buildOptionTile(
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

                        const SizedBox(height: 12),

                        // Logout Card
                        _buildOptionCard(
                          isDestructive: true,
                          children: [
                            _buildOptionTile(
                              icon: Icons.logout_outlined,
                              title: 'Logout',
                              subtitle: 'Sign out of your account',
                              isDestructive: true,
                              onTap: _logout,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

  Widget _buildProfileImage() {
    final resolved = _resolvedPhotoURL.trim();
    final raw = _photoURL.trim();

    if (resolved.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          resolved,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildProfilePlaceholder(),
        ),
      );
    }

    if (raw.toLowerCase().startsWith('http://') || raw.toLowerCase().startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          raw,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildProfilePlaceholder(),
        ),
      );
    }

    return _buildProfilePlaceholder();
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildOptionCard({
    required List<Widget> children,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDestructive ? Colors.red.shade100 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _buildOptionTile({
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}