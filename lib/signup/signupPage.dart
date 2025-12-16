import 'package:flutter/material.dart';
import 'package:sureplan/auth/authGate.dart';
import 'package:sureplan/auth/authService.dart';
import 'package:sureplan/auth/googleSignInService.dart';
import 'package:sureplan/login/loginPage.dart';
import 'package:sureplan/main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

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

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username cannot be empty.';
    }
    return null;
  }

  final passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must contain at least one number and one letter.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password cannot be empty.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // AuthService instance
  final authService = AuthService();

  // Email and password controllers
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Signup button pressed
  void signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _usernameController.text.trim();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await authService.signUpWithEmailPassword(email, displayName, password);

      // Check if widget is still mounted before navigation
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      // Extract clean error message
      String errorMessage = e.toString();

      if (errorMessage.contains("user_already_exists")) {
        errorMessage = "User already exists. Please login.";
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }

      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  // Google Sign-In button pressed
  void signupWithGoogle() async {
    try {
      await GoogleSignInService.signInWithGoogle(supabase);

      // Check if widget is still mounted before navigation
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
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
              colors: [
                Color.fromARGB(246, 255, 255, 250),
                Color.fromARGB(246, 255, 255, 250),
              ],
            ),
          ),
        ),
      ),

      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image(
                image: NetworkImage(
                  "https://img.freepik.com/free-vector/retro-cartoon-coloring-illustration_23-2151296685.jpg",
                ),
                height: 210,
                width: 210,
              ),

              //SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      maxLines: null,
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

                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),

                        errorStyle: TextStyle(fontSize: 14, height: 1.5),
                      ),

                      style: TextStyle(fontSize: 20),
                    ),

                    SizedBox(height: 15),

                    TextFormField(
                      controller: _usernameController,
                      validator: validateUsername,
                      maxLines: null,
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

                        label: Text("Username"),

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

                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),

                        errorStyle: TextStyle(fontSize: 14, height: 1.5),
                      ),

                      style: TextStyle(fontSize: 20),
                    ),

                    SizedBox(height: 15),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      maxLines: 1,
                      validator: validatePassword,
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

                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
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

                        errorStyle: TextStyle(fontSize: 14, height: 1.5),
                      ),

                      style: TextStyle(fontSize: 18),
                    ),

                    SizedBox(height: 15),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      maxLines: 1,
                      validator: validateConfirmPassword,
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

                        label: Text("Confirm Password"),

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

                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),

                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            });
                          },
                        ),

                        errorStyle: TextStyle(fontSize: 14, height: 1.5),
                      ),

                      style: TextStyle(fontSize: 18),
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

                      onPressed: signup,
                      child: Text(
                        "Sign up",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),

                    SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Or",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),

                        Expanded(
                          child: Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: const Color.fromARGB(255, 177, 177, 177),
                          ),
                        ),

                        minimumSize: Size(double.infinity, 55),
                      ),

                      onPressed: signupWithGoogle,

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "lib/welcome/google-logo.png",
                            height: 30,
                            width: 30,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Sign up with Google",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(fontSize: 16),
                        ),

                        SizedBox(width: 5),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Log in",
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
