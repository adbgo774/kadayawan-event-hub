// ANGELIQUE DAWN B. GO

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ovdqxebojmanmzykwmsw.supabase.co',
    anonKey: 'sb_publishable_Dc70ds4ffgsmfdz90l82yA_Dux00t1M',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kadayawan Event Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F00),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session != null) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}