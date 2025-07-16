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
    // Initialize Supabase with proper error handling
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authFlowType: AuthFlowType.pkce,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Supabase initialization timed out');
      },
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

// ...existing code...
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _recoverSession();
  }

  Future<void> _recoverSession() async {
    // This is needed to handle the initial deep link authentication flow.
    try {
      await supabase.auth.getSessionFromUrl(
        Uri.parse(Uri.base.toString()),
        storeSession: true,
      );
    } catch (e) {
      // Ignore errors, session will be null if there's no auth code in the URL
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF123458)),
            ),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const HomePage();
        } else {
          return const IntroPage();
        }
      },
    );
  }
}