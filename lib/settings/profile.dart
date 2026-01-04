import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/auth/auth_service.dart';
import 'package:sureplan/settings/account_page.dart';
import 'package:sureplan/welcome/welcome_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final authService = AuthService();
  String _username = "Loading...";
  String _email = "Loading...";

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  Future<void> getUserProfile() async {
    try {
      final userProfile = await authService.getCurrentUserProfile();

      if (userProfile != null) {
        setState(() {
          _username = userProfile['username'] as String? ?? 'N/A';
          _email = userProfile['email'] as String? ?? 'N/A';
        });
      } else {
        setState(() {
          _username = "Guest";
          _email = "Not logged in";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user profile in UI: $e");
      setState(() {
        _username = "Error";
        _email = "Error";
      });
    }
  }

  Future<void> _logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomePage()),

      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.w600)),
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

      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Padding(
                padding: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color.fromARGB(255, 197, 197, 197),
                        ),
                      ),
                      child: Icon(Icons.person, size: 50),
                    ),

                    SizedBox(width: 15),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              _username,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 91, 91, 91),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Account", style: TextStyle(fontSize: 16)),
            ),

            SizedBox(height: 5),

            AccountPage(),

            Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(
                      color: const Color.fromARGB(255, 192, 192, 192),
                      width: 1,
                    ),
                  ),
                ),
                onPressed: () {
                  _logout();
                },
                child: Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
