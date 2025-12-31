import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppleService {
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

  /// Sign up with Apple
  static Future<AuthResponse> signUpWithApple(SupabaseClient supabase) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception('No Identity Token found.');
      }

      // Check if email already exists in database
      final appleEmail = appleCredential.email;
      if (appleEmail != null) {
        final emailExists = await checkEmailExists(supabase, appleEmail);
        if (emailExists) {
          throw Exception(
            'An account with this email already exists. '
            'Please log in with your email and password instead.',
          );
        }
      }

      // Sign in to Supabase with the Apple tokens
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      // Save user profile to database
      if (response.user != null) {
        String displayName = 'Apple User';
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          displayName =
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim();
        }

        try {
          await supabase.from('user_profiles').upsert({
            'id': response.user!.id,
            'username': displayName,
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

  /// Sign in with Apple
  static Future<AuthResponse> signInWithApple(SupabaseClient supabase) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception('No Identity Token found.');
      }

      // Sign in to Supabase with the Apple tokens
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      // Check if email already exists in database
      final email = response.user!.email;
      final emailExists = await checkEmailExists(supabase, email ?? '');

      if (!emailExists) {
        throw Exception(
          'An account with this email does not exists. '
          'Please sign up with your email first.',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
