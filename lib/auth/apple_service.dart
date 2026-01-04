import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppleService {
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

      // Sign in to Supabase with the Apple tokens. Profile creation is handled by server triggers.
      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('Error signing up with Apple: $e');
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

      return await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }
}
