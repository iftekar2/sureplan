import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sureplan/main_scaffold.dart';
import 'package:sureplan/welcome/welcome_page.dart';

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
        final session = snapshot.data?.session;

        // Authenticated state
        if (session != null) {
          return const MainScaffold();
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
