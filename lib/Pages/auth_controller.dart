import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:VehiCall/Pages/intro_page.dart';
import 'package:VehiCall/Pages/home_page.dart';

// Access the global Supabase client
final supabase = Supabase.instance.client;

class AuthController {
  // Singleton pattern
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  // Check if user is logged in
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // Get current user
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Sign out
  Future<void> signOut(BuildContext context) async {
    try {
      // First navigate to intro page and clear navigation stack
      // This ensures we navigate before potentially losing context
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const IntroPage()),
        (route) => false,
      );

      // Then sign out from Supabase after navigation is complete
      await supabase.auth.signOut();

      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
      // If there was an error but we're still in a valid context, show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Listen to auth state changes
  Stream<AuthState> authStateChanges() {
    return supabase.auth.onAuthStateChange;
  }

  // Handle session expiration
  void setupAuthListener(BuildContext context) {
    print('Setting up auth listener');
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('Auth event: $event');
      if (session != null) {
        print('Session user ID: ${session.user.id}');
      }

      // If user signs out or session expires
      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        print('User signed out or deleted');
        // Only navigate if context is still valid
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const IntroPage()),
            (route) => false,
          );
        }
      }
    });
  }

  // Direct user to appropriate screen based on auth state
  void redirectBasedOnAuthState(BuildContext context) {
    if (isLoggedIn()) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const IntroPage()),
        (route) => false,
      );
    }
  }

  // Add this method to the AuthController class
  void printAuthStatus() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      print('User is logged in:');
      print('User ID: ${user.id}');
      print('User Email: ${user.email}');
      print('User Metadata: ${user.userMetadata}');
    } else {
      print('No user is currently logged in');
    }
  }
}
