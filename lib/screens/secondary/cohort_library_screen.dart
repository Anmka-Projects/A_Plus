import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../services/home_service.dart';

/// Hierarchical cohort library: subject → group type → items (lock per item).
/// [root] is `materials` (books tab from home) or `quizzes` (quizzes tab).
class CohortLibraryScreen extends StatefulWidget {
  final String root;

  const CohortLibraryScreen({super.key, required this.root});

  @override
  State<CohortLibraryScreen> createState() => _CohortLibraryScreenState();
}

class _CohortLibraryScreenState extends State<CohortLibraryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _subjects = [];

  bool get _materialsRoot =>
      widget.root != 'quizzes' && widget.root != 'exams';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await HomeService.instance.getCohortLibrary();
      if (!mounted) return;
      if (payload == null) {
        setState(() {
          _subjects = [];
          _loading = false;
          _error = AppLocalizations.of(context)!.cohortLibraryLoadError;
        });
        return;
      }
      final raw = payload.raw;
      final list = raw['subjects'];
      if (list is List) {
        _subjects = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _subjects = [];
      }
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.cohortLibraryLoadError;
        _subjects = [];
      });
    }
  }

  String _screenTitle(AppLocalizations l10n) =>
      _materialsRoot ? l10n.cohortLibraryMaterialsAppTitle : l10n.cohortLibraryQuizzesAppTitle;

  String _subjectTitle(Map<String, dynamic> sub, AppLocalizations l10n) {
    final id = sub['id']?.toString() ?? '';
    if (id.startsWith('_synthetic')) {
      return l10n.cohortLibrarySyntheticSubjectTitle;
    }
    final ar = sub['title_ar']?.toString();
    final t = sub['title']?.toString();
    if (ar != null && ar.isNotEmpty) return ar;
    if (t != null && t.isNotEmpty) return t;
    return l10n.cohortLibrarySyntheticSubjectTitle;
  }

  String _groupLabel(Map<String, dynamic> group, AppLocalizations l10n) {
    final ar = group['label_ar']?.toString();
    final lb = group['label']?.toString();
    if (ar != null && ar.isNotEmpty) return ar;
    if (lb != null && lb.isNotEmpty) return lb;
    final type = (group['type'] ?? '').toString().toLowerCase();
    switch (type) {
      case 'summary':
        return l10n.cohortGroupTypeSummary;
      case 'book':
        return l10n.cohortGroupTypeBook;
      case 'quiz':
      case 'exam':
        return l10n.cohortGroupTypeQuiz;
      case 'file':
        return l10n.cohortGroupTypeFile;
      case 'video':
        return l10n.cohortGroupTypeVideo;
      case 'assignment':
        return l10n.cohortGroupTypeAssignment;
      default:
        return l10n.cohortGroupTypeOther;
    }
  }

  bool _isQuizGroupType(String type) {
    final t = type.toLowerCase();
    return t == 'quiz' || t == 'exam';
  }

  List<Map<String, dynamic>> _filteredGroups(Map<String, dynamic> subject) {
    final groups = subject['groups'];
    if (groups is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final g in groups) {
      if (g is! Map) continue;
      final gm = Map<String, dynamic>.from(g);
      final type = (gm['type'] ?? '').toString();
      final quizish = _isQuizGroupType(type);
      if (_materialsRoot) {
        if (!quizish) out.add(gm);
      } else {
        if (quizish || type.toLowerCase() == 'assignment') {
          out.add(gm);
        }
      }
    }
    return out;
  }

  String _itemTitle(Map<String, dynamic> item) {
    final ar = item['title_ar']?.toString();
    final t = item['title']?.toString();
    if (ar != null && ar.isNotEmpty) return ar;
    if (t != null && t.isNotEmpty) return t;
    return '';
  }

  static bool _coerceBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  void _onItemTap(Map<String, dynamic> item, AppLocalizations l10n) {
    final unlocked = _coerceBool(item['is_unlocked']);
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.homeCohortContentLockedHint,
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    final type = (item['type'] ?? '').toString().toLowerCase();
    final examId = item['exam_id']?.toString() ?? item['examId']?.toString();
    final fileUrl = item['file_url']?.toString() ?? item['fileUrl']?.toString();

    if (_isQuizGroupType(type) && examId != null && examId.isNotEmpty) {
      context.push(
        RouteNames.exams,
        extra: <String, dynamic>{
          'exam_id': examId,
          'title': _itemTitle(item),
        },
      );
      return;
    }

    if (fileUrl != null && fileUrl.isNotEmpty) {
      context.push(
        RouteNames.pdfViewer,
        extra: <String, dynamic>{
          'pdfUrl': fileUrl,
          'title': _itemTitle(item),
        },
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.cohortLibraryNoFileYet,
          style: GoogleFonts.cairo(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradient,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadius.largeCard),
                      bottomRight: Radius.circular(AppRadius.largeCard),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.brandPurple.withOpacity(0.12),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 24,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.whiteOverlay20,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _screenTitle(l10n),
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _loading
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.35,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ],
                          )
                        : _error != null && _subjects.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 20, 16, 120),
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  for (final subject in _subjects) ...[
                                    ..._buildSubjectSection(subject, l10n),
                                  ],
                                  if (!_loading &&
                                      _flattenVisibleItems() == 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 48),
                                      child: Text(
                                        l10n.cohortLibraryEmpty,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _flattenVisibleItems() {
    var n = 0;
    for (final s in _subjects) {
      for (final g in _filteredGroups(s)) {
        final items = g['items'];
        if (items is List) n += items.length;
      }
    }
    return n;
  }

  List<Widget> _buildSubjectSection(
    Map<String, dynamic> subject,
    AppLocalizations l10n,
  ) {
    final groups = _filteredGroups(subject);
    if (groups.isEmpty) return [];

    return [
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          child: ExpansionTile(
            initiallyExpanded: _subjects.length == 1,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              _subjectTitle(subject, l10n),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF006677),
              ),
            ),
            leading: Icon(
              Icons.folder_special_outlined,
              color: AppColors.brandBlue.withOpacity(0.9),
            ),
            children: [
              for (final group in groups)
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey(
                        '${subject['id']}_${group['id']}'),
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 0),
                    title: Text(
                      _groupLabel(group, l10n),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    leading: Icon(
                      _iconForGroup(group),
                      size: 22,
                      color: AppColors.mutedForeground,
                    ),
                    children: [
                      if (group['items'] is! List ||
                          (group['items'] as List).isEmpty)
                        ListTile(
                          title: Text(
                            l10n.cohortLibraryEmpty,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        )
                      else
                        for (final raw in (group['items'] as List))
                          if (raw is Map)
                            _buildItemTile(
                              Map<String, dynamic>.from(raw),
                              l10n,
                            ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  IconData _iconForGroup(Map<String, dynamic> group) {
    final type = (group['type'] ?? '').toString().toLowerCase();
    switch (type) {
      case 'summary':
        return Icons.article_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'quiz':
      case 'exam':
        return Icons.fact_check_outlined;
      case 'file':
        return Icons.attach_file_rounded;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'assignment':
        return Icons.assignment_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Widget _buildItemTile(Map<String, dynamic> item, AppLocalizations l10n) {
    final unlocked = _coerceBool(item['is_unlocked']);
    final title = _itemTitle(item);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title.isEmpty ? '—' : title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: unlocked
              ? AppColors.foreground
              : AppColors.mutedForeground,
        ),
      ),
      trailing: Icon(
        unlocked
            ? (Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right)
            : Icons.lock_outline_rounded,
        color: AppColors.mutedForeground,
        size: 20,
      ),
      onTap: () => _onItemTap(item, l10n),
    );
  }
}
