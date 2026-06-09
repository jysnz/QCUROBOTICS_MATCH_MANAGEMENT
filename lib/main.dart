import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qcurobotics_match_management/Pages/Auth/login_page.dart';
import 'package:qcurobotics_match_management/Pages/Dashboard/dashboard_page.dart';
import 'package:qcurobotics_match_management/Widgets/design_system.dart';

import 'Pages/Auth/register_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QCU Robotics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasProfile = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    bool hasProfile = false;
    User? user = session?.user;

    if (session != null) {
      final profile = await Supabase.instance.client
          .from('user_accounts')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();
      hasProfile = profile != null;
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = session != null;
        _hasProfile = hasProfile;
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }

    if (!_isAuthenticated) {
      return const LoginPage();
    }

    if (!_hasProfile && _user != null) {
      // If authenticated but no profile, show RegisterPage
      return RegisterPage(
        isGoogleSignUp: true, // Treat as profile completion
        initialEmail: _user!.email,
        initialName: _user!.userMetadata?['full_name'],
        initialImageUrl: _user!.userMetadata?['avatar_url'],
        onProfileComplete: () => setState(() => _hasProfile = true),
      );
    }

    return const DashboardPage();
  }
}
