import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:VehiCall/Pages/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authController = AuthController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // Set email from auth
        _email = user.email ?? '';

        try {
          // Get user profile data from 'profiles' table
          final data =
              await _supabase
                  .from('profiles')
                  .select()
                  .eq('id', user.id)
                  .single();

          // Set profile data
          if (mounted) {
            setState(() {
              _fullName = data['full_name'] ?? '';
              _avatarUrl = data['avatar_url'] ?? '';
            });
          }
        } catch (profileError) {
          print('Profile not found, creating one: $profileError');

          // If profile doesn't exist, create one
          // Extract name from email if full name is not available
          String nameFromEmail = _email.split('@')[0];
          String displayName = user.userMetadata?['full_name'] ?? nameFromEmail;

          try {
            // Create a new profile
            await _supabase.from('profiles').upsert({
              'id': user.id,
              'full_name': displayName,
              'created_at': DateTime.now().toIso8601String(),
            });

            // Set the name
            if (mounted) {
              setState(() {
                _fullName = displayName;
              });
            }

            print('Profile created successfully');
          } catch (createError) {
            print('Error creating profile: $createError');
            // Still show something even if profile creation fails
            if (mounted) {
              setState(() {
                _fullName = displayName;
              });
            }
          }
        }
      }
    } catch (error) {
      // Handle error (could show a snackbar here)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Profile avatar
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              _avatarUrl.isNotEmpty
                                  ? NetworkImage(_avatarUrl)
                                  : null,
                          child:
                              _avatarUrl.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[800],
                                  )
                                  : null,
                        ),

                        const SizedBox(height: 20),

                        // User name
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF123458),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // User email
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Profile sections
                        _buildProfileSection('Personal Information', [
                          _buildProfileItem(
                            Icons.person_outline,
                            'Full Name',
                            _fullName,
                          ),
                          _buildProfileItem(
                            Icons.email_outlined,
                            'Email',
                            _email,
                          ),
                        ]),

                        const SizedBox(height: 20),

                        _buildProfileSection('App Settings', [
                          _buildSettingsItem(
                            Icons.notifications_outlined,
                            'Notifications',
                            'Manage your notifications',
                            () {},
                          ),
                          _buildSettingsItem(
                            Icons.lock_outline,
                            'Privacy',
                            'Manage your privacy settings',
                            () {},
                          ),
                          _buildSettingsItem(
                            Icons.help_outline,
                            'Help & Support',
                            'Get help with the app',
                            () {},
                          ),
                        ]),

                        const SizedBox(height: 40),

                        // Sign out button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123458),
              ),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF123458), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF123458), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
