import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleSignInService {
  /// Web Client ID that you registered with Google Cloud.
  static const webClientId =
      '578638753254-t1s5rnssdrmv4b7rg8bo23c3d6hcerl5.apps.googleusercontent.com';

  /// iOS Client ID that you registered with Google Cloud.
  static const iosClientId =
      '578638753254-e7a5p8oi67hn6ul5gsiipng7o8drgd52.apps.googleusercontent.com';

  static bool _isInitialized = false;

  /// Initialize Google Sign-In
  /// This should be called once when the app starts
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      _isInitialized = true;
    } catch (e) {
      throw 'Failed to initialize Google Sign-In: $e';
    }
  }

  /// Check if email already exists in user_profiles table
  static Future<bool> checkEmailExists(
    SupabaseClient supabase,
    String email,
  ) async {
    try {
      final response = await supabase
          .from('user_profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // If there's an error checking, assume email doesn't exist
      // This prevents blocking legitimate signups due to database errors
      return false;
    }
  }

  /// Sign in with Google
  static Future<AuthResponse> signInWithGoogle(SupabaseClient supabase) async {
    // Ensure Google Sign-In is initialized
    if (!_isInitialized) {
      await initialize();
    }

    final googleSignIn = GoogleSignIn.instance;

    // Authenticate with Google
    final googleUser = await googleSignIn.authenticate();

    // Check if email already exists in database
    final googleEmail = googleUser.email;
    final emailExists = await checkEmailExists(supabase, googleEmail);

    if (emailExists) {
      // Clean up Google Sign-In session
      await googleSignIn.disconnect();
      throw Exception(
        'An account with this email already exists. '
        'Please log in with your email and password instead.',
      );
    }

    // Get the ID token from authentication
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    // Get the access token from authorization client
    final authorization = await googleUser.authorizationClient.authorizeScopes(
      [],
    );
    final accessToken = authorization.accessToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    // Sign in to Supabase with the Google tokens
    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // Save user profile to database
    if (response.user != null) {
      try {
        // Use upsert to handle both new and existing users
        await supabase.from('user_profiles').upsert({
          'id': response.user!.id,
          'username': googleUser.displayName ?? 'Google User',
          'email': response.user!.email,
          'notification': true,
        });
      } catch (e) {
        // Log error but don't fail the authentication
        // User is still authenticated even if profile creation fails
        print('Warning: Failed to create/update user profile: $e');
      }
    }

    return response;
  }
}
