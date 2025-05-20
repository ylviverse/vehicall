import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// class MyButtonNavBar extends StatelessWidget {
//   final void Function(int)? onTabChange;
//   MyButtonNavBar({super.key, required this.onTabChange});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 15),

//       child: GNav(
//         color: Color(0xFF123458),
//         activeColor: Color.fromARGB(255, 16, 45, 77),
//         tabActiveBorder: Border.all(color: Colors.white),
//         tabBackgroundColor: Color.fromARGB(62, 18, 52, 88),

//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         rippleColor: Colors.transparent,
//         hoverColor: Colors.transparent,
//         gap: 8,

//         padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//         onTabChange: (value) => onTabChange!(value),
//         tabs: [
//           GButton(icon: Icons.home, text: 'Home'),
//           GButton(icon: Icons.favorite, text: 'Favorites'),
//           GButton(icon: Icons.message, text: 'Message'),
//           GButton(icon: Icons.person, text: 'Profile'),
//         ],
//       ),
//     );
//   }
// }
class MyButtonNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;
  final int selectedIndex;

  MyButtonNavBar({
    super.key,
    required this.onTabChange,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: GNav(
        selectedIndex: selectedIndex, // ← Add this
        color: Color(0xFF123458),
        activeColor: Color.fromARGB(255, 16, 45, 77),
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Color.fromARGB(62, 18, 52, 88),
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        rippleColor: Colors.transparent,
        hoverColor: Colors.transparent,
        gap: 8,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        onTabChange: (value) => onTabChange!(value),
        tabs: [
          GButton(icon: Icons.home, text: 'Dashboard'),
          GButton(icon: Icons.favorite, text: 'Favorites'),
          GButton(icon: Icons.message, text: 'Message'),
          GButton(icon: Icons.person, text: 'Profile'),
        ],
      ),
    );
  }
}
