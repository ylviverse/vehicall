import 'package:flutter/material.dart';
import 'package:VehiCall/Pages/login_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF123458),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Spacer
            const Spacer(),

            // Logo
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Image.asset('lib/images/Logo_Final.png', height: 100),
            ),

            const SizedBox(height: 20),

            // App name
            const Text(
              'VehiCall',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123458),
              ),
            ),

            const SizedBox(height: 10),

            // Tagline
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Drive Your Way — Rent the Ride, Skip the Hassle.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            const Spacer(),

            // Get started button
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
