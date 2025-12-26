import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Self-healing: Ensure profile exists
    if (response.user != null) {
      await _ensureProfileExists(response.user!);
    }

    return response;
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
          'notification': true,
        });
      } catch (e) {
        // This may fail if email confirmation is required (RLS prevents insert without session)
        // Profile will be created in verifySignupOTP after user is authenticated
        print('Note: Initial profile creation skipped or failed: $e');
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
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );

    // After successful verification, the user is signed in.
    // Ensure the user profile exists.
    if (response.user != null) {
      await _ensureProfileExists(response.user!);
    }

    return response;
  }

  // Ensure profile exists in database
  Future<void> _ensureProfileExists(User user) async {
    try {
      final userId = user.id;
      final displayName = user.userMetadata?['display_name'] as String?;
      final email = user.email;

      // Check if profile exists
      final profile = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile == null && displayName != null && email != null) {
        await _supabase.from('user_profiles').insert({
          'id': userId,
          'username': displayName,
          'email': email,
          'notification': true,
        });
        print('Profile created for user: $userId');
      }
    } catch (e) {
      print('Error ensuring user profile exists: $e');
    }
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

  // Get current user profile with self-healing
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Ensure profile exists
      await _ensureProfileExists(user);

      // Fetch profile
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching current user profile: $e');
      return null;
    }
  }
}
