import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kelas.dart';
import '../models/mapel.dart';
import '../models/activity.dart';
import '../models/progress_siswa.dart';
import 'dart:typed_data';

class KelasService {
  final supabase = Supabase.instance.client;

  Future<List<Kelas>> getKelasBySiswaId(int idSiswa) async {
    try {
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

  Future<List<Mapel>> getMapelByKelasId(int idKelas) async {
    try {
      final response = await supabase
          .from('mata_pelajaran')
          .select('*')
          .eq('id_kelas', idKelas);

      return response.map((json) => Mapel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching mapel: $e');
      return [];
    }
  }

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

      debugPrint('Activity Response: $response');

      final activities = response
          .map((json) => Activity.fromJson(json))
          .toList();
      debugPrint('Parsed Activities: ${activities.length}');

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

  Future<List<ProgressSiswa>> getProgressBySiswaAndActivity(
    int idSiswa,
    List<int> activityIds,
  ) async {
    try {
      if (activityIds.isEmpty) return [];

      final orFilter = activityIds.map((id) => 'id_activity.eq.$id').join(',');
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

  Future<String?> getPublicFileUrl({
    required String bucket,
    required String path,
  }) async {
    try {
      final res = supabase.storage.from(bucket).getPublicUrl(path);
      try {
        final dynamicMap = res as dynamic;
        final candidate =
            dynamicMap['publicURL'] ??
            dynamicMap['publicUrl'] ??
            dynamicMap['public_url'];
        if (candidate != null) return candidate.toString();
      } catch (_) {}

      return res.toString();
    } catch (e) {
      debugPrint('Error getting public url: $e');
      return null;
    }
  }

  Future<String?> getFileUrlOrSigned({
    required String bucket,
    required String path,
    int expiresInSeconds = 60,
  }) async {
    try {
      final public = await getPublicFileUrl(bucket: bucket, path: path);
      if (public != null && public.isNotEmpty) {
        debugPrint('getFileUrlOrSigned: got public url for $bucket/$path');
        return public;
      }

      try {
        debugPrint(
          'getFileUrlOrSigned: attempting signed url for $bucket/$path',
        );
        final signed = await supabase.storage
            .from(bucket)
            .createSignedUrl(path, expiresInSeconds);
        try {
          final dynamicMap = signed as dynamic;
          final candidate =
              dynamicMap['signedURL'] ??
              dynamicMap['signedUrl'] ??
              dynamicMap['signed_url'];
          if (candidate != null) return candidate.toString();
        } catch (_) {}
        return signed.toString();
      } catch (e) {
        debugPrint('createSignedUrl failed: $e');
        return null;
      }
    } catch (e) {
      debugPrint('getFileUrlOrSigned error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadFileBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      await supabase.storage.from(bucket).uploadBinary(path, bytes);
      debugPrint('uploadBinary succeeded for $bucket/$path');
      return {'ok': true};
    } catch (e, st) {
      final msg = 'Upload error: $e';
      debugPrint(msg);
      debugPrint(st.toString());
      return {'ok': false, 'message': msg};
    }
  }

  Future<Map<String, dynamic>> submitTugasRecord({
    required int idActivity,
    required String filePath,
    required int idSiswa,
  }) async {
    try {
      await Supabase.instance.client.from('pengumpulan_tugas').insert({
        'id_tugas': idActivity,
        'file_url': filePath,
        'id_siswa': idSiswa,
      });

      return {'ok': true};
    } catch (e) {
      debugPrint('Error submitting task record: $e');
      return {'ok': false, 'message': e.toString()};
    }
  }
}
