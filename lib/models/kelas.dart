// lib/models/kelas.dart
class Kelas {
  final int idKelas;
  final String namaKelas;
  final int idJurusan;
  final int idPengajar;
  final int idTahun;

  Kelas({
    required this.idKelas,
    required this.namaKelas,
    required this.idJurusan,
    required this.idPengajar,
    required this.idTahun,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      idKelas: json['id_kelas'] as int,
      namaKelas: json['nama_kelas'] as String,
      idJurusan: json['id_jurusan'] as int,
      idPengajar: json['id_pengajar'] as int,
      idTahun: json['id_tahun'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kelas': idKelas,
      'nama_kelas': namaKelas,
      'id_jurusan': idJurusan,
      'id_pengajar': idPengajar,
      'id_tahun': idTahun,
    };
  }
}
