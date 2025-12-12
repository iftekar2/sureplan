import 'package:flutter/material.dart';
import 'package:sureplan/auth/authService.dart';
import 'package:sureplan/login/loginPage.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final authService = AuthService();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password cannot be empty.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  void updatePasswordFunction() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    try {
      await authService.updatePassword(password);

      // Check if widget is still mounted before navigation
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Text("Update Password"),

          SizedBox(height: 20),

          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
            validator: validatePassword,
            obscureText: true,
          ),

          SizedBox(height: 20),

          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: "Confirm Password",
              border: OutlineInputBorder(),
            ),
            validator: validateConfirmPassword,
            obscureText: true,
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: updatePasswordFunction,
            child: Text("Update Password"),
          ),
        ],
      ),
    );
  }
}
