import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/alerts/alert_screen.dart';
import 'package:project_radar_app/screens/home/home_screen.dart';
import 'package:project_radar_app/screens/profile/hotline_screen.dart';
import 'package:project_radar_app/screens/map/map_screen.dart';
import 'package:project_radar_app/screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
      });
    }
  }

  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_currentIndex].currentState!.maybePop();
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
      _buildNavigator(1, const MapScreen()),
      _buildNavigator(2, const AlertScreen()),
      _buildNavigator(3, const HotlinesPage()),
      _buildNavigator(4, const ProfileScreen()),
    ];
  }

  Widget _buildNavigator(int index, Widget screen) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final curve = Curves.easeOut;
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          final beginOffset = index > _previousIndex 
              ? const Offset(1.0, 0.0) 
              : const Offset(-1.0, 0.0);

          return SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.5,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true, // Important for removing white space
        body: Stack(
          children: _buildScreens().asMap().entries.map((entry) {
            return IgnorePointer(
              ignoring: entry.key != _currentIndex,
              child: AnimatedOpacity(
                opacity: entry.key == _currentIndex ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
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
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: "Maps",
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive ? 'active_$icon' : icon),
                  color: color,
                  size: 24,
                ),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
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