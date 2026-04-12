import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/theme_provider.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Login — code entry, header with gradient + logo, support & language footer.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Mockup palette
  static const Color _darkTeal = Color(0xFF006677);
  static const Color _cyan = Color(0xFF23C5C0);
  static const Color _gradientTealDeep = Color(0xFF0A6D6E);
  static const Color _fieldFill = Color(0xFFD9D9D9);
  static const Color _fieldBorder = Color(0xFFB0B0B0);
  static const Color _hintRed = Color(0xFFC0392B);

  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.pleaseActivateCodeFirst,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: _hintRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await AuthService.instance.login(
        code: code,
      );

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasLaunched', true);

      if (mounted) {
        final role = authResponse.user.role.toLowerCase();
        if (role == 'instructor' || role == 'teacher') {
          context.go(RouteNames.instructorHome);
        } else {
          context.go(RouteNames.home);
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.destructive,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context)!;
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: Column(
        children: [
          Expanded(
            flex: 42,
            child: _buildHeader(context),
          ),
          Expanded(
            flex: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.loginEnterCodeTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: _darkTeal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.enterStudentCode,
                              hintStyle: GoogleFonts.cairo(
                                color: AppColors.mutedForeground,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: _fieldFill,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: const BorderSide(
                                  color: _fieldBorder,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: const BorderSide(
                                  color: _fieldBorder,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: const BorderSide(
                                  color: _darkTeal,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.pleaseActivateCodeFirst,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _hintRed,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: _darkTeal,
                                foregroundColor: AppColors.pureWhite,
                                disabledBackgroundColor:
                                    _darkTeal.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.pureWhite,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      l10n.loginLogIn,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.go(RouteNames.register),
                              style: FilledButton.styleFrom(
                                backgroundColor: _darkTeal,
                                foregroundColor: AppColors.pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                l10n.codeActivation,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
                  child: _buildFooter(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _cyan,
                _gradientTealDeep,
              ],
            ),
          ),
        ),
        Positioned(
          top: -35,
          right: -45,
          child: CircleAvatar(
            radius: 75,
            backgroundColor: _darkTeal.withValues(alpha: 0.32),
          ),
        ),
        Positioned(
          top: 50,
          left: -55,
          child: CircleAvatar(
            radius: 58,
            backgroundColor: _darkTeal.withValues(alpha: 0.26),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 28,
          child: CircleAvatar(
            radius: 42,
            backgroundColor: _darkTeal.withValues(alpha: 0.22),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 8,
                child: IconButton(
                  onPressed: () => context.go(RouteNames.splash),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.whiteOverlay20,
                    foregroundColor: AppColors.pureWhite,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildLogoSquircle(),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSquircle() {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Image.asset(
          'assets/images/app_logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.school_rounded,
            size: 58,
            color: _darkTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.push(RouteNames.supportAndHelp),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 28,
                  color: _darkTeal,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.contactUs,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _darkTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: _showLanguagePicker,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 28,
                  color: _darkTeal,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chooseLanguage,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _darkTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
