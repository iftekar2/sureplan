import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/events/createEventPage.dart';
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
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Get the party",
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),

              Text(
                "Started with SurePlan",
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              Text(
                "Let's make sure everyone is on the same page",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 124, 124, 124),
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(270, 70),
                  backgroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateEventPage()),
                  );
                },
                child: Text(
                  "Create an Event",
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
