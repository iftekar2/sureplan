import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String displayName,
    String password,
  ) async {
    // First check if username is already taken
    final usernameExists = await checkUsernameExists(displayName);
    if (usernameExists) {
      throw Exception('This username is already taken. Please choose another.');
    }

    // Sign up the user
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  // Sign out
  Future<void> signOut() async {
    return await _supabase.auth.signOut();
  }

  // Get user email
  String? getUserEmail() {
    final user = _supabase.auth.currentUser;
    return user?.email;
  }

  // Get user display name
  String? getUserDisplayName() {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['display_name'] as String?;
  }

  // Check if email exists (Standardized to avoid explicit enumeration where possible)
  Future<bool> checkEmailExists(String email) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: 'dummy_password_check_active_security_policy',
      );
      return true;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      // Only return true if we are certain the account exists
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid password')) {
        return true;
      }
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    return await _supabase.auth.resetPasswordForEmail(email);
  }

  // Verify OTP for password recovery
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  // Verify OTP for signup
  Future<AuthResponse> verifySignupOTP({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  // Resend OTP
  Future<void> resendOTP({required String email}) async {
    await _supabase.auth.resend(email: email, type: OtpType.signup);
  }

  // Update password
  Future<void> updatePassword(String password) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
  }

  // Get current user
  User? get user => _supabase.auth.currentUser;

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      return null;
    }
  }
}
