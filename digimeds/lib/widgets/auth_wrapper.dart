// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digimeds/screens/login_screen.dart';
import 'package:digimeds/widgets/main_scaffold.dart';
import 'package:digimeds/screens/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading screen while we check the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If the user is logged in, show the main app
        if (snapshot.hasData) {
          return const MainScaffold();
        }

        // If the user is logged out, show the login screen
        return const LoginScreen();
      },
    );
  }
}
