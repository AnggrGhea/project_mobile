// lib/services/auth_service.dart
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
          .eq(
            'password',
            password,
          ) // <-- Pastikan kolom ini ada di table `siswa`
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
    await prefs.setInt('id_kelas', siswa.idKelas);
    debugPrint('User logged in: ${siswa.nama}');
  }

  Future<Siswa?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final idSiswa = prefs.getInt('id_siswa');
    final nama = prefs.getString('nama');
    final nis = prefs.getString('nis');
    final username = prefs.getString('username');
    final idKelas = prefs.getInt('id_kelas');

    if (idSiswa == null ||
        nama == null ||
        nis == null ||
        username == null ||
        idKelas == null) {
      return null; // Sesi tidak tersedia
    }

    return Siswa(
      idSiswa: idSiswa,
      nama: nama,
      nis: nis,
      username: username,
      idKelas: idKelas,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('Session cleared');
  }

  Future<Siswa?> getSiswaById(int idSiswa) async {
    try {
      final response = await supabase
          .from('siswa')
          .select('*')
          .eq('id_siswa', idSiswa)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Siswa.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching siswa by ID: $e');
      return null;
    }
  }

  // Tambahkan method logout() untuk dipanggil di dashboard_screen
  Future<void> logout() async {
    await clearSession();
  }
}
