// lib/models/siswa.dart
class Siswa {
  final int idSiswa;
  final String nama;
  final String nis;
  final String username;
  final int idKelas;
  final String? userId;

  Siswa({
    required this.idSiswa,
    required this.nama,
    required this.nis,
    required this.username,
    required this.idKelas,
    this.userId,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      idSiswa: json['id_siswa'] as int,
      nama: json['nama'] as String,
      nis: json['nis'] as String,
      username: json['username'] as String,
      idKelas: json['id_kelas'] as int,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_siswa': idSiswa,
      'nama': nama,
      'nis': nis,
      'username': username,
      'id_kelas': idKelas,
      'user_id': userId,
    };
  }
}
