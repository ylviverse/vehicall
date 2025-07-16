import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyButtonNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;
  final int selectedIndex;

  const MyButtonNavBar({
    super.key,
    required this.onTabChange,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: GNav(
        selectedIndex: selectedIndex,
        color: const Color(0xFF123458),
        activeColor: const Color.fromARGB(255, 16, 45, 77),
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: const Color.fromARGB(62, 18, 52, 88),
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        rippleColor: Colors.transparent,
        hoverColor: Colors.transparent,
        gap: 8,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        onTabChange: (value) => onTabChange!(value),
        tabs: const [
          GButton(icon: Icons.home, text: 'Dashboard'),
          GButton(icon: Icons.message, text: 'Messages'),
          GButton(icon: Icons.person, text: 'Profile'),
        ],
      ),
    );
  }
}
