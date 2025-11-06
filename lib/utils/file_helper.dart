import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

/// Utility to open or download a file given a URL.
/// - Web: opens URL in new tab
/// - Mobile/Desktop: downloads to temporary file then opens with default app
Future<void> openOrDownloadFile({
  required String url,
  required String filename,
  void Function(int, int)? onProgress,
}) async {
  if (kIsWeb) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    }
    return;
  }

  // Mobile / Desktop: download file bytes then open
  final dio = Dio();
  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/$filename';

  try {
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );

    final file = File(filePath);
    await file.writeAsBytes(response.data!);
    await OpenFilex.open(file.path);
  } catch (e) {
    // fallback: try open url in browser
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    rethrow;
  }
}
