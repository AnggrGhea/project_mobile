// lib/models/progress_siswa.dart
class ProgressSiswa {
  final int idProgress;
  final int idSiswa;
  final int idActivity;
  final double nilai;
  final String status;
  final String? fileSubmission;
  final String? feedbackPengajar;
  final DateTime? completedAt;

  ProgressSiswa({
    required this.idProgress,
    required this.idSiswa,
    required this.idActivity,
    required this.nilai,
    required this.status,
    this.fileSubmission,
    this.feedbackPengajar,
    this.completedAt,
  });

  factory ProgressSiswa.fromJson(Map<String, dynamic> json) {
    return ProgressSiswa(
      idProgress: json['id_progress'] as int,
      idSiswa: json['id_siswa'] as int,
      idActivity: json['id_activity'] as int,
      nilai: json['nilai'] as double,
      status: json['status'] as String,
      fileSubmission: json['file_submission'] as String?,
      feedbackPengajar: json['feedback_pengajar'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_progress': idProgress,
      'id_siswa': idSiswa,
      'id_activity': idActivity,
      'nilai': nilai,
      'status': status,
      'file_submission': fileSubmission,
      'feedback_pengajar': feedbackPengajar,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
