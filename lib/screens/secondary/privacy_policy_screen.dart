import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/design/app_radius.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.cairo(
      fontSize: 14,
      height: 1.55,
      color: AppColors.foreground,
    );

    final mutedStyle = GoogleFonts.cairo(
      fontSize: 13,
      height: 1.55,
      color: AppColors.mutedForeground,
    );

    Widget section({
      required String title,
      required List<String> lines,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h4(color: AppColors.foreground),
            ),
            const SizedBox(height: 10),
            for (final line in lines) ...[
              Text(line, style: textStyle),
              const SizedBox(height: 6),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.pureWhite],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.largeCard),
                  bottomRight: Radius.circular(AppRadius.largeCard),
                ),
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Privacy Policy & Terms',
                      style: AppTextStyles.h3(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'RigTech Training Academy',
                        style: AppTextStyles.h4(color: AppColors.foreground),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'By continuing to use the app, you agree to the following terms.',
                        style: mutedStyle,
                      ),
                      const SizedBox(height: 16),
                      section(
                        title: '1. Introduction',
                        lines: [
                          'By accessing and using RigTech Training Academy, you agree to comply with these Terms and Conditions.',
                        ],
                      ),
                      section(
                        title: '2. User Accounts',
                        lines: [
                          'Users must provide accurate information.',
                          'You are responsible for maintaining account confidentiality.',
                          'Sharing accounts is strictly prohibited.',
                        ],
                      ),
                      section(
                        title: '3. Online Payments',
                        lines: [
                          'Payments are processed via secure third-party gateways (Visa, InstaPay, Vodafone Cash).',
                          'Full payment is required before accessing paid courses.',
                          'No refunds after course access, except approved exceptional cases.',
                          'The platform is not responsible for payment gateway errors or delays.',
                        ],
                      ),
                      section(
                        title: '4. Refund Policy',
                        lines: [
                          'Refunds may be granted only if the course has not been accessed or in technical failure cases verified by the platform.',
                        ],
                      ),
                      section(
                        title: '5. Certificates',
                        lines: [
                          'Certificates are issued upon successful completion of course requirements.',
                          'RigTech does not guarantee external accreditation unless stated.',
                        ],
                      ),
                      section(
                        title: '6. Intellectual Property',
                        lines: [
                          'All content is owned by RigTech Training Academy.',
                          'Copying, sharing, or redistribution is prohibited without written permission.',
                        ],
                      ),
                      section(
                        title: '7. Acceptable Use',
                        lines: [
                          'Users agree not to misuse the platform, attempt hacking, or distribute harmful content.',
                        ],
                      ),
                      section(
                        title: '8. Limitation of Liability',
                        lines: [
                          'RigTech is not responsible for outcomes resulting from course application.',
                          'All training is for educational purposes only.',
                        ],
                      ),
                      section(
                        title: '9. Service Availability',
                        lines: [
                          'The platform may be unavailable temporarily due to maintenance.',
                          'No liability is assumed for downtime.',
                        ],
                      ),
                      section(
                        title: '10. Privacy Policy',
                        lines: [
                          'User data is protected and used only for service improvement and communication.',
                        ],
                      ),
                      section(
                        title: '11. Governing Law',
                        lines: [
                          'These Terms are governed by the laws of the Arab Republic of Egypt.',
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
