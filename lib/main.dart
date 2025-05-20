import 'package:VehiCall/Pages/home_page.dart';
import 'package:VehiCall/Pages/intro_page.dart';
import 'package:VehiCall/model/fav.dart';
import 'package:VehiCall/Pages/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// These will come from your Supabase project dashboard
const String supabaseUrl = 'https://idxfovfpreeheypueqtx.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkeGZvdmZwcmVlaGV5cHVlcXR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxNDQ3ODgsImV4cCI6MjA2MjcyMDc4OH0.8FylwlyDUctFmVzneaxOmgtstWZMYJR7P0fVq1INvpw';

// Initialize a global Supabase client that can be accessed throughout the app
final supabase = Supabase.instance.client;

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authFlowType: AuthFlowType.pkce,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Fav(),
      builder:
          (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
            theme: ThemeData(
              primaryColor: const Color(0xFF123458),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF123458),
                primary: const Color(0xFF123458),
              ),
            ),
          ),
    );
  }
}

// Auth wrapper to handle authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    // Add delay to ensure proper initialization
    Future.delayed(Duration.zero, () {
      _authController.setupAuthListener(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (_authController.isLoggedIn()) {
      return const HomePage();
    } else {
      return const IntroPage();
    }
  }
}
