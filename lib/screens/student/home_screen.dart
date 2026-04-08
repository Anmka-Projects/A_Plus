import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../core/api/api_endpoints.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/home_service.dart';
import '../../services/courses_service.dart';
import '../../services/profile_service.dart';
import '../../services/notifications_service.dart';
import '../../services/teachers_service.dart';
import '../../l10n/app_localizations.dart';
import '../../data/sample_teachers.dart';

/// Home Screen - Enhanced with 3D Banner & Modern Design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _bannerController;
  late Animation<double> _bannerAnimation;

  // API Data
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _homeData;
  Map<String, dynamic>? _userProfile;
  int _notificationsCount = 0;
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
        setState(() => _userProfile = profile);
      } catch (e) {
        // User might not be logged in, continue
        if (kDebugMode) {
          print('❌ Error loading profile in home screen: $e');
        }
      }

      // Load notifications count if logged in
      try {
        final notifications =
            await NotificationsService.instance.getNotifications(
          unreadOnly: true,
          perPage: 1,
        );
        setState(() =>
            _notificationsCount = notifications['meta']?['unread_count'] ?? 0);
      } catch (e) {
        // User might not be logged in, continue
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

      setState(() {
        _homeData = homeData;
        _enrolledCourses = enrolled;
        _teachers = teachers;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      // Show error message instead of fallback data
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _enrolledCourses = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  List<Map<String, dynamic>> get _allCourses {
    final courses = <Map<String, dynamic>>[];
    for (final e in _enrolledCourses) {
      final c = _courseMapFromEnrollmentRow(e);
      if (c != null) courses.add(c);
    }
    return courses;
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
      backgroundColor: AppColors.pureWhite,
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
                // Enhanced Header
                _buildHeader(statusBarHeight),
                const SizedBox(height: 15),

                // Content
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: _errorMessage != null
                        ? _buildErrorView()
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 3D Banner
                                if (_isLoading)
                                  _build3DBannerSkeleton()
                                else
                                  _build3DBanner(),

                                const SizedBox(height: 24),

                                // Quick Stats Row
                                if (_isLoading)
                                  _buildQuickStatsSkeleton()
                                else
                                  _buildQuickStats(),

                                const SizedBox(height: 24),

                                // Teachers slider
                                _buildSectionHeader(l10n.teachers, () {
                                  context.push(
                                    RouteNames.teachers,
                                    extra: _teachers,
                                  );
                                }),
                                const SizedBox(height: 16),
                                if (_isLoading && _teachers.isEmpty)
                                  _buildTeachersSliderSkeleton()
                                else
                                  _buildTeachersSlider(l10n),

                                const SizedBox(height: 28),

                                // Enrolled courses only (replaces featured, categories, recommended)
                                if (_isLoading) ...[
                                  _buildSectionHeader(l10n.myCourses, () {}),
                                  const SizedBox(height: 16),
                                  _buildEnrolledCoursesSkeleton(),
                                  const SizedBox(height: 28),
                                ] else ...[
                                  _buildSectionHeader(
                                    l10n.myCourses,
                                    () => context.push(RouteNames.enrolled),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_enrolledCourses.isEmpty)
                                    _buildEnrolledCoursesEmpty()
                                  else
                                    _buildEnrolledCoursesHome(),
                                  const SizedBox(height: 28),
                                ],

                                const SizedBox(height: 140),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation
          const BottomNav(activeTab: 'home'),
        ],
      ),
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.largeCard),
          bottomRight: Radius.circular(AppRadius.largeCard),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.brandPurple.withOpacity(0.14),
            blurRadius: 42,
            offset: const Offset(0, 22),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative educational icons - transparent
          Positioned(
            top: statusBarHeight + 60,
            right: 20,
            child: Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 30,
            left: 40,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 30,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 60,
            child: Icon(
              Icons.science_outlined,
              size: 35,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            child: Icon(
              Icons.calculate_outlined,
              size: 28,
              color: Colors.white.withOpacity(0.06),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: statusBarHeight + 16,
              left: 20,
              right: 20,
              bottom: 56,
            ),
            child: Column(
              children: [
                // Top Row - Student Avatar, User & Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Student Avatar and welcome
                    Expanded(
                      child: Row(
                        children: [
                          // Student Avatar instead of logo
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _userProfile?['avatar'] != null
                                  ? Image.network(
                                      ApiEndpoints.getImageUrl(
                                        _userProfile!['avatar']?.toString(),
                                      ),
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
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
                                        if (kDebugMode) {
                                          print(
                                              '❌ Error loading avatar image: $error');
                                          print(
                                              '   Avatar URL: ${ApiEndpoints.getImageUrl(_userProfile!['avatar']?.toString())}');
                                          print('   Stack trace: $stackTrace');
                                        }
                                        return Image.asset(
                                          'assets/images/student-avatar.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.person,
                                              color: AppColors.purple,
                                              size: 28,
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
                                          size: 28,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.welcome(
                                      _userProfile?['name']?.toString() ??
                                          AppLocalizations.of(context)!
                                              .visitor),
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .excellentStudent,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
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
                    // Actions
                    Row(
                      children: [
                        // Settings
                        _buildHeaderButton(
                          icon: Icons.settings_outlined,
                          onTap: () => context.push(RouteNames.settings),
                        ),
                        const SizedBox(width: 8),
                        // Notifications with badge
                        _buildHeaderButton(
                          icon: Icons.notifications_none_rounded,
                          badge: _notificationsCount > 0
                              ? _notificationsCount.toString()
                              : null,
                          onTap: () => context.push(RouteNames.notifications),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Enhanced Oval Search Bar
                _buildSearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon, String? badge, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Oval shape
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: AppColors.foreground,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchPlaceholder,
          hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(right: 20, left: 12),
            child:
                Icon(Icons.search_rounded, color: AppColors.purple, size: 24),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.berkeleyBlue, AppColors.pureWhite],
              ),
              borderRadius: BorderRadius.circular(20), // Oval suffix
            ),
            child:
                const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        onTap: () {
          // Show search overlay
          _showSearchOverlay(context);
        },
        readOnly: true,
      ),
    );
  }

  void _showSearchOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchOverlay(
        allCourses: _allCourses,
        onCourseSelected: (course) {
          Navigator.pop(context);
          _handleCourseClick(course);
        },
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

// Search Overlay Widget
class _SearchOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> allCourses;
  final Function(Map<String, dynamic>) onCourseSelected;

  const _SearchOverlay({
    required this.allCourses,
    required this.onCourseSelected,
  });

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _searchController = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> get _filteredCourses {
    if (_query.isEmpty) return widget.allCourses;
    return widget.allCourses.where((course) {
      final title = course['title']?.toString() ?? '';
      final instructor = course['instructor'] is Map
          ? (course['instructor'] as Map)['name']?.toString() ?? ''
          : course['instructor']?.toString() ?? '';
      final category = course['category'] is Map
          ? (course['category'] as Map)['name']?.toString() ?? ''
          : course['category']?.toString() ?? '';

      return title.contains(_query) ||
          instructor.contains(_query) ||
          category.contains(_query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.cairo(fontSize: 15),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchPlaceholder,
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(right: 16, left: 12),
                    child: Icon(Icons.search_rounded, color: AppColors.purple),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noResultsFound,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      return GestureDetector(
                        onTap: () => widget.onCourseSelected(course),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (course['thumbnail'] != null ||
                                        course['image'] != null)
                                    ? Image.network(
                                        course['thumbnail']?.toString() ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => course[
                                                    'image'] !=
                                                null
                                            ? Image.asset(
                                                course['image']?.toString() ??
                                                    '',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: AppColors.purple
                                                      .withOpacity(0.1),
                                                  child: const Icon(Icons.image,
                                                      color: AppColors.purple),
                                                ),
                                              )
                                            : Container(
                                                width: 60,
                                                height: 60,
                                                color: AppColors.purple
                                                    .withOpacity(0.1),
                                                child: const Icon(Icons.image,
                                                    color: AppColors.purple),
                                              ),
                                      )
                                    : course['image'] != null
                                        ? Image.asset(
                                            course['image']?.toString() ?? '',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 60,
                                              height: 60,
                                              color: AppColors.purple
                                                  .withOpacity(0.1),
                                              child: const Icon(Icons.image,
                                                  color: AppColors.purple),
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: AppColors.purple
                                                .withOpacity(0.1),
                                            child: const Icon(Icons.image,
                                                color: AppColors.purple),
                                          ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course['title']?.toString() ?? '',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      course['instructor'] is Map
                                          ? (course['instructor']
                                                      as Map)['name']
                                                  ?.toString() ??
                                              ''
                                          : course['instructor']?.toString() ??
                                              '',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (course['isFree'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.free,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
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
      ),
    );
  }
}


// 1- وفيها زرار عرض المزيد تدخلك علي صفحه كل المحاضرين  اعمل سلايدر المحاضرون
// 2- لو ضغط علي اي معلم يفتح صفحه سينجل للمدرس تعرض الصوره واسمو بشكل رايق ونبذه عنو وتحتها كورساتو 