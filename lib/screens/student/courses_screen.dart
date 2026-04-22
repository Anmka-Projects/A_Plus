import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_track.dart';
import '../../widgets/bottom_nav.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  static const Color _titleTeal = Color(0xFF006677);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F7),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandTealDark.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    bottom: 22,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(RouteNames.home);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.whiteOverlay20,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? Icons.arrow_forward_ios_rounded
                                      : Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.courses,
                                    style: GoogleFonts.cairo(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 430),
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 430
                            ? (MediaQuery.of(context).size.width - 430) / 2
                            : 0,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.monitor_heart_outlined,
                                  size: 25,
                                  color: _titleTeal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.homeCoursesSectionTitle,
                                    style: GoogleFonts.cairo(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _titleTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTracksSection(l10n),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const BottomNav(activeTab: 'courses'),
        ],
      ),
    );
  }

  Widget _buildTracksSection(AppLocalizations l10n) {
    const trackImages = <String>[
      'assets/images/WhatsApp Image 2026-04-14 at 5.03.54 PM.jpeg',
      'assets/images/WhatsApp Image 2026-04-14 at 5.03.55 PM.jpeg',
      'assets/images/WhatsApp Image 2026-04-14 at 5.03.55 PM (1).jpeg',
      'assets/images/WhatsApp Image 2026-04-14 at 5.03.56 PM.jpeg',
      'assets/images/WhatsApp Image 2026-04-14 at 5.03.56 PM (1).jpeg',
      'assets/images/WhatsApp Image 2026-04-14 at 5.03.57 PM.jpeg',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: List.generate(MedicalTrack.values.length, (i) {
            final track = MedicalTrack.values[i];
            final label = _trackLabel(l10n, track);
            return _buildTrackTile(
              imageAsset: trackImages[i],
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
    required String imageAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.medical_services_outlined,
                    size: 28,
                    color: _titleTeal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
}
