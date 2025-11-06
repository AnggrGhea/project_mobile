// lib/models/activity.dart
import 'package:flutter/foundation.dart';

class Activity {
  final int idActivity;
  final String judul;
  final String deskripsi;
  final int idMapel;

  // Data dari join dengan tabel modul/kuis/tugas
  final Map<String, dynamic>? modul;
  final Map<String, dynamic>? kuis;
  final Map<String, dynamic>? tugas;

  Activity({
    required this.idActivity,
    required this.judul,
    required this.deskripsi,
    required this.idMapel,
    this.modul,
    this.kuis,
    this.tugas,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing activity JSON: $json');

    Map<String, dynamic>? parseRelation(dynamic value) {
      if (value == null) return null;
      // Supabase returns array for one-to-many joins; when empty list -> null
      if (value is List) {
        if (value.isEmpty) return null;
        final first = value.first;
        if (first is Map) return Map<String, dynamic>.from(first as Map);
        return null;
      }
      if (value is Map) return Map<String, dynamic>.from(value as Map);
      return null;
    }

    final activity = Activity(
      idActivity: json['id_activity'] is int
          ? json['id_activity'] as int
          : int.parse(json['id_activity'].toString()),
      judul: json['judul']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      idMapel: json['id_mapel'] is int
          ? json['id_mapel'] as int
          : int.parse(json['id_mapel'].toString()),
      modul: parseRelation(json['modul']),
      kuis: parseRelation(json['kuis']),
      tugas: parseRelation(json['tugas']),
    );

    debugPrint(
      'Parsed Activity - ID: ${activity.idActivity}, Type: ${activity.type}',
    );
    return activity;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_activity': idActivity,
      'judul': judul,
      'deskripsi': deskripsi,
      'id_mapel': idMapel,
      'modul': modul,
      'kuis': kuis,
      'tugas': tugas,
    };
  }

  // Helper untuk cek tipe activity
  String get type {
    if (modul != null && modul!.isNotEmpty) return 'modul';
    if (kuis != null && kuis!.isNotEmpty) return 'kuis';
    if (tugas != null) return 'tugas';
    return 'unknown';
  }

  // Helper untuk ambil deadline jika ada
  DateTime? get deadline {
    if (kuis != null) return DateTime.tryParse(kuis!['deadline'] ?? '');
    if (tugas != null) return DateTime.tryParse(tugas!['deadline'] ?? '');
    return null;
  }

  // Helper untuk ambil durasi kuis jika ada
  int? get durasiKuis => kuis?['durasi'];
}
