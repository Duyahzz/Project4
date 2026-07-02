import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/student/student_dashboard.dart';
import 'views/teacher/teacher_dashboard.dart';
import 'views/parent/parent_dashboard.dart';
import 'views/admin/admin_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const EStudiezApp(),
    ),
  );
}

class EStudiezApp extends StatelessWidget {
  const EStudiezApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eStudiez',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A2540),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A2540),
          primary: const Color(0xFF0A2540),
          secondary: const Color(0xFFED7D31),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: const CardThemeData(
          elevation: 1.5,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A2540),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthRouter(),
    );
  }
}

class AuthRouter extends StatelessWidget {
  const AuthRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Initial Splash Screen loading session
    if (auth.isLoading && !auth.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2540)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading eStudiez session...',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    // Routing Logic
    if (auth.isAuthenticated) {
      final role = auth.currentUser?.role ?? 'student';
      
      switch (role) {
        case 'admin':
          return const AdminDashboard();
        case 'teacher':
          return const TeacherDashboard();
        case 'parent':
          return const ParentDashboard();
        case 'student':
        default:
          return const StudentDashboard();
      }
    }

    // Default to Login Screen
    return const LoginScreen();
  }
}
