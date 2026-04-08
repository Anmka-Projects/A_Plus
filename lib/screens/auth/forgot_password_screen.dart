import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/navigation/route_names.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await AuthService.instance.forgotPassword(
          email: _emailController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppTextStyles.bodySmall(),
            ),
            backgroundColor: AppColors.destructive,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // Purple Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                child: Column(
                  children: [
                    // Back Button & Title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.whiteOverlay20,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.pureWhite,
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.forgotPasswordTitle,
                          style: AppTextStyles.h3(
                            color: AppColors.pureWhite,
                          ).copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.whiteOverlay20,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.pureWhite,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.resetPasswordTitle,
                      style: AppTextStyles.h2(
                        color: AppColors.pureWhite,
                      ).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.resetPasswordDescription,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.whiteOverlay40,
                      ).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Container
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: _emailSent
                      ? _buildSuccessView(context)
                      : _buildForm(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          _buildLabel(l10n.email),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: l10n.enterEmail,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            context: context,
          ),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForeground,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      l10n.sendResetLink,
                      style: AppTextStyles.buttonMedium().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => context.go(RouteNames.login),
              child: Text(
                l10n.backToLogin,
                style: AppTextStyles.bodySmall(
                  color: AppColors.purple,
                ).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.sentSuccessfully,
          style: AppTextStyles.h2(
            color: AppColors.foreground,
          ).copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.resetPasswordSent,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(
            color: AppColors.mutedForeground,
          ).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall(
            color: AppColors.purple,
          ).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go(RouteNames.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n.backToLogin,
              style: AppTextStyles.buttonMedium().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: Text(
            l10n.sendToAnotherEmail,
            style: AppTextStyles.bodySmall(
              color: AppColors.mutedForeground,
            ).copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodySmall(
        color: AppColors.foreground,
      ).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandBlue.withOpacity(0.06),
            AppColors.brandPurple.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOverlay20,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.bodySmall().copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall(
            color: AppColors.mutedForeground,
          ).copyWith(fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.purple, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.fieldRequired;
          }
          if (keyboardType == TextInputType.emailAddress) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return l10n.invalidEmail;
            }
          }
          return null;
        },
      ),
    );
  }
}
