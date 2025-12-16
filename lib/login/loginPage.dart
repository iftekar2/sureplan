import 'package:flutter/material.dart';
import 'package:sureplan/auth/authGate.dart';
import 'package:sureplan/auth/authService.dart';
import 'package:sureplan/forgot_password/forgotPasswordPage.dart';
import 'package:sureplan/home/homePage.dart';
import 'package:sureplan/signup/signupPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;

  // AuthService instance
  final AuthService authService = AuthService();

  // Email and password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Login button pressed
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Attemp to login
    try {
      await authService.signInWithEmailPassword(email, password);

      // Navigate to home page
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Parse error message for user-friendly display
      String errorMessage = e.toString().toLowerCase();
      String displayMessage;

      // Check for specific Supabase error types
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid_credentials') ||
          errorMessage.contains('invalid password')) {
        displayMessage = 'Incorrect email or password. Please try again.';
      } else if (errorMessage.contains('email not confirmed')) {
        displayMessage = 'Please verify your email before logging in.';
      } else if (errorMessage.contains('user not found') ||
          errorMessage.contains('email not found')) {
        displayMessage = 'No account found with this email. Please sign up.';
      } else if (errorMessage.contains('too many requests')) {
        displayMessage = 'Too many login attempts. Please try again later.';
      } else if (errorMessage.contains('network')) {
        displayMessage = 'Network error. Please check your connection.';
      } else {
        // Generic error message for unknown errors
        displayMessage = 'Login failed. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: NetworkImage(
                  "https://img.freepik.com/free-vector/hand-drawn-retro-cartoon-coloring-illustration_52683-159886.jpg",
                ),
                height: 300,
                width: 300,
              ),

              SizedBox(height: 20),
              Container(
                child: Column(
                  children: [
                    SizedBox(height: 10),

                    Container(
                      height: 60,
                      child: TextField(
                        controller: _emailController,
                        maxLines: null,
                        expands: true,
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

                          label: Text("Email"),

                          labelStyle: TextStyle(
                            fontSize: 20,
                            color: const Color.fromARGB(255, 119, 119, 119),
                            fontWeight: FontWeight.w500,
                          ),

                          floatingLabelStyle: TextStyle(
                            fontSize: 25,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        style: TextStyle(fontSize: 20),
                      ),
                    ),

                    SizedBox(height: 20),

                    Container(
                      height: 70,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        maxLines: 1,
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

                          label: Text("Password"),

                          labelStyle: TextStyle(
                            fontSize: 20,
                            color: const Color.fromARGB(255, 119, 119, 119),
                            fontWeight: FontWeight.w500,
                          ),

                          floatingLabelStyle: TextStyle(
                            fontSize: 25,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),

                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),

                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),

                        style: TextStyle(fontSize: 20),
                      ),
                    ),

                    SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: Size(double.infinity, 60),
                      ),

                      onPressed: () {
                        _login();
                      },
                      child: Text(
                        "Log in",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),

                    SizedBox(height: 50),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 16),
                        ),

                        SizedBox(width: 5),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
