import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/auth/authGate.dart';
import 'package:sureplan/auth/googleSignInService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://rqjmnuccshboadqrgveb.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxam1udWNjc2hib2FkcXJndmViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwNDgzMTAsImV4cCI6MjA4MDYyNDMxMH0.AyJjG4GF_xzafhTI53hnjVh55Ap8qCUjsnxB2_ub6XQ",
  );

  // Initialize Google Sign-In
  await GoogleSignInService.initialize();

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthGate());
  }
}
