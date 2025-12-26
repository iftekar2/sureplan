import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleService {
  /// Web Client ID that you registered with Google Cloud.
  static String get webClientId => dotenv.env['SUPABASE_WEB_CLIENT_ID'] ?? '';

  /// iOS Client ID that you registered with Google Cloud.
  static String get iosClientId => dotenv.env['SUPABASE_IOS_CLIENT_ID'] ?? '';

  static bool _isInitialized = false;

  /// Initialize Google Sign-In
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      _isInitialized = true;
    } catch (e) {
      // If already initialized or other error
      _isInitialized = true;
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
      return false;
    }
  }

  /// Sign up with Google
  static Future<AuthResponse> signUpWithGoogle(SupabaseClient supabase) async {
    try {
      await initialize();
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
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // Sign in to Supabase with the Google tokens
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      // Save user profile to database
      if (response.user != null) {
        try {
          await supabase.from('user_profiles').upsert({
            'id': response.user!.id,
            'username': googleUser.displayName ?? 'Google User',
            'email': response.user!.email,
            'notification': true,
          });
        } catch (e) {
          print('Warning: Failed to create/update user profile: $e');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google
  static Future<AuthResponse> signInWithGoogle(SupabaseClient supabase) async {
    try {
      await initialize();
      final googleSignIn = GoogleSignIn.instance;

      // Authenticate with Google
      final googleUser = await googleSignIn.authenticate();

      // Get the ID token from authentication
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // Sign in to Supabase with the Google tokens
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      // Check if email already exists in database
      final email = response.user!.email;
      final emailExists = await checkEmailExists(supabase, email ?? '');

      if (!emailExists) {
        // Clean up Google Sign-In session
        await googleSignIn.disconnect();
        throw Exception(
          'An account with this email does not exists. '
          'Please sign up with your email first.',
        );
      }

      // Save user profile to database
      // if (response.user != null) {
      //   try {
      //     await supabase.from('user_profiles').upsert({
      //       'id': response.user!.id,
      //       'username': googleUser.displayName ?? 'Google User',
      //       'email': response.user!.email,
      //       'notification': true,
      //     });
      //   } catch (e) {
      //     print('Warning: Failed to create/update user profile: $e');
      //   }
      // }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
