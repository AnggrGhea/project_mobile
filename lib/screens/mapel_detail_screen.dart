import 'package:flutter/material.dart';
import '../models/mapel.dart';
import '../services/kelas_service.dart';
import '../utils/file_helper.dart';
import '../models/activity.dart';
import '../models/progress_siswa.dart';

class MapelDetailScreen extends StatefulWidget {
  final Mapel mapel;
  final int idSiswa; // Diperlukan untuk ambil progress

  const MapelDetailScreen({
    super.key,
    required this.mapel,
    required this.idSiswa,
  });

  @override
  State<MapelDetailScreen> createState() => _MapelDetailScreenState();
}

class _MapelDetailScreenState extends State<MapelDetailScreen> {
  final KelasService _kelasService = KelasService();
  List<Activity> _activities = [];
  List<ProgressSiswa> _progressList = [];
  bool _isLoading = true;
  int _currentIndex = 0; // 0 = Activity, 1 = Nilai

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint('Loading data for mapel ID: ${widget.mapel.idMapel}');

    // Ambil Activity
    final activities = await _kelasService.getActivityByMapelId(
      widget.mapel.idMapel,
    );
    debugPrint('Retrieved ${activities.length} activities');

    // Debug setiap activity
    for (var activity in activities) {
      debugPrint('Activity: ${activity.idActivity}');
      debugPrint('- Judul: ${activity.judul}');
      debugPrint('- Type: ${activity.type}');
      debugPrint('- Has Modul: ${activity.modul != null}');
    }

    setState(() {
      _activities = activities;
      debugPrint('State updated with ${_activities.length} activities');
    });

    // Ambil Progress Siswa
    final activityIds = activities.map((a) => a.idActivity).toList();
    if (activityIds.isNotEmpty) {
      final progress = await _kelasService.getProgressBySiswaAndActivity(
        widget.idSiswa,
        activityIds,
      );
      setState(() {
        _progressList = progress;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      initialIndex: _currentIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          elevation: 2,
          title: Text(
            widget.mapel.namaMapel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
          ),
          bottom: TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: colorScheme.secondary),
              insets: const EdgeInsets.symmetric(horizontal: 24.0),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Activity'),
              Tab(text: 'Nilai'),
            ],
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              )
            : TabBarView(children: [_buildActivityTab(), _buildNilaiTab()]),
      ),
    );
  }

  Widget _buildActivityTab() {
    debugPrint('Building Activity Tab with ${_activities.length} activities');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(31),
              child: Icon(
                _getIconForActivity(activity),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              _getTitleForActivity(activity),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            subtitle: Text(
              _getSubtitleForActivity(activity),
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey[600],
            ),
            onTap: () async {
              // Jika activity adalah modul dan memiliki file, buka/download
              if (activity.type == 'modul' && activity.modul != null) {
                final modul = activity.modul!;
                // Try common keys for file path
                final fileVal =
                    (modul['file_path'] ?? modul['file_modul'] ?? modul['file'])
                        ?.toString();
                if (fileVal == null || fileVal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File modul tidak tersedia')),
                  );
                  return;
                }

                // If fileVal looks like a numeric id, we can't resolve it here
                if (int.tryParse(fileVal) != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File modul belum tersimpan sebagai path'),
                    ),
                  );
                  return;
                }

                // get public url from storage
                final url = await _kelasService.getPublicFileUrl(
                  bucket: 'modul',
                  path: fileVal,
                );

                if (url == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal mengambil file')),
                  );
                  return;
                }

                // Open or download
                try {
                  await openOrDownloadFile(
                    url: url,
                    filename: fileVal.split('/').last,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuka file: $e')),
                  );
                }
                return;
              }

              // Default behavior: quick snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Activity ${activity.idActivity} diklik'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNilaiTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _progressList.length,
      itemBuilder: (context, index) {
        final progress = _progressList[index];
        final activity = _activities.firstWhere(
          (a) => a.idActivity == progress.idActivity,
          orElse: () =>
              Activity(idActivity: 0, judul: '', deskripsi: '', idMapel: 0),
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(31),
              child: Icon(
                _getIconForActivity(activity),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              _getTitleForActivity(activity),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            subtitle: Text(
              'Status: ${progress.status}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _scoreColor(progress.nilai),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${progress.nilai}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _scoreColor(double nilai) {
    // Simple thresholds: >=75 green, 50-74 amber, below 50 red
    if (nilai >= 75) return const Color(0xFF2E7D32); // green
    if (nilai >= 50) return const Color(0xFFF9A825); // amber
    return const Color(0xFFD32F2F); // red
  }

  IconData _getIconForActivity(Activity activity) {
    switch (activity.type) {
      case 'modul':
        return Icons.book;
      case 'kuis':
        return Icons.quiz;
      case 'tugas':
        return Icons.assignment;
      default:
        return Icons.info;
    }
  }

  String _getTitleForActivity(Activity activity) {
    return activity.judul;
  }

  String _getSubtitleForActivity(Activity activity) {
    final deadline = activity.deadline;
    final type = activity.type;

    if (deadline != null) {
      final date = deadline.toLocal();
      final deadlineStr = '${date.day}/${date.month}/${date.year}';

      if (type == 'kuis') {
        final durasi = activity.durasiKuis;
        return 'Kuis ${durasi}m | Deadline: $deadlineStr';
      } else if (type == 'tugas') {
        return 'Tugas | Deadline: $deadlineStr';
      }
    }

    return activity.deskripsi;
  }
}
