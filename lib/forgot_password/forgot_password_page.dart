import 'package:flutter/material.dart';
import 'package:sureplan/auth/auth_service.dart';
import 'package:sureplan/login/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final authService = AuthService();
  bool _isResetMode = false;
  bool _passwordVisible = false;

  final emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty.';
    }
    if (!emailRegex.hasMatch(value)) {
      return 'Email is not valid.';
    }
    return null;
  }

  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Verify Token and Reset Password
  void verifyAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation
    if (token.isEmpty || token.length < 6) {
      _showError("Invalid token format.");
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError("Password must be at least 6 characters.");
      return;
    }

    try {
      // 1. Verify OTP
      await authService.verifyOTP(email: email, token: token);

      // 2. Update Password
      await authService.updatePassword(password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password successfully updated! Please login.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _showError(dynamic e) {
    String errorMessage = e.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring('Exception: '.length);
    }
    // Clean Supabase errors
    if (errorMessage.contains("Token has expired") ||
        errorMessage.contains("Invalid token")) {
      errorMessage = "Invalid or expired token.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isResetMode ? "Reset Password" : "Forgot Password?",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  _isResetMode
                      ? "Enter the code sent to your email and your new password."
                      : "Don't worry it happens. Please enter the email associated with your account.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 40),

                // Email Field (Always visible)
                Text(
                  "Email address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                TextFormField(
                  controller: _emailController,
                  validator: validateEmail,
                  decoration: _inputDecoration("Enter your email address"),
                  style: TextStyle(fontSize: 18),
                ),

                // Extra fields for Reset Mode
                if (_isResetMode) ...[
                  SizedBox(height: 20),
                  Text(
                    "Reset Token",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _tokenController,
                    decoration: _inputDecoration("Enter 6-digit token"),
                    style: TextStyle(fontSize: 18),
                    validator: (val) =>
                        val != null && val.isEmpty ? "Token required" : null,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "New Password",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: _inputDecoration("Enter new password").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(fontSize: 18),
                    validator: (val) => val != null && val.length < 6
                        ? "Min 6 characters"
                        : null,
                  ),
                ],

                SizedBox(height: 20),

                // Toggle Mode Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isResetMode = !_isResetMode;
                        _tokenController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(
                      _isResetMode
                          ? "I need a token"
                          : "I already have a token",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 169, 169, 169),
          width: 2.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 169, 169, 169),
          width: 2.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 169, 169, 169),
          width: 2.0,
        ),
      ),
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.grey,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
