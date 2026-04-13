import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/localization/localization_helper.dart';
import '../../core/navigation/route_names.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/courses_service.dart';

/// My Enrolled Courses Screen with search.
///
/// Optional [categoryId] / [categorySlug] / [screenTitle] come from `GoRouterState.extra`
/// (see [RouteNames.allCourses]).
class AllCoursesScreen extends StatefulWidget {
  final String? categoryId;
  final String? categorySlug;
  final String? screenTitle;

  const AllCoursesScreen({
    super.key,
    this.categoryId,
    this.categorySlug,
    this.screenTitle,
  });

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _courses = [];
  int _totalCourses = 0;
  bool get _hasCategoryFilter {
    final id = widget.categoryId?.trim();
    final slug = widget.categorySlug?.trim();
    return (id != null && id.isNotEmpty) || (slug != null && slug.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _loadCourses();
      }
    });
  }

  Future<void> _loadCourses() async {
    try {
      setState(() => _isLoading = true);
      List<Map<String, dynamic>> coursesList = [];
      int totalCoursesValue = 0;

      if (_hasCategoryFilter) {
        final response = await CoursesService.instance.getCourses(
          page: 1,
          perPage: 50,
          search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          categoryId: widget.categoryId,
          categorySlug: widget.categorySlug,
          price: 'all',
          sort: 'newest',
          level: 'all',
          duration: 'all',
        );

        if (response['data'] is List) {
          coursesList = (response['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (response['data'] is Map<String, dynamic>) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['courses'] is List) {
            coursesList = (dataMap['courses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        totalCoursesValue = response['meta']?['total'] is num
            ? (response['meta']!['total'] as num).toInt()
            : coursesList.length;
      } else {
        final response = await CoursesService.instance.getEnrollments(
          status: 'all',
          page: 1,
          perPage: 100,
        );

        final data = response['data'];
        List<Map<String, dynamic>> enrollments = <Map<String, dynamic>>[];
        if (data is List) {
          enrollments = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (data is Map<String, dynamic>) {
          final source = data['enrollments'] ?? data['courses'] ?? data['data'];
          if (source is List) {
            enrollments = source
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        coursesList = enrollments
            .map((enrollment) => enrollment['course'])
            .whereType<Map>()
            .map((course) => Map<String, dynamic>.from(course))
            .toList();

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          coursesList = coursesList.where((course) {
            final title = course['title']?.toString().toLowerCase() ?? '';
            final instructor = course['instructor'] is Map
                ? (course['instructor'] as Map)['name']
                        ?.toString()
                        .toLowerCase() ??
                    ''
                : course['instructor']?.toString().toLowerCase() ?? '';
            return title.contains(q) || instructor.contains(q);
          }).toList();
        }
        totalCoursesValue = coursesList.length;
      }

      setState(() {
        _courses = coursesList;
        _totalCourses = totalCoursesValue;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading courses: $e');
        print('  Stack trace: ${StackTrace.current}');
      }
      setState(() {
        _courses = [];
        _totalCourses = 0;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorLoadingCourses,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(context),

              // Courses Grid
              Expanded(
                child: _isLoading
                    ? _buildCoursesSkeleton()
                    : _courses.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.63,
                            ),
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              return _buildCourseCard(_courses[index]);
                            },
                          ),
              ),
            ],
          ),
          // Bottom Navigation
          const BottomNav(activeTab: ''),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
        left: 20,
        right: 20,
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(RouteNames.home),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.screenTitle?.trim().isNotEmpty == true
                          ? widget.screenTitle!.trim()
                          : (_hasCategoryFilter
                              ? context.l10n.allCourses
                              : context.l10n.myCourses),
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _hasCategoryFilter
                          ? context.l10n.coursesAvailable(_totalCourses)
                          : context.l10n.enrolledCoursesCount(_totalCourses),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar - Oval like Home
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
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
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: context.l10n.searchCourse,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 12),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradient,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              onChanged: (value) {
                // Search is handled by _onSearchChanged listener
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    // Safely parse price
    num priceValue = 0;
    if (course['price'] != null) {
      if (course['price'] is num) {
        priceValue = course['price'] as num;
      } else if (course['price'] is String) {
        priceValue = num.tryParse(course['price'] as String) ?? 0;
      }
    }
    final isFree = course['is_free'] == true || priceValue == 0;

    final thumbnail = course['thumbnail']?.toString() ?? '';
    final categoryName = course['category'] is Map
        ? (course['category'] as Map)['name']?.toString() ?? ''
        : course['category']?.toString() ?? '';
    final instructorName = course['instructor'] is Map
        ? (course['instructor'] as Map)['name']?.toString() ?? ''
        : course['instructor']?.toString() ?? '';

    // Safely parse rating
    num ratingValue = 0.0;
    if (course['rating'] != null) {
      if (course['rating'] is num) {
        ratingValue = course['rating'] as num;
      } else if (course['rating'] is String) {
        ratingValue = num.tryParse(course['rating'] as String) ?? 0.0;
      }
    }

    // Safely parse students_count
    int studentsCountValue = 0;
    if (course['students_count'] != null) {
      if (course['students_count'] is int) {
        studentsCountValue = course['students_count'] as int;
      } else if (course['students_count'] is num) {
        studentsCountValue = (course['students_count'] as num).toInt();
      } else if (course['students_count'] is String) {
        studentsCountValue =
            int.tryParse(course['students_count'] as String) ?? 0;
      }
    }

    return GestureDetector(
      onTap: () {
        context.push(RouteNames.courseDetails, extra: course);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: thumbnail.isNotEmpty
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandBlue.withOpacity(0.12),
                              AppColors.brandPurple.withOpacity(0.12),
                            ],
                          ),
                    color: thumbnail.isEmpty ? AppColors.lavenderLight : null,
                  ),
                  child: thumbnail.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Image.network(
                            thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildNoImagePlaceholder(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.lavenderLight,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _buildNoImagePlaceholder(),
                ),
                // Gradient overlay only when image exists
                if (thumbnail.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2)
                        ],
                      ),
                    ),
                  ),
                // Price Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isFree
                          ? const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)])
                          : const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isFree
                          ? context.l10n.free
                          : '${priceValue.toInt()} ${context.l10n.egyptianPoundShort}',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    if (categoryName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandBlue.withOpacity(0.15),
                              AppColors.brandPurple.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.brandGradient,
                          ).createShader(bounds),
                          child: Text(
                            categoryName,
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (categoryName.isNotEmpty) const SizedBox(height: 6),
                    // Title
                    Text(
                      course['title']?.toString() ?? context.l10n.noTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Instructor
                    if (instructorName.isNotEmpty)
                      Text(
                        instructorName,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    const Spacer(),
                    // Stats
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          ratingValue.toStringAsFixed(1),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.people_rounded,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text(
                          studentsCountValue.toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
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

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandBlue.withOpacity(0.14),
            AppColors.brandPurple.withOpacity(0.14),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandBlue.withOpacity(0.12),
                    AppColors.brandPurple.withOpacity(0.12),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.brandGradient,
                ).createShader(bounds),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.brandGradient,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandBlue.withOpacity(0.14),
                  AppColors.brandPurple.withOpacity(0.14),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ).createShader(bounds),
              child: const Icon(
                Icons.search_off_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.noResults,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tryDifferentSearch,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                        const SizedBox(height: 6),
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
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              height: 12,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 12,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
