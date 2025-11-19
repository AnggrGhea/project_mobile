import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/siswa.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Siswa? _siswa;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final idSiswa = prefs.getInt('id_siswa');

    if (idSiswa == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final authService = AuthService();
    final siswa = await authService.getSiswaById(idSiswa);

    setState(() {
      _siswa = siswa;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _siswa == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Data profil tidak ditemukan',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Profil',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildProfileItem('Nama', _siswa!.nama),
                  _buildProfileItem('NIS', _siswa!.nis),
                  _buildProfileItem('Username', _siswa!.username),
                  _buildProfileItem('ID Kelas', _siswa!.idKelas.toString()),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur Edit Profil akan segera hadir'),
                        ),
                      );
                    },
                    child: const Text('Edit Profil'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
