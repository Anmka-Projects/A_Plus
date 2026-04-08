import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_text_styles.dart';

class SupportAndHelpScreen extends StatelessWidget {
  const SupportAndHelpScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text(
            'Unable to open link',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  Widget _tile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lavenderLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium(color: AppColors.foreground)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fb = Uri.parse(
      'https://www.facebook.com/share/14TXZsfv8yZ/?mibextid=LQQJ4d',
    );
    final linkedin = Uri.parse(
      'https://www.linkedin.com/company/rigtech-training-academy/',
    );
    final youtube =
        Uri.parse('https://www.youtube.com/@RigTechtrainingAcademy');

    final phone1 = Uri.parse('tel:+201007619238');
    final whatsapp1 = Uri.parse('https://wa.me/201007619238');
    final whatsapp2 = Uri.parse('https://wa.me/201111666780');

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
                  Text(
                    'Support & Help',
                    style: AppTextStyles.h3(color: Colors.white),
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
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 88,
                                  height: 88,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.lavenderLight,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: AppColors.purple,
                                    size: 42,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Rigtech Training Academy',
                              style:
                                  AppTextStyles.h4(color: AppColors.foreground),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Contact us or follow our platforms.',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.mutedForeground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Platforms',
                          style: AppTextStyles.h4(color: AppColors.foreground),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tile(
                        context: context,
                        icon: Icons.facebook_rounded,
                        title: 'Facebook',
                        subtitle:
                            'https://www.facebook.com/share/14TXZsfv8yZ/?mibextid=LQQJ4d',
                        onTap: () => _launch(context, fb),
                      ),
                      _tile(
                        context: context,
                        icon: Icons.work_rounded,
                        title: 'LinkedIn',
                        subtitle:
                            'https://www.linkedin.com/company/rigtech-training-academy/',
                        onTap: () => _launch(context, linkedin),
                      ),
                      _tile(
                        context: context,
                        icon: Icons.ondemand_video_rounded,
                        title: 'YouTube',
                        subtitle: 'www.youtube.com/@RigTechtrainingAcademy',
                        onTap: () => _launch(context, youtube),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Contact',
                          style: AppTextStyles.h4(color: AppColors.foreground),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tile(
                        context: context,
                        icon: Icons.call_rounded,
                        title: '+20 100 761 9238',
                        subtitle: 'Phone call',
                        onTap: () => _launch(context, phone1),
                      ),
                      _tile(
                        context: context,
                        icon: Icons.chat_rounded,
                        title: '+20 100 761 9238',
                        subtitle: 'WhatsApp',
                        onTap: () => _launch(context, whatsapp1),
                      ),
                      _tile(
                        context: context,
                        icon: Icons.chat_rounded,
                        title: '+01111666780',
                        subtitle: 'WhatsApp',
                        onTap: () => _launch(context, whatsapp2),
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
