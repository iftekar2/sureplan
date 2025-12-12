import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/settings/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final currentEmail = currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("SuperPlan", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color.fromARGB(255, 156, 156, 156),
                ),
              ),

              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(Icons.person, color: Colors.black, size: 40),
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        // Fetch user profile from database using user ID
        future: supabase
            .from('user_profiles')
            .select()
            .eq('id', currentUser?.id ?? '')
            .single(),
        builder: (context, snapshot) {
          // While loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // If error occurred
          if (snapshot.hasError) {
            return Column(
              children: [
                Text("Home Page"),
                SizedBox(height: 20),
                Text(
                  "Welcome, ${currentEmail ?? 'User'}!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }

          // Get username from database
          final username = snapshot.data?['username'] as String?;

          return Column(
            children: [
              Text("Home Page"),
              SizedBox(height: 20),
              Text(
                "Welcome, ${username ?? currentEmail ?? 'User'}!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }
}
