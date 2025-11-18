import 'package:flutter/material.dart';
import '../models/mapel.dart';
import '../services/kelas_service.dart';
import '../utils/file_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../models/activity.dart';
import 'tugas_detail_screen.dart';
import '../models/progress_siswa.dart';

class MapelDetailScreen extends StatefulWidget {
  final Mapel mapel;
  final int idSiswa;

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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    debugPrint('Loading data for mapel ID: ${widget.mapel.idMapel}');

    final activities = await _kelasService.getActivityByMapelId(
      widget.mapel.idMapel,
    );
    debugPrint('Retrieved ${activities.length} activities');

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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mapel.namaMapel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_activities.length} aktivitas',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            tooltip: 'Kembali',
            color: Colors.white,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: Colors.white,
              child: TabBar(
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colorScheme.primary, width: 3),
                  ),
                ),
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.assignment_outlined, size: 20),
                    text: 'Aktivitas',
                  ),
                  Tab(
                    icon: Icon(Icons.grade_outlined, size: 20),
                    text: 'Nilai',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat data...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
            : TabBarView(children: [_buildActivityTab(), _buildNilaiTab()]),
      ),
    );
  }

  Widget _buildActivityTab() {
    debugPrint('Building Activity Tab with ${_activities.length} activities');

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada aktivitas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aktivitas akan muncul di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        final isDeadlineSoon = _isDeadlineSoon(activity);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                if (activity.type == 'modul' && activity.modul != null) {
                  final modul = activity.modul!;
                  final fileVal =
                      (modul['file_path'] ??
                              modul['file_modul'] ??
                              modul['file'])
                          ?.toString();
                  if (fileVal == null || fileVal.isEmpty) {
                    debugPrint(
                      'MapelDetail: modul fileVal is null/empty for activity ${activity.idActivity}',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File modul tidak tersedia'),
                      ),
                    );
                    return;
                  }

                  if (int.tryParse(fileVal) != null) {
                    debugPrint(
                      'MapelDetail: modul fileVal is numeric (${fileVal}) for activity ${activity.idActivity}',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'File modul belum tersimpan sebagai path',
                        ),
                      ),
                    );
                    return;
                  }

                  String? url;
                  final maybeUri = Uri.tryParse(fileVal);
                  final isAbsoluteHttp =
                      maybeUri != null &&
                      (maybeUri.scheme == 'http' || maybeUri.scheme == 'https');

                  if (isAbsoluteHttp) {
                    url = fileVal;
                  } else {
                    url = await _kelasService.getPublicFileUrl(
                      bucket: 'modul',
                      path: fileVal,
                    );
                  }

                  if (url == null || url.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal mengambil file')),
                    );
                    return;
                  }

                  try {
                    final uri = Uri.parse(url);
                    final lower = fileVal.toLowerCase();
                    final isDocx =
                        lower.endsWith('.doc') || lower.endsWith('.docx');
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membuka file: $e')),
                    );
                  }
                  return;
                }

                if (activity.type == 'tugas') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TugasDetailScreen(
                        activity: activity,
                        idSiswa: widget.idSiswa,
                      ),
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Activity ${activity.idActivity} diklik'),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getColorForActivity(activity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForActivity(activity),
                        color: _getColorForActivity(activity),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColorForActivity(
                                    activity,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getActivityTypeLabel(activity.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _getColorForActivity(activity),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isDeadlineSoon) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.red[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Segera',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getTitleForActivity(activity),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getSubtitleForActivity(activity),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Column(
                      children: [
                        if (activity.type == 'modul' && activity.modul != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 20,
                              ),
                              color: Colors.grey[700],
                              tooltip: 'Download',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                if (activity.type != 'modul' ||
                                    activity.modul == null)
                                  return;
                                final modul = activity.modul!;
                                final fileVal =
                                    (modul['file_path'] ??
                                            modul['file_modul'] ??
                                            modul['file'])
                                        ?.toString();
                                if (fileVal == null || fileVal.isEmpty) return;
                                if (int.tryParse(fileVal) != null) return;

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
                                    bucket: 'modul',
                                    path: fileVal,
                                  );
                                }
                                if (url == null || url.isEmpty) return;

                                try {
                                  await openOrDownloadFile(
                                    url: url,
                                    filename: fileVal.split('/').last,
                                  );
                                } catch (_) {}
                              },
                            ),
                          ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNilaiTab() {
    if (_progressList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada nilai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nilai akan muncul setelah pengerjaan',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Calculate average
    final totalNilai = _progressList.fold<double>(
      0,
      (sum, item) => sum + item.nilai,
    );
    final averageNilai = _progressList.isNotEmpty
        ? totalNilai / _progressList.length
        : 0.0;

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rata-rata Nilai',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      averageNilai.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_progressList.length} aktivitas dinilai',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _progressList.length,
            itemBuilder: (context, index) {
              final progress = _progressList[index];
              final activity = _activities.firstWhere(
                (a) => a.idActivity == progress.idActivity,
                orElse: () => Activity(
                  idActivity: 0,
                  judul: '',
                  deskripsi: '',
                  idMapel: 0,
                ),
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getColorForActivity(
                            activity,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForActivity(activity),
                          color: _getColorForActivity(activity),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTitleForActivity(activity),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      progress.status,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    progress.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(progress.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _scoreColor(progress.nilai),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${progress.nilai.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _scoreColor(double nilai) {
    if (nilai >= 75) return const Color(0xFF2E7D32);
    if (nilai >= 50) return const Color(0xFFF9A825);
    return const Color(0xFFD32F2F);
  }

  Color _getColorForActivity(Activity activity) {
    switch (activity.type) {
      case 'modul':
        return const Color(0xFF1976D2); // Blue
      case 'kuis':
        return const Color(0xFF7B1FA2); // Purple
      case 'tugas':
        return const Color(0xFFE65100); // Orange
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'proses':
      case 'in progress':
        return const Color(0xFFF9A825);
      case 'belum':
      case 'not started':
        return const Color(0xFF616161);
      default:
        return Colors.grey;
    }
  }

  String _getActivityTypeLabel(String type) {
    switch (type) {
      case 'modul':
        return 'MODUL';
      case 'kuis':
        return 'KUIS';
      case 'tugas':
        return 'TUGAS';
      default:
        return type.toUpperCase();
    }
  }

  bool _isDeadlineSoon(Activity activity) {
    if (activity.deadline == null) return false;
    final now = DateTime.now();
    final deadline = activity.deadline!;
    final difference = deadline.difference(now);
    return difference.inDays <= 2 && difference.inDays >= 0;
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
