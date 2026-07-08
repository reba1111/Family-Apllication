import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/couple_code/generate_code_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FamilyApp());
}

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family ❤️',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final initialUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<User?>(
      initialData: initialUser,
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: FutureBuilder(
                future: Future.delayed(const Duration(seconds: 4)),
                builder: (context, delaySnap) {
                  if (delaySnap.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: AppTheme.primary);
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white54, size: 50),
                      const SizedBox(height: 16),
                      const Text('ئینتەرنێت لاوازە یان پچڕاوە', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Force a rebuild to retry
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthGate()),
                          );
                        },
                        child: const Text('دووبارە هەوڵبدەرەوە'),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        if (snap.data == null) {
          return const LoginScreen();
        }

        // Use StreamBuilder instead of FutureBuilder for instant offline load from cache
        return StreamBuilder<UserModel?>(
          stream: AuthService().streamUserModel(snap.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting && !userSnap.hasData) {
              return Scaffold(
                backgroundColor: AppTheme.background,
                body: Center(
                  child: FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 4)),
                    builder: (context, delaySnap) {
                      if (delaySnap.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: AppTheme.primary);
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white54, size: 50),
                          const SizedBox(height: 16),
                          const Text('ناتوانرێت داتاکەت بهێنرێت، تکایە ئینتەرنێت پێ بکە', style: TextStyle(color: Colors.white)),
                        ],
                      );
                    },
                  ),
                ),
              );
            }
            final user = userSnap.data;
            if (user == null) return const GenerateCodeScreen();
            if (user.coupleId == null) return const GenerateCodeScreen();
            return HomeScreen(user: user);
          },
        );
      },
    );
  }
}
