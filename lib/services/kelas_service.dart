// lib/services/kelas_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kelas.dart';
import '../models/mapel.dart';
import '../models/activity.dart';
import '../models/progress_siswa.dart';

class KelasService {
  final supabase = Supabase.instance.client;

  Future<List<Kelas>> getKelasBySiswaId(int idSiswa) async {
    try {
      // Ambil id_kelas dari siswa
      final siswaResponse = await supabase
          .from('siswa')
          .select('id_kelas')
          .eq('id_siswa', idSiswa)
          .maybeSingle();

      if (siswaResponse == null) {
        debugPrint('Siswa tidak ditemukan');
        return [];
      }

      final idKelas = siswaResponse['id_kelas'] as int;

      // Ambil data kelas berdasarkan id_kelas
      final response = await supabase
          .from('kelas')
          .select('*')
          .eq('id_kelas', idKelas);

      return response.map((json) => Kelas.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching kelas: $e');
      return [];
    }
  }

  // 🔥 Method Baru: Ambil Mapel Berdasarkan id_kelas
  Future<List<Mapel>> getMapelByKelasId(int idKelas) async {
    try {
      final response = await supabase
          .from(
            'mata_pelajaran',
          ) // Ganti dengan nama tabel yang benar di Supabase kamu
          .select('*')
          .eq('id_kelas', idKelas);

      return response.map((json) => Mapel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching mapel: $e');
      return [];
    }
  }

  // 🔥 Method Baru: Ambil Activity Berdasarkan id_mapel
  Future<List<Activity>> getActivityByMapelId(int idMapel) async {
    try {
      debugPrint('Fetching activities for mapel $idMapel');

      final query = supabase
          .from('activity')
          .select('''
            *,
            modul:modul!left(*),
            kuis:kuis!left(*),
            tugas:tugas!left(*)
          ''')
          .eq('id_mapel', idMapel);

      final response = await query;
      debugPrint('Supabase Response: $response');
      debugPrint('Response from Supabase: $response');

      debugPrint('Activity Response: $response'); // Debug print

      final activities = response
          .map((json) => Activity.fromJson(json))
          .toList();
      debugPrint('Parsed Activities: ${activities.length}'); // Debug count

      // Debug setiap activity
      for (var activity in activities) {
        debugPrint(
          'Activity ${activity.idActivity}: type=${activity.type}, hasModul=${activity.modul != null}',
        );
      }

      return activities;
    } catch (e) {
      debugPrint('Error fetching activity: $e');
      return [];
    }
  }

  // 🔥 Method Baru: Ambil Progress Siswa Berdasarkan id_siswa dan id_activity
  Future<List<ProgressSiswa>> getProgressBySiswaAndActivity(
    int idSiswa,
    List<int> activityIds,
  ) async {
    try {
      // Jika tidak ada activityIds, kembalikan list kosong lebih awal
      if (activityIds.isEmpty) return [];

      // Gunakan filter in_ pada kolom id_activity untuk mengambil progress yang relevan
      final orFilter = activityIds.map((id) => 'id_activity.eq.\$id').join(',');
      final response = await supabase
          .from('progress_siswa')
          .select('*')
          .eq('id_siswa', idSiswa)
          .or(orFilter);

      return response.map((json) => ProgressSiswa.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching progress: $e');
      return [];
    }
  }

  // Optional: Ambil nama jurusan berdasarkan id_jurusan
  Future<String> getNamaJurusan(int idJurusan) async {
    try {
      final response = await supabase
          .from('jurusan')
          .select('nama_jurusan')
          .eq('id_jurusan', idJurusan)
          .maybeSingle();

      if (response == null) {
        return 'Jurusan tidak ditemukan';
      }

      return response['nama_jurusan'] as String;
    } catch (e) {
      debugPrint('Error fetching jurusan: $e');
      return 'Error';
    }
  }

  /// Get public URL for a file stored in Supabase Storage bucket.
  /// Returns null if not available.
  Future<String?> getPublicFileUrl({
    required String bucket,
    required String path,
  }) async {
    try {
      final res = supabase.storage.from(bucket).getPublicUrl(path);
      // Try to access common keys dynamically (some SDKs return Map-like object)
      try {
        final dynamicMap = res as dynamic;
        final candidate =
            dynamicMap['publicURL'] ??
            dynamicMap['publicUrl'] ??
            dynamicMap['public_url'];
        if (candidate != null) return candidate.toString();
      } catch (_) {
        // ignore
      }

      // Fallback to string representation
      return res.toString();
    } catch (e) {
      debugPrint('Error getting public url: $e');
      return null;
    }
  }
}
