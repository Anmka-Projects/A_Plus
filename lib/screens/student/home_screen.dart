// Legacy home widgets (banner, teachers slider, etc.) kept for reference; main home uses the new layout.
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../core/config/theme_provider.dart';
import '../../core/api/api_endpoints.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/home_service.dart';
import '../../services/courses_service.dart';
import '../../services/profile_service.dart';
import '../../services/teachers_service.dart';
import '../../l10n/app_localizations.dart';
import '../../data/sample_teachers.dart';
import '../../models/medical_track.dart';

/// Home Screen - Enhanced with 3D Banner & Modern Design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const Color _homeTitleTeal = Color(0xFF006677);

  late AnimationController _bannerController;
  late Animation<double> _bannerAnimation;

  // API Data
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _homeData;
  Map<String, dynamic>? _userProfile;
  /// Enrollment rows from [CoursesService.getEnrollments] (each may include `course`).
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> _teachers = [];

  /// Soft layered shadows for white cards (brand glow + depth).
  List<BoxShadow> get _homeCardShadows => [
        BoxShadow(
          color: AppColors.brandBlue.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ];

  /// Hero banner: colored glow under the card.
  List<BoxShadow> get _homeHeroShadows => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.38),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: AppColors.brandPurple.withOpacity(0.16),
          blurRadius: 40,
          offset: const Offset(0, 20),
          spreadRadius: -8,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutBack,
    );
    _bannerController.forward();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Load home data
      final homeData = await HomeService.instance.getHomeData();

      // Load user profile if logged in
      try {
        final profile = await ProfileService.instance.getProfile();
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('🖼️ HOME SCREEN - PROFILE AVATAR');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('Profile avatar raw: ${profile['avatar']}');
          print('Profile avatar type: ${profile['avatar']?.runtimeType}');
          if (profile['avatar'] != null) {
            final avatarUrl =
                ApiEndpoints.getImageUrl(profile['avatar']?.toString());
            print('Profile avatar URL: $avatarUrl');
            print('Avatar URL length: ${avatarUrl.length}');
            print('Avatar URL is empty: ${avatarUrl.isEmpty}');
          } else {
            print('⚠️ Profile avatar is null');
          }
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        if (!mounted) return;
        setState(() => _userProfile = profile);
      } catch (e) {
        // User might not be logged in, continue
        if (kDebugMode) {
          print('❌ Error loading profile in home screen: $e');
        }
      }

      // Load teachers from API
      List<Map<String, dynamic>> teachers = [];
      try {
        final teachersResponse = await TeachersService.instance.getTeachers(
          page: 1,
          perPage: 10, // Load first 10 teachers for the slider
          sort: 'rating',
        );
        final data = teachersResponse['data'];
        if (data is Map<String, dynamic> && data['teachers'] != null) {
          teachers = List<Map<String, dynamic>>.from(data['teachers']);
        } else if (data is List) {
          teachers = List<Map<String, dynamic>>.from(data);
        }
      } catch (e) {
        // Fallback to sample teachers if API fails
        teachers = List<Map<String, dynamic>>.from(kSampleTeachers);
      }

      List<Map<String, dynamic>> enrolled = [];
      try {
        final enrResponse = await CoursesService.instance.getEnrollments(
          status: 'all',
          page: 1,
          perPage: 50,
        );
        enrolled = _parseEnrollmentsData(enrResponse['data']);
      } catch (_) {
        enrolled = [];
      }

      if (!mounted) return;
      setState(() {
        _homeData = homeData;
        _enrolledCourses = enrolled;
        _teachers = teachers;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      // Show error message instead of fallback data
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _enrolledCourses = [];
      });
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _courseMapFromEnrollmentRow(Map<String, dynamic> row) {
    final nested = row['course'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    if (row['title'] != null || row['id'] != null) {
      return Map<String, dynamic>.from(row);
    }
    return null;
  }

  List<Map<String, dynamic>> _parseEnrollmentsData(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final courses = data['courses'];
      if (courses is List) {
        return courses
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return [];
  }

  void _handleTeacherTap(Map<String, dynamic> teacher) {
    if (!mounted) return;
    context.push(RouteNames.teacherDetails, extra: teacher);
  }

  void _handleCourseClick(Map<String, dynamic> course) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('hasLaunched') ?? false;
    final isFree = course['isFree'] == true || course['is_free'] == true;

    if (!isFree && !isLoggedIn) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.loginRequired),
            content: Text(l10n.loginRequired),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
                child: Text(
                  l10n.login,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        if (result == true && mounted) {
          context.push(RouteNames.login);
        }
      }
      return;
    }

    if (mounted) {
      context.push(RouteNames.courseDetails, extra: course);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F7),
      extendBodyBehindAppBar: false,
      appBar: _HomeAppBar(
        statusBarHeight: statusBarHeight,
        l10n: l10n,
        userProfile: _userProfile,
        onLanguageTap: () => _showHomeLanguagePicker(l10n),
        onSettingsTap: () => context.push(RouteNames.settings),
      ),
      body: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 430),
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 430
                  ? (MediaQuery.of(context).size.width - 430) / 2
                  : 0,
            ),
            child: Column(
              children: [
                Expanded(
                  child: _errorMessage != null
                      ? _buildErrorView()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isLoading) ...[
                                _buildHomeMainSkeleton(),
                              ] else ...[
                                _buildCoursesTrackSection(l10n),
                                const SizedBox(height: 28),
                                _buildBooksAssignmentsSection(l10n),
                              ],
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),

          const BottomNav(activeTab: 'home'),
        ],
      ),
    );
  }

  void _showHomeLanguagePicker(AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.chooseLanguage,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                ListTile(
                  title: Text('العربية', style: GoogleFonts.cairo()),
                  onTap: () {
                    ThemeProvider.instance.setLanguage(const Locale('ar'));
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  title: Text('English', style: GoogleFonts.cairo()),
                  onTap: () {
                    ThemeProvider.instance.setLanguage(const Locale('en'));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeMainSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 28, height: 28, color: Colors.white),
              const SizedBox(width: 8),
              Container(
                width: 140,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: List.generate(
              6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTrackSection(AppLocalizations l10n) {
    const trackSvgs = <String>[
      'assets/icons/tracks/doctor.svg',
      'assets/icons/tracks/dentist.svg',
      'assets/icons/tracks/physiotherapist.svg',
      'assets/icons/tracks/pharmacist.svg',
      'assets/icons/tracks/nurse.svg',
      'assets/icons/tracks/scientist.svg',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 26,
              color: _homeTitleTeal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.homeCoursesSectionTitle,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _homeTitleTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.88,
          children: List.generate(MedicalTrack.values.length, (i) {
            final track = MedicalTrack.values[i];
            final label = _trackLabel(l10n, track);
            return _buildTrackTile(
              svgAsset: trackSvgs[i],
              label: label,
              onTap: () => context.push(
                RouteNames.allCourses,
                extra: <String, dynamic>{
                  'categorySlug': track.slug,
                  'screenTitle': label,
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  String _trackLabel(AppLocalizations l10n, MedicalTrack track) {
    switch (track) {
      case MedicalTrack.doctor:
        return l10n.trackDoctor;
      case MedicalTrack.dentist:
        return l10n.trackDentist;
      case MedicalTrack.physiotherapist:
        return l10n.trackPhysiotherapist;
      case MedicalTrack.pharmacist:
        return l10n.trackPharmacist;
      case MedicalTrack.nurse:
        return l10n.trackNurse;
      case MedicalTrack.scientist:
        return l10n.trackScientist;
    }
  }

  Widget _buildTrackTile({
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    const iconBg = Color(0xFFF0F7F8);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _homeCardShadows,
          ),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Icon(
                    Icons.medical_services_outlined,
                    size: 28,
                    color: _homeTitleTeal.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksAssignmentsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeBooksAssignmentsSection,
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _homeTitleTeal,
          ),
        ),
        const SizedBox(height: 14),
        _buildHomeWideCard(
          icon: Icons.library_books_rounded,
          iconColors: const [
            Color(0xFF5B8DEF),
            Color(0xFFE85D75),
            Color(0xFF4ECDC4),
          ],
          title: l10n.homeDeptHeadsBooks,
          onTap: () => context.push(RouteNames.downloads),
        ),
        const SizedBox(height: 12),
        _buildHomeWideCard(
          icon: Icons.fact_check_outlined,
          iconColors: const [Color(0xFF006677)],
          title: l10n.homeQuizzesAssignments,
          onTap: () => context.push(RouteNames.myExams),
        ),
      ],
    );
  }

  Widget _buildHomeWideCard({
    required IconData icon,
    required List<Color> iconColors,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _homeCardShadows,
          ),
          child: Row(
            children: [
              if (iconColors.length >= 3)
                SizedBox(
                  width: 52,
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 4,
                        child: Container(
                          width: 22,
                          height: 30,
                          decoration: BoxDecoration(
                            color: iconColors[0],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        child: Container(
                          width: 22,
                          height: 30,
                          decoration: BoxDecoration(
                            color: iconColors[1],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 6,
                        child: Container(
                          width: 22,
                          height: 30,
                          decoration: BoxDecoration(
                            color: iconColors[2],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColors.first.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColors.first, size: 28),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _homeTitleTeal,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DBanner() {
    final heroBanner = _homeData?['hero_banner'] as Map<String, dynamic>?;
    final title = heroBanner?['title']?.toString();
    final subtitle = heroBanner?['subtitle']?.toString();
    final buttonText = heroBanner?['button_text']?.toString();
    final imageUrl = heroBanner?['image']?.toString();

    // Don't show banner if no data
    if (title == null && subtitle == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _bannerAnimation,
        builder: (context, child) {
          // Clamp animation value to ensure it stays within 0.0-1.0 range
          // Use max/min to ensure safety even if value is NaN or Infinity
          final rawValue = _bannerAnimation.value;
          final animationValue = (rawValue.isNaN || rawValue.isInfinite)
              ? 1.0
              : rawValue.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.9 + (animationValue * 0.1),
            child: Opacity(
              opacity: animationValue,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: _homeHeroShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: 60,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),

                // Main Row - Text on right, Character on left
                Row(
                  children: [
                    // 3D Character - Inside banner on left
                    Expanded(
                      flex: 4,
                      child: Transform.translate(
                        offset: const Offset(-10, 10),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/student-character.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    margin: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 60,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              )
                            : Image.asset(
                                'assets/images/student-character.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  margin: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    size: 60,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    // Content on right
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (heroBanner?['badge'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        color: Colors.orange, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      heroBanner?['badge']?.toString() ??
                                          AppLocalizations.of(context)!
                                              .specialOffer,
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (title != null) ...[
                              if (heroBanner?['badge'] != null)
                                const SizedBox(height: 8),
                              Text(
                                title,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ],
                            if (subtitle != null) ...[
                              if (title != null) const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                            if (buttonText != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  buttonText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DBannerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Skeletonizer(
        enabled: true,
        child: Container(
          height: 165,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: _homeHeroShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 18,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 32,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    // Get user summary from API
    final userSummary = _homeData?['user_summary'] as Map<String, dynamic>?;
    final enrolledCourses = userSummary?['enrolled_courses'] ?? 0;
    final certificates = userSummary?['certificates'] ?? 0;
    final totalHours = userSummary?['total_hours'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.play_circle_fill_rounded,
            value: enrolledCourses.toString(),
            label: AppLocalizations.of(context)!.enrolledCourse,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.emoji_events_rounded,
            value: certificates.toString(),
            label: AppLocalizations.of(context)!.certificates,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.access_time_filled_rounded,
            value: totalHours.toString(),
            label: AppLocalizations.of(context)!.learningHours,
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Skeletonizer(
        enabled: true,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _homeCardShadows,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 11,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _homeCardShadows,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 11,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _homeCardShadows,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 11,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _homeCardShadows,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.brandBlue.withOpacity(0.12),
                    AppColors.brandPurple.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandBlue.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: AppColors.brandGradient,
                ).createShader(bounds),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.viewMore,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersSlider(AppLocalizations l10n) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: _teachers.length,
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          final avatarUrl = teacher['avatar']?.toString() ?? '';
          final hasAvatar = avatarUrl.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _handleTeacherTap(teacher),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _homeCardShadows,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppColors.brandGradient,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: hasAvatar
                                ? NetworkImage(avatarUrl)
                                : null,
                            onBackgroundImageError: (_, __) {},
                            child: hasAvatar
                                ? null
                                : ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: AppColors.brandGradient,
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.person,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher['name']?.toString() ?? '',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foreground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                teacher['title']?.toString() ?? '',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      teacher['bio']?.toString() ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          (teacher['rating'] ?? 0).toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: AppColors.brandGradient,
                          ).createShader(bounds),
                          child: const Icon(Icons.people_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: AppColors.brandGradient,
                          ).createShader(bounds),
                          child: Text(
                            l10n.studentsCount(
                                (teacher['students'] as int?) ?? 0),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.brandBlue.withOpacity(0.12),
                                AppColors.brandPurple.withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: AppColors.brandGradient,
                            ).createShader(bounds),
                            child: Text(
                              l10n.coursesCount(
                                (teacher['courses_count'] as int?) ??
                                    (teacher['courses'] as List?)?.length ??
                                    0,
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeachersSliderSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 8),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _homeCardShadows,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 12,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 16,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 16,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 24,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _loadHomeData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCoursesHome() {
    final rows = <Widget>[];
    var n = 0;
    const maxItems = 6;
    for (final enrollment in _enrolledCourses) {
      if (n >= maxItems) break;
      final course = _courseMapFromEnrollmentRow(enrollment);
      if (course == null) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHorizontalCourseCard(course),
        ),
      );
      n++;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: rows),
    );
  }

  Widget _buildEnrolledCoursesEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _homeCardShadows,
        ),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noEnrolledCourses,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCourseCard(Map<String, dynamic> course) {
    return GestureDetector(
      onTap: () => _handleCourseClick(course),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _homeCardShadows,
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandBlue.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: course['thumbnail'] != null
                    ? Image.network(
                        course['thumbnail']?.toString() ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => course['image'] != null
                            ? Image.asset(
                                course['image']?.toString() ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.purple.withOpacity(0.1),
                                  child: const Icon(Icons.image,
                                      color: AppColors.purple, size: 30),
                                ),
                              )
                            : Container(
                                color: AppColors.purple.withOpacity(0.1),
                                child: const Icon(Icons.image,
                                    color: AppColors.purple, size: 30),
                              ),
                      )
                    : course['image'] != null
                        ? Image.asset(
                            course['image']?.toString() ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.purple.withOpacity(0.1),
                              child: const Icon(Icons.image,
                                  color: AppColors.purple, size: 30),
                            ),
                          )
                        : Container(
                            color: AppColors.purple.withOpacity(0.1),
                            child: const Icon(Icons.image,
                                color: AppColors.purple, size: 30),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course['category']?['name'] ??
                              course['category'] ??
                              '',
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.purple,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      if ((course['is_free'] ?? course['isFree']) == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.free,
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course['title'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course['instructor']?['name'] ?? course['instructor'] ?? '',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${course['rating'] ?? 0}',
                        style: GoogleFonts.cairo(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${course['duration_hours'] ?? course['hours'] ?? 0}س',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppColors.mutedForeground),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people_rounded,
                          size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${course['students_count'] ?? course['students'] ?? 0}',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton Loading Widgets
  Widget _buildEnrolledCoursesSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(2, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _homeCardShadows,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Home-only app bar: teal gradient, profile (read-only), language action, tagline.
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double statusBarHeight;
  final AppLocalizations l10n;
  final Map<String, dynamic>? userProfile;
  final VoidCallback onLanguageTap;
  final VoidCallback onSettingsTap;

  const _HomeAppBar({
    required this.statusBarHeight,
    required this.l10n,
    required this.userProfile,
    required this.onLanguageTap,
    required this.onSettingsTap,
  });

  static const double _contentHeight = 138;
  static const Color _gradientTop = Color(0xFF23C5C0);
  static const Color _gradientBottom = Color(0xFF0A6D6E);

  @override
  Size get preferredSize => Size.fromHeight(statusBarHeight + _contentHeight);

  @override
  Widget build(BuildContext context) {
    final displayName = userProfile?['name']?.toString().trim().isNotEmpty == true
        ? userProfile!['name'].toString()
        : l10n.visitor;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradientTop, _gradientBottom],
          ),
          boxShadow: [
            BoxShadow(
              color: _gradientBottom.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: statusBarHeight + 6,
            left: 20,
            right: 16,
            bottom: 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: userProfile?['avatar'] != null
                                    ? Image.network(
                                        ApiEndpoints.getImageUrl(
                                          userProfile!['avatar']?.toString(),
                                        ),
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.white,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.purple,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/student-avatar.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: Colors.white,
                                              child: const Icon(
                                                Icons.person,
                                                color: AppColors.purple,
                                                size: 26,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        'assets/images/student-avatar.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.white,
                                          child: const Icon(
                                            Icons.person,
                                            color: AppColors.purple,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.welcomeLabel,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSettingsTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Tooltip(
                            message: l10n.settings,
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                color: Colors.white.withValues(alpha: 0.95),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onLanguageTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  size: 22,
                                ),
                                Positioned(
                                  right: 7,
                                  bottom: 8,
                                  child: Text(
                                    'A',
                                    style: GoogleFonts.cairo(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.homeMotivationalLine,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.35,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
