import 'package:flutter/material.dart';
import 'package:sureplan/auth/auth_service.dart';
import 'package:sureplan/auth/google_service.dart';
import 'package:sureplan/auth/apple_service.dart';
import 'package:sureplan/forgot_password/forgot_password_page.dart';
import 'package:sureplan/home/home_page.dart';
import 'package:sureplan/main.dart';
import 'package:sureplan/main_scaffold.dart';
import 'package:sureplan/signup/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;
  bool _isLoading = false;

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
          MaterialPageRoute(builder: (context) => const MainScaffold()),
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

  // Apple Sign-In button pressed
  void _loginWithApple() async {
    setState(() => _isLoading = true);
    try {
      await AppleService.signInWithApple(supabase);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScaffold()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Apple Sign-in failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

        title: Text(
          "Login",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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

                    SizedBox(
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

                    SizedBox(height: 15),

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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 18),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // SizedBox(height: 30),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Expanded(
                    //       child: Divider(
                    //         color: Colors.grey,
                    //         height: 20,
                    //         thickness: 2,
                    //         indent: 16,
                    //         endIndent: 16,
                    //       ),
                    //     ),

                    //     Text(
                    //       "Or",
                    //       style: TextStyle(
                    //         color: Colors.grey[500],
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),

                    //     Expanded(
                    //       child: Divider(
                    //         color: Colors.grey,
                    //         height: 20,
                    //         thickness: 2,
                    //         indent: 16,
                    //         endIndent: 16,
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    // SizedBox(height: 20),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     SizedBox(
                    //       height: 70,
                    //       child: ElevatedButton(
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Colors.white,
                    //           elevation: 0,
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(10),
                    //             side: BorderSide(color: Colors.grey, width: 1),
                    //           ),
                    //         ),
                    //         onPressed: _loginWithApple,
                    //         child: Row(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Image.network(
                    //               "https://img.icons8.com/?size=100&id=30840&format=png&color=000000",
                    //               height: 40,
                    //               width: 40,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),

                    //     SizedBox(width: 20),

                    //     SizedBox(
                    //       height: 70,
                    //       child: ElevatedButton(
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Colors.white,
                    //           elevation: 0,
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(10),
                    //             side: BorderSide(color: Colors.grey, width: 1),
                    //           ),
                    //         ),

                    //         onPressed: () async {
                    //           setState(() => _isLoading = true);
                    //           try {
                    //             await GoogleService.signInWithGoogle(supabase);

                    //             if (mounted) {
                    //               Navigator.pushAndRemoveUntil(
                    //                 context,
                    //                 MaterialPageRoute(
                    //                   builder: (context) => const HomePage(),
                    //                 ),
                    //                 (route) => false,
                    //               );
                    //             }
                    //           } catch (e) {
                    //             if (mounted) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 SnackBar(
                    //                   content: Text(
                    //                     'Google Sign-in failed: $e',
                    //                   ),
                    //                   backgroundColor: Colors.red,
                    //                 ),
                    //               );
                    //             }
                    //           } finally {
                    //             if (mounted) {
                    //               setState(() => _isLoading = false);
                    //             }
                    //           }
                    //         },

                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Image.asset(
                    //               "lib/login/google-logo.png",
                    //               height: 40,
                    //               width: 40,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
