import 'package:flutter/foundation.dart';
import 'package:sureplan/config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleService {
  /// Web Client ID that you registered with Google Cloud.
  static String get webClientId => AppConfig.googleWebClientId;

  /// iOS Client ID that you registered with Google Cloud.
  static String get iosClientId => AppConfig.googleIosClientId;

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
      _isInitialized = true;
    }
  }

  /// Sign up with Google
  static Future<AuthResponse> signUpWithGoogle(SupabaseClient supabase) async {
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

      // Sign in to Supabase with the Google tokens.
      // Profile creation is handled by server triggers using Google's synced metadata.
      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('Error signing up with Google: $e');
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
      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }
}
