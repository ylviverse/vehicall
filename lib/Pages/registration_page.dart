import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Access the global Supabase client
final _supabase = Supabase.instance.client;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Text controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Loading state
  bool isLoading = false;

  // Error message
  String? errorMessage;

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Register method using Supabase
  Future<void> register() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Sign up with Supabase auth
        final AuthResponse res = await _supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {'full_name': fullNameController.text},
          emailRedirectTo: 'io.flutter.vehicall://login-callback',
        );

        // If sign up is successful, store additional user data in a Supabase table
        if (res.user != null) {
          try {
            // Store additional user data in the profiles table
            final profileData = {
              'id': res.user!.id,
              'full_name': fullNameController.text,
              'created_at': DateTime.now().toIso8601String(),
            };

            // Insert profile data and handle any errors
            final profileResponse =
                await _supabase.from('profiles').upsert(profileData).select();

            print('Profile created successfully: $profileResponse');

            // Return to login page with success message
            if (mounted) {
              Navigator.pop(context, {
                'success': true,
                'email': emailController.text,
              });
            }
          } catch (profileError) {
            print('Error creating profile: $profileError');

            // Even if profile creation fails, the user is still created
            // We can still return success but log the error
            if (mounted) {
              // Show a warning about profile creation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account created, but profile setup had an issue. This will be fixed automatically when you sign in.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );

              Navigator.pop(context, {
                'success': true,
                'email': emailController.text,
              });
            }
          }
        } else {
          // Should not normally reach here, but just in case
          if (mounted) {
            setState(() {
              errorMessage = "Registration failed. Please try again.";
              isLoading = false;
            });
          }
        }
      } on AuthException catch (error) {
        // Handle specific Supabase auth errors
        print('Auth error: ${error.message}');
        if (mounted) {
          setState(() {
            errorMessage = error.message;
            isLoading = false;
          });
        }
      } catch (error) {
        // Handle other errors
        print('Unexpected error: $error');
        if (mounted) {
          setState(() {
            errorMessage = "An unexpected error occurred: $error";
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF123458)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF123458),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Image.asset(
                        'lib/images/Logo_Final.png',
                        height: 70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Welcome text
                  const Center(
                    child: Text(
                      'Join VehiCall',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF123458),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      'Create an account to start renting vehicles',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
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

                  // Full Name field
                  TextFormField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(
                        Icons.person,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
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
                      // Simple email validation
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Create a password',
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF123458),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF123458),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
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
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      // Check for at least one uppercase letter
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      // Check for at least one number
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Password must contain at least one number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password field
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF123458),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF123458),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
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
                        return 'Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Terms and conditions checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: true,
                        onChanged: (value) {},
                        activeColor: const Color(0xFF123458),
                      ),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Color(0xFF123458),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF123458),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login option
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF123458),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
