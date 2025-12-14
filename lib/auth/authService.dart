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
      // If table doesn't exist or other error, return false
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
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    // Create user profile entry in database
    if (response.user != null) {
      try {
        await _supabase.from('user_profiles').insert({
          'id': response.user!.id,
          'username': displayName,
          'email': email,
        });
      } catch (e) {
        print('Warning: Failed to create user profile: $e');
      }
    }

    return response;
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

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: 'dummy_password_check_12345',
      );
      return true;
    } catch (e) {
      // Check the error message
      final errorMessage = e.toString().toLowerCase();

      // If error contains "invalid login credentials", email exists but password is wrong
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid password')) {
        return true;
      }

      // If error contains "user not found" or similar, email doesn't exist
      if (errorMessage.contains('user not found') ||
          errorMessage.contains('email not found') ||
          errorMessage.contains('not registered')) {
        return false;
      }

      // For any other error, assume email doesn't exist
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    // First check if email exists
    final emailExists = await checkEmailExists(email);

    if (!emailExists) {
      throw Exception('No account found with this email address.');
    }

    return await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<void> updatePassword(String password) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
  }

  // Get current user
  User? get user => _supabase.auth.currentUser;
}
