import 'package:flutter/material.dart';
import 'package:VehiCall/Pages/home_page.dart';
import 'package:VehiCall/Pages/registration_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Add this import at the top of the file
import 'package:flutter/foundation.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

// Access the global Supabase client
final _supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Add these variables to the _LoginPageState class
  bool _initialUriIsHandled = false;
  StreamSubscription? _streamSubscription;

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Loading state
  bool isLoading = false;

  // Error message
  String? errorMessage;

  // Sign in method using Supabase
  Future<void> signIn() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Authenticate with Supabase
        final response = await _supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        // Check if authentication was successful
        if (response.user != null) {
          // Navigate to home page on success
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          // Should not reach here normally, but just in case
          if (mounted) {
            setState(() {
              errorMessage = "Authentication failed";
              isLoading = false;
            });
          }
        }
      } on AuthException catch (error) {
        // Handle specific Supabase auth errors
        if (mounted) {
          setState(() {
            errorMessage = error.message;
            isLoading = false;
          });
        }
      } catch (error) {
        // Handle other errors
        if (mounted) {
          setState(() {
            errorMessage = "An unexpected error occurred";
            isLoading = false;
          });
        }
      }
    }
  }

  // Add this method to the _LoginPageState class
  void _checkAndShowRegistrationResult(dynamic result) {
    if (result != null && result is Map && result['success'] == true) {
      // Pre-fill email field
      emailController.text = result['email'];

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! You can now sign in.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Add this method to the _LoginPageState class
  Future<void> _initDeepLinkListener() async {
    // Handle case where app is opened from a deep link
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final initialUri = await getInitialUri();
        if (initialUri != null) {
          _handleDeepLink(initialUri);
        }
      } catch (e) {
        print('Error handling initial deep link: $e');
      }
    }

    // Handle case where app is already running and receives a deep link
    _streamSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (error) {
        print('Error handling deep link: $error');
      },
    );
  }

  // Add this method to handle the deep link
  void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');

    // Extract the access token and refresh token from the URL if present
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    final type = uri.queryParameters['type'];

    if (accessToken != null && type == 'signup') {
      // Show success message for email confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email confirmed successfully! You can now sign in.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Add this to the initState method
  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  // Add this to the dispose method
  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Image.asset(
                        'lib/images/Logo_Final.png',
                        height: 80,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Welcome text
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF123458),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Please sign in to continue',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 30),

                    // Error message if any
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email field
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF123458),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF123458),
                            width: 2,
                          ),
                        ),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF123458),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF123458),
                            width: 2,
                          ),
                        ),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Implement password reset with Supabase
                          showDialog(
                            context: context,
                            builder: (context) => ResetPasswordDialog(),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF123458),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Register option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // Navigate to registration page
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegistrationPage(),
                              ),
                            );

                            // Check if registration was successful
                            _checkAndShowRegistrationResult(result);
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: Color(0xFF123458),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Password Reset Dialog
class ResetPasswordDialog extends StatefulWidget {
  @override
  _ResetPasswordDialogState createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _supabase.auth.resetPasswordForEmail(_emailController.text.trim());

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = 'Password reset link sent to your email';
      });
    } on AuthException catch (error) {
      setState(() {
        _isLoading = false;
        _message = error.message;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _message = 'An unexpected error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reset Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email address to receive a password reset link'),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_message != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color:
                        _isSuccess
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF123458)),
          child:
              _isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text('Send Reset Link'),
        ),
      ],
    );
  }
}
