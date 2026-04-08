import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';

/// Onboarding Screen - Pixel-perfect match to React version
/// Matches: components/screens/onboarding-screen.tsx
class OnboardingScreen extends StatelessWidget {
  final int step;

  const OnboardingScreen({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isStep1 = step == 1;
    final title = isStep1 ? l10n.learnEasily : l10n.continuousProgress;
    final subtitle = isStep1
        ? l10n.discoverBestCourses
        : l10n.trackProgressAndGetCertificates;
    final buttonText = isStep1 ? l10n.nextStep : l10n.startNow;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 400
                ? (MediaQuery.of(context).size.width - 400) / 2
                : 0,
          ),
          child: Column(
            children: [
              // Illustration area
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Stack(
                      children: [
                        // Main illustration card
                        Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(48),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
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
                                ),
                                child: Center(
                                  child: ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: AppColors.brandGradient,
                                    ).createShader(bounds),
                                    child: Icon(
                                      isStep1
                                          ? Icons.menu_book
                                          : Icons.emoji_events,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: isStep1 ? 64 : 32,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: isStep1
                                          ? const LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: AppColors.brandGradient,
                                            )
                                          : null,
                                      color: isStep1
                                          ? null
                                          : AppColors.mutedForeground
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: isStep1 ? 32 : 64,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: !isStep1
                                          ? const LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: AppColors.brandGradient,
                                            )
                                          : null,
                                      color: !isStep1
                                          ? null
                                          : AppColors.mutedForeground
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Floating decorations
                        Positioned(
                          top: -16,
                          right: -16,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppColors.brandGradient,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPurple.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            transform: Matrix4.rotationZ(0.2),
                          ),
                        ),
                        Positioned(
                          bottom: -24,
                          left: -24,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppColors.brandGradient,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPurple.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.largeCard),
                    topRight: Radius.circular(AppRadius.largeCard),
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Step indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: step == 1
                                ? const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: AppColors.brandGradient,
                                  )
                                : null,
                            color: step == 1 ? null : AppColors.muted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: step == 2
                                ? const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: AppColors.brandGradient,
                                  )
                                : null,
                            color: step == 2 ? null : AppColors.muted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mutedForeground,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: AppColors.brandGradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPurple.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isStep1) {
                              context.go(RouteNames.onboarding2);
                            } else {
                              // Mark onboarding as completed
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('hasLaunched', true);
                              if (kDebugMode) {
                                print('✅ Onboarding completed, hasLaunched set to true');
                              }
                              context.go(RouteNames.login);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.primaryForeground,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryForeground,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                buttonText,
                                style: GoogleFonts.cairo(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryForeground,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_back, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


