import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/navigation/route_names.dart';
import '../../services/token_storage_service.dart';

/// Splash — vertical teal gradient, transparent app logo, title, loader, person footer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.brandTealDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entryController.forward();

    Timer(const Duration(milliseconds: 3200), _checkFirstLaunch);
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool('hasLaunched') ?? false;

    if (kDebugMode) {
      debugPrint('Splash: hasLaunched=$hasLaunched');
    }

    if (!mounted) return;

    if (!hasLaunched) {
      context.go(RouteNames.brandIntro);
      return;
    }

    final isLoggedIn = await TokenStorageService.instance.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }

    final role = await TokenStorageService.instance.getUserRole();
    if (!mounted) return;
    final roleLower = role?.toLowerCase() ?? 'student';
    if (kDebugMode) {
      debugPrint('Splash: role=$roleLower');
    }
    if (roleLower == 'instructor' || roleLower == 'teacher') {
      context.go(RouteNames.instructorHome);
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.splashGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: h * 0.08),
              AnimatedBuilder(
                animation: _entryController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    _buildLogoSquircle(),
                    const SizedBox(height: 22),
                    const Text(
                      'A PLUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Indigo',
                        fontWeight: FontWeight.w400,
                        fontSize: 34,
                        letterSpacing: 2.0,
                        color: AppColors.pureWhite,
                        height: 1.05,
                        shadows: [
                          Shadow(
                            color: AppColors.whiteOverlay20,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                  color: AppColors.pureWhite,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              const Spacer(flex: 3),
              _buildPersonFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSquircle() {
    return SizedBox(
      width: 190,
      height: 190,
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandTealLight,
                AppColors.brandTeal,
              ],
            ),
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 72,
            color: AppColors.pureWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonFooter() {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) {
        return Opacity(
          opacity: 0.92 * _fade.value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/personSplash.jfif',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.whiteOverlay20,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.pureWhite,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DR. YOUSSEF SAMIR',
                    style: TextStyle(
                      fontFamily: AppTextStyles.radlushFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.6,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CEO & FOUNDER',
                    style: TextStyle(
                      fontFamily: AppTextStyles.radlushFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 1.0,
                      color: AppColors.pureWhite.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
