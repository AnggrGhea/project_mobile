// lib/screens/mycourse_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import SharedPreferencesS
import '../services/kelas_service.dart';
import '../models/mapel.dart';
import '../screens/mapel_detail_screen.dart'; // ✅ Import MapelDetailScreen

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen> {
  final KelasService _kelasService = KelasService();
  List<Mapel> _mapelList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapel();
  }

  Future<void> _loadMapel() async {
    // Ambil id_siswa dari session
    final prefs = await SharedPreferences.getInstance(); // ✅ Sekarang dikenali
    final idSiswa = prefs.getInt('id_siswa');

    if (idSiswa == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Ambil id_kelas dari siswa
    final kelasList = await _kelasService.getKelasBySiswaId(idSiswa);
    if (kelasList.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final idKelas = kelasList.first.idKelas;

    // Ambil daftar mapel berdasarkan id_kelas
    final mapelList = await _kelasService.getMapelByKelasId(idKelas);
    setState(() {
      _mapelList = mapelList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _mapelList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada mata pelajaran',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mapelList.length,
              itemBuilder: (context, index) {
                final mapel = _mapelList[index];
                return GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final idSiswa = prefs.getInt('id_siswa');
                    if (idSiswa != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MapelDetailScreen(mapel: mapel, idSiswa: idSiswa),
                        ),
                      );
                    }
                  },
                  child: _buildCourseCard(mapel),
                );
              },
            ),
    );
  }

  Widget _buildCourseCard(Mapel mapel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Image
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage('assets/images/book_placeholder.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tahun Ajaran (bisa diambil dari tabel tahun_ajaran nanti)
                  Text(
                    '2024/2025',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nama Mata Pelajaran
                  Text(
                    mapel.namaMapel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ID Kelas (opsional - bisa diganti dengan nama kelas)
                  Text(
                    'ID Kelas: ${mapel.idKelas}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
