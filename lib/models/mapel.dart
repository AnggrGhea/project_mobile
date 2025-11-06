// lib/models/mapel.dart
class Mapel {
  final int idMapel;
  final String namaMapel;
  final int idKelas;
  final int idTahun;

  Mapel({
    required this.idMapel,
    required this.namaMapel,
    required this.idKelas,
    required this.idTahun,
  });

  factory Mapel.fromJson(Map<String, dynamic> json) {
    return Mapel(
      idMapel: json['id_mapel'] as int,
      namaMapel: json['nama_mapel'] as String,
      idKelas: json['id_kelas'] as int,
      idTahun: json['id_tahun'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_mapel': idMapel,
      'nama_mapel': namaMapel,
      'id_kelas': idKelas,
      'id_tahun': idTahun,
    };
  }
}
