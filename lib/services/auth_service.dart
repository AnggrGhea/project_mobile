import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/siswa.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<Siswa?> login(String username, String password) async {
    try {
      final response = await supabase
          .from('siswa')
          .select('*')
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        return null; // Login gagal
      }

      final siswa = Siswa.fromJson(response);
      await saveSession(siswa); // Simpan sesi
      return siswa;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<void> saveSession(Siswa siswa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id_siswa', siswa.idSiswa);
    await prefs.setString('nama', siswa.nama);
    await prefs.setString('nis', siswa.nis);
    await prefs.setString('username', siswa.username);
    await prefs.setString(
      'password',
      siswa.password,
    ); // ⚠️ Hati-hati, password harus dihash!
    debugPrint('User logged in: ${siswa.nama}');
  }

  Future<Siswa?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final idSiswa = prefs.getInt('id_siswa');
    final nama = prefs.getString('nama');
    final nis = prefs.getString('nis');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (idSiswa == null ||
        nama == null ||
        nis == null ||
        username == null ||
        password == null) {
      return null; // Sesi tidak tersedia
    }

    return Siswa(
      idSiswa: idSiswa,
      nama: nama,
      nis: nis,
      username: username,
      password: password,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('Session cleared');
  }
}
