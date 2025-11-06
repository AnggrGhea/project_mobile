import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'models/siswa.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://doldvhllfmxnpababugw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvbGR2aGxsZm14bnBhYmFidWd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMDQzMzEsImV4cCI6MjA3NDc4MDMzMX0.FjW1uShBHSD99KN97Jos0yWnGOeV4Ed_VcyEQgCzfWk',
  );

  final authService = AuthService();
  final siswa = await authService.getSession();

  runApp(MyApp(siswa: siswa));
}

class MyApp extends StatelessWidget {
  final Siswa? siswa;

  const MyApp({super.key, this.siswa});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: siswa != null
          ? DashboardScreen(siswa: siswa!)
          : const LoginScreen(),
    );
  }
}
