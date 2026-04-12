import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/navigation/route_names.dart';
import '../../services/token_storage_service.dart';

/// Shown after [SplashScreen] on first launch only (4s).
/// White background, centered [onboarding.png] only, then navigates after 4s.
class BrandIntroScreen extends StatefulWidget {
  const BrandIntroScreen({super.key});

  @override
  State<BrandIntroScreen> createState() => _BrandIntroScreenState();
}

class _BrandIntroScreenState extends State<BrandIntroScreen> {
  static const Color _bg = Colors.white;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _timer = Timer(const Duration(seconds: 4), _complete);
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasLaunched', true);
    if (kDebugMode) {
      debugPrint('BrandIntro: hasLaunched set, routing…');
    }
    if (!mounted) return;

    final isLoggedIn = await TokenStorageService.instance.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }

    final role = await TokenStorageService.instance.getUserRole();
    if (!mounted) return;
    final roleLower = role?.toLowerCase() ?? 'student';
    if (roleLower == 'instructor' || roleLower == 'teacher') {
      context.go(RouteNames.instructorHome);
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageMaxWidth = (size.width - 48).clamp(0.0, size.width);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Image.asset(
              'assets/images/onboarding.png',
              width: imageMaxWidth,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
