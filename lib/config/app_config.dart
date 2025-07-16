class AppConfig {
  // Move these to environment variables in production
  // For development, you can keep them here, but for production:
  // 1. Use flutter_dotenv package
  // 2. Create a .env file (add to .gitignore)
  // 3. Load from environment variables

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://idxfovfpreeheypueqtx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkeGZvdmZwcmVlaGV5cHVlcXR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxNDQ3ODgsImV4cCI6MjA2MjcyMDc4OH0.8FylwlyDUctFmVzneaxOmgtstWZMYJR7P0fVq1INvpw',
  );

  // App configuration
  static const String appName = 'VehiCall';
  static const String appVersion = '1.0.0';
  static const String appTagline =
      'Drive Your Way — Rent the Ride, Skip the Hassle.';

  // Validation constants
  static const int minPasswordLength = 6;
  static const int minNameLength = 3;
  static const int maxMessageLength = 500;
  static const int maxDescriptionLength = 300;
}
