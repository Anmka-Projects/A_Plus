import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../core/design/app_colors.dart';
import '../../core/localization/localization_helper.dart';
import '../../services/video_download_service.dart';
import '../../models/download_model.dart';
import 'downloaded_video_player.dart';

/// Downloads Screen - Pixel-perfect match to React version
/// Matches: components/screens/downloads-screen.tsx
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isLoading = true;
  List<DownloadedVideoModel> _downloadedVideos = [];
  double _storageUsedMB = 0;
  double _storageLimitMB = 500;
  double _storagePercentage = 0;
  final VideoDownloadService _downloadService = VideoDownloadService();
  List<_LocalPdfFile> _localPdfFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _downloadService.initialize();
    await _loadDownloads();
    await _loadLocalPdfFiles();
  }

  Future<void> _loadDownloads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // تحميل الفيديوهات المحملة محلياً
      final videos = await _downloadService.getDownloadedVideosWithManager();

      // حساب إجمالي المساحة المستخدمة
      double totalSize = 0;
      for (var video in videos) {
        totalSize += video.fileSizeMb;
      }

      if (kDebugMode) {
        print('✅ Downloaded videos loaded:');
        print('  videos count: ${videos.length}');
        print('  total size: ${totalSize.toStringAsFixed(2)} MB');
      }

      if (!mounted) return;
      setState(() {
        _downloadedVideos = videos;
        _storageUsedMB = totalSize;
        _storageLimitMB = 500; // يمكن جلبها من API لاحقاً
        _storagePercentage =
            (_storageLimitMB > 0) ? (totalSize / _storageLimitMB * 100) : 0;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading downloads: $e');
      }
      if (!mounted) return;
      setState(() {
        _downloadedVideos = [];
        _storageUsedMB = 0;
        _storageLimitMB = 500;
        _storagePercentage = 0;
        _isLoading = false;
      });
    }
  }

  Future<Directory> _pdfStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}${Platform.pathSeparator}pdf_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _loadLocalPdfFiles() async {
    try {
      final dir = await _pdfStorageDirectory();
      final entities = await dir.list().toList();
      final pdfs = <_LocalPdfFile>[];
      for (final entity in entities) {
        if (entity is! File) continue;
        if (!entity.path.toLowerCase().endsWith('.pdf')) continue;
        final stat = await entity.stat();
        pdfs.add(
          _LocalPdfFile(
            path: entity.path,
            name: entity.uri.pathSegments.last,
            sizeBytes: stat.size,
          ),
        );
      }
      pdfs.sort((a, b) => b.name.compareTo(a.name));
      if (!mounted) return;
      setState(() => _localPdfFiles = pdfs);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading local pdf files: $e');
      }
    }
  }

  Future<void> _pickPdfFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final sourcePath = picked.path;
      if (sourcePath == null || sourcePath.isEmpty) return;
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return;

      final dir = await _pdfStorageDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = picked.name.replaceAll(' ', '_');
      final targetPath =
          '${dir.path}${Platform.pathSeparator}${timestamp}_$safeName';
      await sourceFile.copy(targetPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة ملف PDF إلى التحميلات',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadLocalPdfFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  Future<void> _deleteLocalPdf(_LocalPdfFile file) async {
    try {
      final f = File(file.path);
      if (await f.exists()) {
        await f.delete();
      }
      if (!mounted) return;
      await _loadLocalPdfFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  String _formatSize(double sizeMB) {
    if (sizeMB >= 1024) {
      return '${(sizeMB / 1024).toStringAsFixed(1)} GB';
    } else {
      return '${sizeMB.toStringAsFixed(0)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F7),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.brandGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandTealDark.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 28,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.whiteOverlay20,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_forward_ios_rounded
                                  : Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.downloads,
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'رفع PDF',
                        onPressed: _pickPdfFromDevice,
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.whiteOverlay20,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.downloadedFiles(_downloadedVideos.length),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content - matches React: px-4 -mt-4 space-y-4
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16), // -mt-4
                child: _isLoading
                    ? _buildLoadingState()
                    : RefreshIndicator(
                        onRefresh: _loadDownloads,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16), // px-4
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Storage Card - matches React: bg-white rounded-3xl p-5 shadow-lg
                              _buildStorageCard(),

                              // Downloaded Videos List
                              if (_downloadedVideos.isEmpty)
                                _buildEmptyState()
                              else
                                ..._downloadedVideos
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final video = entry.value;
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                        milliseconds: 400 + (index * 100)),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildVideoCard(context, video),
                                  );
                                }),
                              if (_localPdfFiles.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ..._localPdfFiles.map(_buildPdfCard),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    final usedGB = _storageUsedMB / 1024;
    final limitGB = _storageLimitMB / 1024;
    final percentage = _storagePercentage / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // space-y-4
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Storage icon and info - matches React: gap-3 mb-4
          Padding(
            padding: const EdgeInsets.only(bottom: 16), // mb-4
            child: Row(
              children: [
                Container(
                  width: 48, // w-12
                  height: 48, // h-12
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storage,
                    size: 24, // w-6 h-6
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.storage,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        context.l10n.storageUsed(
                          usedGB.toStringAsFixed(1),
                          limitGB.toStringAsFixed(1),
                        ),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar - matches React: h-3 bg-gray-100 rounded-full
          Container(
            height: 12, // h-3
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor:
                  percentage > 1 ? 1 : (percentage < 0 ? 0 : percentage),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.brandTealLight,
                      AppColors.brandTeal,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, DownloadedVideoModel video) {
    final title = video.title;
    final courseTitle = video.courseTitle;
    final sizeStr = _formatSize(video.fileSizeMb);
    final durationText =
        video.durationText.isNotEmpty ? video.durationText : 'غير محدد';

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // space-y-3
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Course info row - matches React: flex items-center gap-4
          Row(
            children: [
              // Video icon - matches React: w-16 h-16 rounded-xl
              Container(
                width: 64, // w-16
                height: 64, // h-16
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.video_library_rounded,
                  color: AppColors.brandTeal,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16), // gap-4

              // Course info - matches React: flex-1
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          durationText,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sizeStr,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              GestureDetector(
                onTap: () => _handleDelete(video),
                child: Container(
                  width: 40, // w-10
                  height: 40, // h-10
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  child: Icon(
                    Icons.delete,
                    size: 20, // w-5 h-5
                    color: Colors.red[500],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12), // mt-3

          // Play button - matches React: w-full py-3 rounded-xl bg-[var(--purple)]
          GestureDetector(
            onTap: () => _handlePlayOffline(video),
            child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF102027),
                    Color(0xFF4DD0E1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.watchOffline,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlayOffline(DownloadedVideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadedVideoPlayer(
          videoPath: video.localPath,
          videoTitle: video.title,
        ),
      ),
    );
  }

  Future<void> _handleDelete(DownloadedVideoModel video) async {
    // Show confirmation dialog
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteFile,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        content: Text(
          l10n.confirmDeleteFile,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.delete,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _downloadService.deleteDownloadedVideo(video.id);

      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.fileDeleted : l10n.unknownError,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor:
                success ? AppColors.success : AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Refresh the list
      _loadDownloads();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting video: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.unknownError}: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            ...List.generate(
                3,
                (index) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, // w-24
            height: 96, // h-24
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_rounded,
              size: 48,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noDownloads,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.downloadCoursesToWatchOffline,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(_LocalPdfFile file) {
    final sizeMb = file.sizeBytes / (1024 * 1024);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  _formatSize(sizeMb),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _LocalPdfViewerScreen(
                    filePath: file.path,
                    title: file.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.visibility_rounded, color: AppColors.purple),
          ),
          IconButton(
            onPressed: () => _deleteLocalPdf(file),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.destructive),
          ),
        ],
      ),
    );
  }
}

class _LocalPdfFile {
  final String path;
  final String name;
  final int sizeBytes;

  const _LocalPdfFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}

class _LocalPdfViewerScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const _LocalPdfViewerScreen({
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PDFView(filePath: filePath),
    );
  }
}
