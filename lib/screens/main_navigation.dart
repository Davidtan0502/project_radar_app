import 'package:flutter/material.dart';
import 'package:project_radar_app/screens/home_screen.dart';
import 'package:project_radar_app/screens/map_screen.dart';
// Import your other screen files here (once created)
// import 'package:project_radar/screens/search_screen.dart';
// import 'package:project_radar/screens/maps_screen.dart';
// import 'package:project_radar/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    Placeholder(), // SearchScreen(),
    MapScreen(), // MapsScreen(),
    Placeholder(), // ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAlertPressed() {
    // Handle alert button action here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ALERT button tapped!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home, label: "Home", index: 0),
              _navItem(icon: Icons.search, label: "Search", index: 1),
              const SizedBox(width: 48), // Space for FAB
              _navItem(icon: Icons.map, label: "Maps", index: 2),
              _navItem(icon: Icons.person, label: "Profile", index: 3),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAlertPressed,
        backgroundColor: const Color(0xFF3F73A3),
        child: const Icon(Icons.warning_amber_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.black),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
