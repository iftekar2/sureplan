import 'package:flutter/material.dart';
import 'package:sureplan/auth/authService.dart';
import 'package:sureplan/login/loginPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final authService = AuthService();

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

  // Forgot password button pressed
  void forgotPassword() async {
    final email = _emailController.text.trim();

    try {
      await authService.resetPassword(email);

      // Check if widget is still mounted before navigation
      if (!mounted) return;

      // Show success message with instructions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent! Check your email and click the link to reset your password.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Forgot Password?",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
            ),

            SizedBox(height: 5),

            Text(
              "Don't worry it happens. Please enter the email associated with your account.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),

            SizedBox(height: 40),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Email address",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),

            SizedBox(height: 2),

            TextFormField(
              controller: _emailController,
              validator: validateEmail,
              decoration: InputDecoration(
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

                hintText: "Enter your email address",
                hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: TextStyle(fontSize: 18),
            ),

            SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                minimumSize: Size(double.infinity, 60),
              ),
              onPressed: () {
                forgotPassword();
              },
              child: Text(
                "Send Reset Link",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
