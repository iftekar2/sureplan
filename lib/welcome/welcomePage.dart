import 'package:flutter/material.dart';
import 'package:sureplan/auth/authGate.dart';
import 'package:sureplan/login/loginPage.dart';
import 'package:sureplan/signup/signupPage.dart';
import 'package:sureplan/auth/googleSignInService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final supabase = Supabase.instance.client;

  // Google Sign In pressed
  void signupWithGoogle() async {
    try {
      await GoogleSignInService.signInWithGoogle(supabase);

      // Check if widget is still mounted before navigation
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1485178075098-49f78b4b43b4?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGV2ZW50JTIwd2FsbHBhcGVyfGVufDB8fDB8fHww",
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 2),
              Column(
                children: [
                  Text(
                    "Plan Smart, Not Hard",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20),

                  SizedBox(
                    height: 100,
                    width: 350,
                    child: Center(
                      child: Text(
                        "Confirm the perfect timing, easily check attendance, and never waste a hang-out again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(child: Container()),

              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupPage(),
                                  ),
                                );
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: Size(300, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Create an Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(height: 10),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "I already have an account",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(height: 10),
                            Divider(thickness: 0.3, color: Colors.black),
                            SizedBox(height: 10),

                            Text(
                              "Sign up with",
                              style: TextStyle(
                                fontSize: 18,
                                color: const Color.fromARGB(255, 99, 99, 99),
                              ),
                            ),

                            SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: signupWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                              ),
                              child: SizedBox(
                                height: 60,
                                width: 60,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        196,
                                        196,
                                        196,
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    "lib/welcome/google-logo.png",
                                    height: 40,
                                    width: 40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
