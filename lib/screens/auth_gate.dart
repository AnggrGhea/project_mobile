// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:project_mobile/models/siswa.dart';
import 'package:project_mobile/screens/dashboard_screen.dart';
import 'package:project_mobile/screens/login_screen.dart';
import 'package:project_mobile/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  // Fungsi ini akan mengecek login DAN mengambil profil
  Future<Siswa?> _checkSessionAndGetProfile() async {
    // 1. Cek apakah ada user login di Supabase
    final User? supabaseUser = _authService.getCurrentUser();

    if (supabaseUser == null) {
      // Jika tidak ada, kembalikan null
      return null;
    }

    // 2. Jika ada, ambil profil 'Siswa' dari tabel 'siswa'
    final Siswa? siswaProfile = await _authService.getSiswaProfile();
    return siswaProfile;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Siswa?>(
      future: _checkSessionAndGetProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan loading spinner selagi mengecek
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Jika data 'Siswa' ada, pergi ke Dashboard
          return DashboardScreen(siswa: snapshot.data!);
        } else {
          // Jika tidak ada (null), pergi ke Login
          return const LoginScreen();
        }
      },
    );
  }
}
