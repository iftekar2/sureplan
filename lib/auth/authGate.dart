import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/forgot_password/updatePassword.dart';
import 'package:sureplan/home/homePage.dart';
import 'package:sureplan/welcome/welcomePage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build widget based on auth state
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Get the auth event and session
        final event = snapshot.data?.event;
        final session = snapshot.data?.session;

        // Check if this is a password recovery event
        if (event == AuthChangeEvent.passwordRecovery) {
          return const UpdatePassword();
        }

        // Authenticated state
        if (session != null) {
          return const HomePage();
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
