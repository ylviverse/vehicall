import 'package:VehiCall/Pages/home_page.dart';
import 'package:VehiCall/Pages/intro_page.dart';
import 'package:VehiCall/config/app_config.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:VehiCall/error_boundary.dart';


final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter framework errors gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    // In debug mode, print the error
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    // In release mode, you might want to log to a crash reporting service
  };

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
     
    );

    print('Supabase initialized successfully');

    runApp(const MyApp());
  } catch (e) {
    print('Fatal error during app initialization: $e');
    // Run a minimal error app instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to start application',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode ? e.toString() : 'Please restart the app',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        home: const AuthWrapper(),
        theme: ThemeData(
          primaryColor: const Color(0xFF123458),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF123458),
            primary: const Color(0xFF123458),
          ),
        ),
        builder: (context, child) {
          // Handle keyboard focus issues
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Prevent text scaling issues
            ),
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    if (_isInitializing) return; // Prevent multiple calls
    
    setState(() {
      _isInitializing = true;
    });

    print("AuthWrapper: Initializing auth...");
    try {
      // Only attempt URL recovery if we're on web and there's actually a URL fragment
      if (kIsWeb && Uri.base.fragment.isNotEmpty) {
        print("AuthWrapper: Attempting to recover session from URL...");
        await supabase.auth.getSessionFromUrl(
          Uri.parse(Uri.base.toString()),
          storeSession: true,
        );
        print("AuthWrapper: Session recovery from URL completed.");
      }
    } catch (e) {
      print("AuthWrapper: Error recovering session from URL: $e");
    }
    
    setState(() {
      _isInitialized = true;
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("AuthWrapper: Build method started.");
    
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF123458)),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print("AuthWrapper: StreamBuilder running. State: ${snapshot.connectionState}");
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF123458)),
            ),
          );
        }

        final session = supabase.auth.currentSession; // Use currentSession instead of snapshot.data
        print("AuthWrapper: Current session is ${session == null ? 'null' : 'active'}.");

        if (session != null) {
          print("AuthWrapper: User is authenticated, showing HomePage");
          return const HomePage();
        } else {
          print("AuthWrapper: User is not authenticated, showing IntroPage");
          return const IntroPage();
        }
      },
    );
  }
}