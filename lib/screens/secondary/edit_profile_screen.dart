import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/localization/localization_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/profile_service.dart';

/// Profile screen — data is read-only (display only).
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;

  const EditProfileScreen({
    super.key,
    this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile =
          widget.initialProfile ?? await ProfileService.instance.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading profile: $e');
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.errorLoadingProfile,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  String _str(String? key) {
    final v = _profile?[key];
    if (v == null) return '';
    final s = v.toString().trim();
    return s;
  }

  String _languageLabel(AppLocalizations l10n) {
    final code = _str('language').toLowerCase();
    if (code == 'en') return l10n.english;
    if (code == 'ar' || code.isEmpty) return l10n.arabic;
    return code;
  }

  String _extractReadable(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is num || raw is bool) return raw.toString().trim();
    if (raw is Map<String, dynamic>) {
      final preferred = [
        'name',
        'name_ar',
        'title',
        'title_ar',
        'label',
      ];
      for (final key in preferred) {
        final v = raw[key]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }
    return '';
  }

  String _valueFromProfile(List<String> keys) {
    for (final key in keys) {
      final root = _extractReadable(_profile?[key]);
      if (root.isNotEmpty) return root;
    }
    final user = _profile?['user'];
    if (user is Map<String, dynamic>) {
      for (final key in keys) {
        final nested = _extractReadable(user[key]);
        if (nested.isNotEmpty) return nested;
      }
    }
    return '';
  }

  String _facultyName() {
    final direct = _valueFromProfile([
      'registrationFacultyName',
      'categoryName',
      // Backend currently returns readable faculty name in these keys.
      'faculty_id',
      'category_id',
      'faculty_name',
      'faculty',
      'facultyName',
      'faculty_label',
      'college',
      'college_name',
      // Keep UUID-like ids as last fallback only.
      'registrationFacultyId',
      'categoryId',
    ]);
    if (direct.isNotEmpty) return direct;
    final faculty = _profile?['faculty'];
    if (faculty is Map<String, dynamic>) {
      final name = faculty['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
      final nameAr = faculty['name_ar']?.toString().trim() ?? '';
      if (nameAr.isNotEmpty) return nameAr;
    }
    return _categoryNameFallback();
  }

  String _sectionName() {
    final direct = _valueFromProfile([
      'registrationSectionName',
      'subcategoryName',
      // Backend currently returns readable section name in these keys.
      'section_id',
      'subcategory_id',
      'section_name',
      'section',
      'sectionName',
      'section_label',
      'grade',
      'grade_name',
      'grade_id',
      // Keep UUID-like ids as last fallback only.
      'registrationSectionId',
      'subcategoryId',
    ]);
    if (direct.isNotEmpty) return direct;
    final section = _profile?['section'];
    if (section is Map<String, dynamic>) {
      final name = section['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
      final nameAr = section['name_ar']?.toString().trim() ?? '';
      if (nameAr.isNotEmpty) return nameAr;
    }
    return _subcategoryNameFallback();
  }

  String _categoryNameFallback() {
    final direct = _valueFromProfile(['category_name', 'categoryName']);
    if (direct.isNotEmpty) return direct;
    final category = _profile?['category'];
    if (category is Map<String, dynamic>) {
      final name = category['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
      final nameAr = category['name_ar']?.toString().trim() ?? '';
      if (nameAr.isNotEmpty) return nameAr;
    }
    return '';
  }

  String _subcategoryNameFallback() {
    final direct = _valueFromProfile(['subcategory_name', 'subcategoryName']);
    if (direct.isNotEmpty) return direct;
    final subcategory = _profile?['subcategory'];
    if (subcategory is Map<String, dynamic>) {
      final name = subcategory['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
      final nameAr = subcategory['name_ar']?.toString().trim() ?? '';
      if (nameAr.isNotEmpty) return nameAr;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.foreground,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.editProfile,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandTeal,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.brandTeal,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildAvatar(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _readOnlyField(
                    label: l10n.name,
                    value: _str('name'),
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  _readOnlyField(
                    label: l10n.phone,
                    value: _str('phone'),
                    icon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 16),
                  _readOnlyField(
                    label: isArabic ? 'الكلية' : l10n.faculty,
                    value: _facultyName(),
                    icon: Icons.school_rounded,
                  ),
                  const SizedBox(height: 16),
                  _readOnlyField(
                    label: isArabic ? 'الفرقة' : l10n.section,
                    value: _sectionName(),
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 16),
                  _readOnlyField(
                    label: l10n.language,
                    value: _languageLabel(l10n),
                    icon: Icons.language_rounded,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.brandTeal,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.profileReadOnlyMessage,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    final raw = _profile?['avatar']?.toString();
    if (raw == null || raw.isEmpty) {
      return const ColoredBox(
        color: AppColors.muted,
        child: Icon(
          Icons.person_rounded,
          size: 56,
          color: AppColors.brandTeal,
        ),
      );
    }
    final url = ApiEndpoints.getImageUrl(raw);
    if (url.isEmpty) {
      return const ColoredBox(
        color: AppColors.muted,
        child: Icon(
          Icons.person_rounded,
          size: 56,
          color: AppColors.brandTeal,
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppColors.muted,
        child: Icon(
          Icons.person_rounded,
          size: 56,
          color: AppColors.brandTeal,
        ),
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
    int? maxLines = 2,
  }) {
    final display = value.isEmpty ? '—' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.brandTeal, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  display,
                  maxLines: maxLines,
                  overflow: maxLines == null
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
