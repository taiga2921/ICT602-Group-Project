import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/user/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Record System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // User is logged in - check if admin or regular user
        return FutureBuilder<bool>(
          future: _authService.isUserAdmin(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final isAdmin = adminSnapshot.data ?? false;

            // Navigate based on user role
            if (isAdmin) {
              return const AdminDashboard();
            } else {
              return const UserDashboard();
            }
          },
        );
      },
    );
  }
}
