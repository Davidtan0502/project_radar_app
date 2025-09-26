import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_radar_app/community/community_screen.dart';
import 'package:project_radar_app/screens/alerts/alert_screen.dart';
import 'package:project_radar_app/screens/home/home_screen.dart';
import 'package:project_radar_app/screens/hotlines/hotline_screen.dart';
import 'package:project_radar_app/screens/map/map_screen.dart';
import 'package:project_radar_app/screens/profile/profile_screen.dart';
import 'package:project_radar_app/screens/auth/login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  // Keep a GlobalKey<NavigatorState> per tab so we can reset individual tab navigators.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for auth state changes: if user becomes null, navigate to Login and clear stack.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        // If user signed out (or was deleted), make sure we clear everything and show login screen.
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen(onTap: () {})),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Re-tap = replace the navigator key for this tab -> forces a fresh Navigator (reload)
      setState(() {
        _navigatorKeys[index] = GlobalKey<NavigatorState>();
      });
    } else {
      // Switching to a different tab:
      // Replace the navigator key of the tab being entered so it loads fresh.
      setState(() {
        _navigatorKeys[index] = GlobalKey<NavigatorState>(); // <<-- CHANGED: reset destination tab
        _previousIndex = _currentIndex;
        _currentIndex = index;
      });
    }
  }

  Future<bool> _onWillPop() async {
    // Ask the current tab's navigator whether it can pop.
    final isFirstRouteInCurrentTab =
        !await (_navigatorKeys[_currentIndex].currentState?.maybePop() ?? Future.value(true));

    if (isFirstRouteInCurrentTab) {
      if (_currentIndex != 0) {
        setState(() {
          _previousIndex = _currentIndex;
          _currentIndex = 0;
        });
        return false;
      }
    }
    return isFirstRouteInCurrentTab;
  }

  List<Widget> _buildScreens() {
    return [
      _buildNavigator(0, const HomeScreen()),
      _buildNavigator(1, const CommunityScreen()),
      _buildNavigator(2, const AlertScreen()),
      _buildNavigator(3, const HotlinesPage()),
      _buildNavigator(4, const ProfileScreen()),
    ];
  }

  Widget _buildNavigator(int index, Widget screen) {
    // Use a direct MaterialPageRoute (no custom transitions) so there are no animations.
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: screens.asMap().entries.map((entry) {
            final isActive = entry.key == _currentIndex;
            // Use Offstage + TickerMode to show/hide without animation.
            return Offstage(
              offstage: !isActive,
              child: TickerMode(
                enabled: isActive,
                child: entry.value,
              ),
            );
          }).toList(),
        ),
        bottomNavigationBar: _BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

// ---------------- Bottom Navigation ----------------

class _BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8),
      child: SafeArea(
        child: SizedBox(
          height: kBottomNavigationBarHeight + 8,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: "Home",
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: "Community",
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _AlertButton(
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.call_outlined,
                activeIcon: Icons.call,
                label: "Hotlines",
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: "Profile",
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2E72AD) : Colors.grey[600];

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF2E72AD).withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive ? 'active_$icon' : icon),
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AlertButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2E72AD) : Colors.grey[600];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                // keep same visual: gradient when active, solid when not.
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF2E72AD), Color(0xFF4AA8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : const Color(0xFF2E72AD),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isActive ? 0.2 : 0.1),
                    blurRadius: isActive ? 8 : 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "ALERT",
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
