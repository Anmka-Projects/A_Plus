import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../services/profile_service.dart';
import '../../l10n/app_localizations.dart';

Widget _settingsGradientIcon(IconData icon, double size) {
  return Center(
    child: ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.brandGradient,
      ).createShader(bounds),
      child: Icon(icon, size: size, color: Colors.white),
    ),
  );
}

/// Settings Screen - Pixel-perfect match to React version
/// Matches: components/screens/settings-screen.tsx
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _preferences;
  bool _notifications = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.instance.getProfile();
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📋 PROFILE DATA IN SETTINGS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ Profile loaded successfully');
        print('📦 Full profile data: $profile');
        print('📦 Profile keys: ${profile.keys.toList()}');
        print('📦 Profile type: ${profile.runtimeType}');
        print('');
        print('🔍 Checking name field:');
        print('  profile["name"]: ${profile['name']}');
        print('  profile["name"] type: ${profile['name']?.runtimeType}');
        print('  profile["name"] toString: ${profile['name']?.toString()}');
        print('  profile["name"] is null: ${profile['name'] == null}');
        print(
            '  profile["name"] isEmpty: ${profile['name']?.toString().isEmpty ?? true}');
        print('');
        print('🔍 Checking user field (nested):');
        print('  profile["user"]: ${profile['user']}');
        if (profile['user'] != null) {
          final user = profile['user'] as Map<String, dynamic>?;
          print('  profile["user"]["name"]: ${user?['name']}');
        }
        print('');
        print('🔍 Other relevant fields:');
        print('  profile["email"]: ${profile['email']}');
        print('  profile["studentType"]: ${profile['studentType']}');
        print('  profile["student_type"]: ${profile['student_type']}');
        print(
            '  profile["studentType"] type: ${profile['studentType']?.runtimeType}');
        print(
            '  profile["student_type"] type: ${profile['student_type']?.runtimeType}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      setState(() {
        _profile = profile;
        _preferences = profile['preferences'] as Map<String, dynamic>?;
        _emailNotifications = _preferences?['email_notifications'] ?? true;
        _pushNotifications = _preferences?['push_notifications'] ?? true;
        _notifications = _pushNotifications;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('✅ State updated with profile');
        print('  _profile["name"]: ${_profile?['name']}');
        print(
            '  Will display: ${_profile?['name']?.toString() ?? AppLocalizations.of(context)!.user}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ ERROR LOADING PROFILE IN SETTINGS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Error: $e');
        print('Error type: ${e.runtimeType}');
        print('Stack trace: ${StackTrace.current}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreferences() async {
    try {
      await ProfileService.instance.updatePreferences(
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
      );
      if (kDebugMode) {
        print('✅ Preferences updated');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.preferencesUpdated,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating preferences: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorUpdatingPreferences,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.brandBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header — brand blue → purple + shadow (matches enrolled / secondary)
            Container(
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
                top: MediaQuery.of(context).padding.top + 16, // pt-4
                bottom: 32, // pb-8
                left: 16, // px-4
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, // w-10
                      height: 40, // h-10
                      decoration: const BoxDecoration(
                        color: AppColors.whiteOverlay20, // bg-white/20
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20, // w-5 h-5
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // gap-4
                  Text(
                    AppLocalizations.of(context)!.settings,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content - matches React: px-4 -mt-4
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16), // -mt-4
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile section - matches React: bg-white rounded-3xl p-5 mb-6
                      Container(
                        margin: const EdgeInsets.only(bottom: 24), // mb-6
                        padding: const EdgeInsets.all(20), // p-5
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(24), // rounded-3xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar - matches React: w-16 h-16 rounded-full
                            Container(
                              width: 64, // w-16
                              height: 64, // h-16
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: AppColors.brandGradient,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: Container(
                                  color: Colors.white,
                                  child: Image.asset(
                                    'assets/images/WhatsApp Image 2026-04-14 at 5.04.03 PM.jpeg',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                      'assets/images/user-avatar.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _settingsGradientIcon(
                                              Icons.person, 32),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), // gap-4
                            // User info - matches React: flex-1
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?['name']?.toString() ??
                                        AppLocalizations.of(context)!.user,
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                  Text(
                                    _profile?['email']?.toString() ?? '',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit button - matches React: w-10 h-10 rounded-xl
                            GestureDetector(
                              onTap: () async {
                                final result = await context.push(
                                  RouteNames.editProfile,
                                  extra: _profile,
                                );
                                if (result == true && mounted) {
                                  _loadProfile();
                                }
                              },
                              child: Container(
                                width: 40, // w-10
                                height: 40, // h-10
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.brandBlue.withOpacity(0.12),
                                      AppColors.brandPurple.withOpacity(0.12),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(12), // rounded-xl
                                ),
                                child: Center(
                                  child: ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: AppColors.brandGradient,
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Settings title - matches React: text-lg font-bold mb-4
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16), // mb-4
                        child: Text(
                          AppLocalizations.of(context)!.generalSettings,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),

                      // Chat - teacher/student messaging
                      _buildSettingItem(
                        icon: Icons.chat_bubble_rounded,
                        label:
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'المحادثات'
                                : 'Chat',
                        onTap: () => context.push(RouteNames.chatConversations),
                      ),

                      // Notifications toggle - matches React SettingItem with toggle
                      _buildSettingItem(
                        icon: Icons.notifications,
                        label: AppLocalizations.of(context)!.notifications,
                        hasToggle: true,
                        toggleValue: _notifications,
                        onToggle: () {
                          setState(() {
                            _notifications = !_notifications;
                            _pushNotifications = _notifications;
                          });
                          _updatePreferences();
                        },
                      ),

                      // Privacy setting
                      _buildSettingItem(
                        icon: Icons.shield,
                        label: AppLocalizations.of(context)!.privacyAndSecurity,
                        onTap: () => context.push(RouteNames.privacyPolicy),
                      ),

                      // Help setting
                      _buildSettingItem(
                        icon: Icons.help,
                        label: AppLocalizations.of(context)!.helpAndSupport,
                        onTap: () => context.push(RouteNames.supportAndHelp),
                      ),

                      const SizedBox(height: 32),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    String? value,
    bool hasToggle = false,
    bool toggleValue = false,
    VoidCallback? onToggle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: hasToggle ? onToggle : (onTap ?? () {}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // mb-3
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // rounded-2xl
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and label - matches React: gap-3
            Row(
              children: [
                Container(
                  width: 40, // w-10
                  height: 40, // h-10
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandBlue.withOpacity(0.12),
                        AppColors.brandPurple.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  child: Center(
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.brandGradient,
                      ).createShader(bounds),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),

            // Value or toggle
            if (hasToggle)
              // Toggle switch - matches React custom toggle
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 48, // w-12
                  height: 28, // h-7
                  padding: const EdgeInsets.all(4), // p-1
                  decoration: BoxDecoration(
                    gradient: toggleValue
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: AppColors.brandGradient,
                          )
                        : null,
                    color: toggleValue ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(999), // rounded-full
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: toggleValue
                        ? Alignment.centerLeft // RTL: toggle moves left when on
                        : Alignment.centerRight,
                    child: Container(
                      width: 20, // w-5
                      height: 20, // h-5
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  if (value != null)
                    Text(
                      value,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  const SizedBox(width: 8), // gap-2
                  const Icon(
                    Icons.chevron_left,
                    size: 20, // w-5 h-5
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
