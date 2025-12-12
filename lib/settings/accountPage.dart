import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/auth/authService.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;

  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String _username = "Loading...";
  String _email = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _getUserProfile();
  }

  Future<void> _loadNotificationPreference() async {
    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? '';

    try {
      final userProfile = await supabase
          .from('user_profiles')
          .select('notification')
          .eq('id', userId)
          .single();

      setState(() {
        _notificationsEnabled = userProfile['notification'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading notification preference: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotifications(bool newValue) async {
    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? '';

    try {
      await supabase
          .from('user_profiles')
          .update({'notification': newValue})
          .eq('id', userId);

      setState(() {
        _notificationsEnabled = newValue;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifications updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update notifications'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getUserProfile() async {
    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? '';

    try {
      final userProfile = await supabase
          .from('user_profiles')
          .select('username, email')
          .eq('id', userId)
          .single();

      final username = userProfile['username'] as String? ?? 'N/A';
      final email = userProfile['email'] as String? ?? 'N/A';

      setState(() {
        _username = username;
        _email = email;
      });
    } catch (e) {
      print("Error fetching user profile: $e");
      setState(() {
        _username = "Error";
        _email = "Error";
      });
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final currentUser = supabase.auth.currentUser;
    final userId = currentUser?.id ?? '';

    try {
      // Check if username is already taken by another user
      final existingUser = await supabase
          .from('user_profiles')
          .select('id')
          .eq('username', newUsername)
          .maybeSingle();

      if (existingUser != null && existingUser['id'] != userId) {
        throw Exception(
          'This username is already taken. Please choose another.',
        );
      }

      // Update username in database
      await supabase
          .from('user_profiles')
          .update({'username': newUsername})
          .eq('id', userId);

      // Update local state
      setState(() {
        _username = newUsername;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  void showEditUsernameDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: _username,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,

        title: Text('Edit Username'),
        content: Container(
          height: 110,
          width: double.maxFinite,
          child: Column(
            children: [
              Text(_email, style: TextStyle(color: Colors.black, fontSize: 18)),

              SizedBox(height: 20),

              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'New Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0.0,

              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(color: Colors.grey.shade400, width: 1.0),
              ),
            ),
            onPressed: () {
              final newUsername = usernameController.text.trim();
              if (newUsername.isNotEmpty && newUsername != _username) {
                updateUsername(newUsername);
                Navigator.pop(context);
              } else if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Username cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // First, verify the current password by attempting to sign in
      final email = supabase.auth.currentUser?.email ?? '';

      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // If sign-in succeeds, update to new password
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to update password';
      if (e.toString().toLowerCase().contains('invalid')) {
        errorMessage = 'Current password is incorrect';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  void showEditPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Change Password'),
        content: Container(
          height: 220,
          child: Column(
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(color: Colors.grey.shade400, width: 1.0),
              ),
            ),
            onPressed: () {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All fields are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _changePassword(currentPassword, newPassword);
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 221,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      width: 2,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.person_outline, size: 25),
                  ),
                ),

                SizedBox(width: 15),
                Text(
                  "Manage Profile",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                Spacer(),

                IconButton(
                  onPressed: showEditUsernameDialog,

                  icon: Icon(Icons.arrow_forward, size: 25),
                ),
              ],
            ),

            Divider(color: Colors.grey.shade300),

            Row(
              children: [
                Icon(Icons.lock_outline, size: 30),

                SizedBox(width: 15),
                Text(
                  "Password & Security",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                Spacer(),

                IconButton(
                  onPressed: showEditPasswordDialog,
                  icon: Icon(Icons.arrow_forward, size: 25),
                ),
              ],
            ),

            SizedBox(height: 5),

            Divider(color: Colors.grey.shade300),

            Row(
              children: [
                Icon(Icons.notifications_none, size: 30),

                SizedBox(width: 15),

                Text(
                  "Notifications",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                Spacer(),

                Switch(
                  value: _notificationsEnabled,
                  onChanged: _isLoading
                      ? null
                      : (bool newValue) {
                          _updateNotifications(newValue);
                        },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
