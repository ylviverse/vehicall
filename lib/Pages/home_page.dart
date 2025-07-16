import 'package:flutter/material.dart';
import 'package:VehiCall/Pages/rent_page.dart';
import 'package:VehiCall/Pages/message_page.dart';
import 'package:VehiCall/Pages/profile_page.dart';

import 'package:VehiCall/Pages/create_post_page.dart';
import 'package:VehiCall/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/buttons_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void navigateBottonBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Create pages lazily to avoid initialization issues
  Widget _getPage(int index) {
  

    switch (index) {
      case 0:
        return const RentPage();
      case 1:
        return const MessagePage();
      case 2:
        return const ProfilePage();
      default:
        return const RentPage();
    }
  }

  @override
  void initState() {
    super.initState();
  }



  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result == true && _selectedIndex == 0) {
      // Refresh the rent page by rebuilding it
      setState(() {});
    }
  }

  Future<void> _signOut() async {
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
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
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
      body: _getPage(_selectedIndex),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                    AppConfig.appName,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                     Supabase.instance.client.auth.currentUser?.email ?? 'User',
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
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
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
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('About ${AppConfig.appName}'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${AppConfig.appName} - Vehicle Rental App'),
                            const SizedBox(height: 8),
                            Text('Version ${AppConfig.appVersion}'),
                            const SizedBox(height: 16),
                            Text(
                              '"${AppConfig.appTagline}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
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
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
