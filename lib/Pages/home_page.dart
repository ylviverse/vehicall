import 'package:flutter/material.dart';
import 'package:VehiCall/Pages/favorites.dart';
import 'package:VehiCall/Pages/rent_page.dart';
import 'package:VehiCall/Pages/message_page.dart';
import 'package:VehiCall/Pages/profile_page.dart';
import 'package:VehiCall/Pages/auth_controller.dart';
import 'package:VehiCall/Pages/uploads_page.dart';
import 'package:VehiCall/Pages/create_post_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/buttons_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _authController = AuthController();
  final _supabase = Supabase.instance.client;

  void navigateBottonBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Add this method to the _HomePageState class
  void navigateToMessagesTab() {
    setState(() {
      _selectedIndex = 2; // Index 2 is the Messages tab
    });
  }

  final List<Widget> _pages = [
    const RentPage(),
    const FavoritePage(),
    const MessagePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Set up auth listener to handle session expiration
    Future.delayed(Duration.zero, () {
      _authController.setupAuthListener(context);
    });
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    // If post was created successfully, refresh the RentPage
    if (result == true && _selectedIndex == 0) {
      setState(() {
        // This will rebuild the RentPage
        _pages[0] = const RentPage();
      });
    }
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF123458),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await _authController.signOut(context);
      } catch (e) {
        // Handle any exceptions that might occur during sign out
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: MyButtonNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: (index) => navigateBottonBar(index),
      ),
      body: _pages[_selectedIndex],

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF123458)),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),

      // Add floating action button for creating posts only on home page (index 0)
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: _navigateToCreatePost,
                backgroundColor: const Color(0xFF123458),
                child: const Icon(
                  Icons.add_photo_alternate,
                  color: Colors.white,
                ),
              )
              : null,

      // Position the FAB on the right side
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      //drawer menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF123458)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VehiCall',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _authController.getCurrentUser()?.email ?? 'User',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('My Uploads'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadsPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.add_photo_alternate),
              title: const Text('Create Post'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreatePost();
              },
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                // Show about dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('About VehiCall'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VehiCall - Vehicle Rental App'),
                            SizedBox(height: 8),
                            Text('Version 1.0.0'),
                            SizedBox(height: 16),
                            Text(
                              '"Drive Your Way — Rent the Ride, Skip the Hassle."',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
