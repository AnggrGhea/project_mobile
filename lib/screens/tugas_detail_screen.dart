import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../services/kelas_service.dart';
import '../utils/file_helper.dart';

class TugasDetailScreen extends StatefulWidget {
  final Activity activity;
  final int idSiswa;

  const TugasDetailScreen({
    super.key,
    required this.activity,
    required this.idSiswa,
  });

  @override
  State<TugasDetailScreen> createState() => _TugasDetailScreenState();
}

class _TugasDetailScreenState extends State<TugasDetailScreen> {
  final KelasService _kelasService = KelasService();
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  Future<void> openOrDownloadFile({
    required String url,
    required String filename,
  }) async {
    final uri = Uri.parse(url);
    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tugas = widget.activity.tugas;
    final fileVal = (tugas != null)
        ? (tugas['file_path'] ?? tugas['file_tugas'] ?? tugas['file'])
              ?.toString()
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.activity.judul)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activity.deskripsi,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (widget.activity.deadline != null)
              Text('Deadline: ${widget.activity.deadline!.toLocal()}'),
            const SizedBox(height: 20),
            if (fileVal != null &&
                fileVal.isNotEmpty &&
                int.tryParse(fileVal) == null)
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('Preview Tugas'),
                    onPressed: () async {
                      String? url;
                      final maybeUri = Uri.tryParse(fileVal);

                      final isAbsoluteHttp =
                          maybeUri != null &&
                          (maybeUri.scheme == 'http' ||
                              maybeUri.scheme == 'https');

                      if (isAbsoluteHttp) {
                        url = fileVal;
                      } else {
                        url = await _kelasService.getPublicFileUrl(
                          bucket: 'tugas',
                          path: fileVal,
                        );
                      }
                      if (url == null || url.isEmpty) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal mengambil file tugas'),
                          ),
                        );
                        return;
                      }

                      final lower = fileVal.toLowerCase();
                      final isDocx =
                          lower.endsWith('.doc') || lower.endsWith('.docx');
                      try {
                        if (isDocx) {
                          final preview =
                              'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(url)}';
                          final pu = Uri.parse(preview);
                          if (kIsWeb) {
                            await launchUrl(pu, webOnlyWindowName: '_blank');
                          } else {
                            await launchUrl(
                              pu,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        } else {
                          final uri = Uri.parse(url);
                          if (kIsWeb) {
                            await launchUrl(uri, webOnlyWindowName: '_blank');
                          } else {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membuka file: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () async {
                      String? url;
                      final maybeUri = Uri.tryParse(fileVal);

                      final isAbsoluteHttp =
                          maybeUri != null &&
                          (maybeUri.scheme == 'http' ||
                              maybeUri.scheme == 'https');

                      if (isAbsoluteHttp) {
                        url = fileVal;
                      } else {
                        url = await _kelasService.getPublicFileUrl(
                          bucket: 'tugas',
                          path: fileVal,
                        );
                      }
                      if (url == null || url.isEmpty) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal mengambil file tugas'),
                          ),
                        );
                        return;
                      }

                      try {
                        await openOrDownloadFile(
                          url: url,
                          filename: fileVal.split('/').last,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mendownload: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),

            const SizedBox(height: 24),
            const Text(
              'Kirim Tugas Kamu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _pickedFile?.name ?? 'Pilih file (pdf/doc/docx/csv)',
                    ),
                    onPressed: _isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx', 'csv'],
                              withData: true,
                            );
                            if (result == null || result.files.isEmpty) return;
                            setState(() {
                              _pickedFile = result.files.first;
                            });
                          },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_pickedFile == null || _isUploading)
                      ? null
                      : () async {
                          final bytes = _pickedFile!.bytes;
                          final filename = _pickedFile!.name;
                          if (bytes == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tidak bisa membaca file, coba lagi',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => _isUploading = true);

                          final sanitizedFilename = filename.replaceAll(
                            RegExp(r'[^\w\.-]+'),
                            '_',
                          );

                          final timestamp =
                              DateTime.now().millisecondsSinceEpoch;

                          // --- INI DIKEMBALIKAN KE VERSI LAMA ---
                          final authUserId =
                              Supabase.instance.client.auth.currentUser?.id;
                          final ownerFolder =
                              authUserId ?? widget.idSiswa.toString();
                          // ---------------------------------

                          final storagePath =
                              'private/$ownerFolder/submissions/${widget.activity.idActivity}/${timestamp}_$sanitizedFilename';

                          final uploadResult = await _kelasService
                              .uploadFileBytes(
                                bucket: 'tugas',
                                path: storagePath,
                                bytes: bytes,
                                filename: sanitizedFilename,
                              );
                          final ok = uploadResult['ok'] == true;
                          if (!ok) {
                            if (!mounted) return;
                            setState(() => _isUploading = false);
                            final msg =
                                uploadResult['message'] ??
                                'Gagal mengupload file';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengupload file: $msg'),
                              ),
                            );
                            return;
                          }

                          final publicUrl = await _kelasService
                              .getFileUrlOrSigned(
                                bucket: 'tugas',
                                path: storagePath,
                              );

                          // --- PASTIKAN 'kelas_service.dart' JUGA DIKEMBALIKAN ---
                          // --- FUNGSI submitTugasRecord HARUS MENERIMA idSiswa ---
                          final submitResult = await _kelasService
                              .submitTugasRecord(
                                idActivity: widget.activity.idActivity,
                                filePath: publicUrl ?? storagePath,
                                idSiswa: widget.idSiswa, // <-- Tambahkan ini
                              );
                          // ----------------------------------------------------

                          if (!mounted) return;
                          setState(() => _isUploading = false);

                          final dbOk = submitResult['ok'] == true;
                          if (dbOk) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tugas berhasil dikirim'),
                              ),
                            );
                            Navigator.pop(context, true);
                          } else {
                            final msg =
                                submitResult['message'] ??
                                'Gagal menyimpan metadata tugas';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Upload berhasil tapi gagal menyimpan metadata: $msg',
                                ),
                              ),
                            );
                          }
                        },
                  child: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kirim'),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Text(
              'Catatan: Kamu dapat mengunggah ulang jika ingin mengganti file.',
            ),
          ],
        ),
      ),
    );
  }
}
