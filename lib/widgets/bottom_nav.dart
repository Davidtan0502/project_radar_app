import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: Colors.white,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home, label: "Home", index: 0),
            _navItem(icon: Icons.map, label: "Maps", index: 1),
            const SizedBox(width: 48), // space for FAB
            _navItem(icon: Icons.call, label: "Hotline", index: 2),
            _navItem(icon: Icons.person, label: "Profile", index: 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.black),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue : Colors.black),
          ),
        ],
      ),
    );
  }
}
