import 'package:flutter/material.dart';
import 'package:VehiCall/Pages/home_page.dart';
import 'package:VehiCall/Pages/registration_page.dart';
import 'package:VehiCall/utils/validators.dart';
import 'package:VehiCall/utils/error_handler.dart';
import 'package:VehiCall/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;


   Future<void> signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Just sign in. AuthWrapper will handle navigation.
        await _supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        // No navigation logic here.
        // The StreamBuilder in AuthWrapper handles it.

      } catch (error) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, error);
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void _checkAndShowRegistrationResult(dynamic result) {
    if (result != null && result is Map && result['success'] == true) {
      emailController.text = result['email'];
      ErrorHandler.showSuccessSnackBar(
        context,
        'Registration successful! You can now sign in.',
      );
    }
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
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Image.asset(
                        'lib/images/Logo_Final.png',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 20),
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ResetPasswordDialog(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegistrationPage(),
                              ),
                            );
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
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
    } catch (error) {
      setState(() {
        _isLoading = false;
        _message = ErrorHandler.getErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link',
            ),
            const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF123458),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Send Reset Link'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
